"==============================================================================
" Classe......: ZCL_THOM_INTERF_LOTE
" Descrição...: Interface SAP # THOM – Sincronização de Lotes de Materiais
"------------------------------------------------------------------------------
" Objetivo:
"   Esta classe é responsável por toda a lógica de integração entre o SAP
"   e o sistema THOM para eventos relacionados a Lotes de Materiais (Batch).
"
"   A classe centraliza:
"     - Leitura de dados de Lote (MCHA / MCHB)
"     - Construção do payload JSON
"     - Envio HTTP (POST) para o THOM
"     - Tratamento de erros sem geração de DUMP
"     - Persistência e monitorização via ZTHOM_INTERF_LOT
"
"------------------------------------------------------------------------------
" Como a interface é acionada:
"   - Através de BAdI / Enhancement ligado às transações:
"       * MSC1N – Criação de Lote
"       * MSC2N – Alteração / Inativação de Lote
"
"   - O método principal chamado é:
"       SEND_LOTE
"
"------------------------------------------------------------------------------
" Arquitetura da integração:
"
"   SAP (Outbound, Event-Driven)
"      ### Evento de Lote (criação / alteração / inativação)
"            ### ZCL_THOM_INTERF_LOTE
"                  ### Leitura de dados SAP (MCHA / MCHB)
"                  ### Montagem JSON
"                  ### HTTP POST # THOM
"                  ### Log e controle em ZTHOM_INTERF_LOT
"
"------------------------------------------------------------------------------
" Configurações necessárias:
"
"   1) TVARVC
"      - ZTHOM_HTTP_DEST
"          # Nome do destino HTTP configurado no SM59
"
"      - ZTHOM_LOTES_PATH
"          # Path relativo do endpoint (ex.: /api/batches)
"
"   2) SM59
"      - Destino HTTP do tipo G
"      - Apontando para o host do sistema THOM
"      - Autenticação conforme definido pela equipa de integração
"
"   Observação:
"     A ausência de qualquer configuração gera ERRO CONTROLADO
"     (ZCX_THOM_CFG), gravado em ZTHOM_INTERF_LOT, sem DUMP.
"
"------------------------------------------------------------------------------
" Tabela de monitorização:
"
"   ZTHOM_INTERF_LOT
"
"   Finalidade:
"     - Rastreabilidade completa da interface
"     - Controle de tentativas e reprocessamento
"     - Auditoria técnica
"
"   Principais campos:
"     - INTERF_ID        : GUID da execução (idempotência)
"     - EVENT_TYPE       : Tipo do evento de Lote
"     - MATNR / CHARG    : Identificação do Lote
"     - STATUS           : NEW / SENT / ERROR
"     - ATTEMPTS         : Nº de tentativas
"     - NEXT_RETRY_TS    : Próxima tentativa (UTC)
"     - LAST_HTTP_CODE   : Último código HTTP
"     - LAST_ERROR       : Última mensagem de erro
"     - PAYLOAD_HASH    : Hash MD5 do payload
"     - PAYLOAD_JSON    : Payload enviado (RAWSTRING)
"     - RESPONSE         : Resposta do THOM (RAWSTRING)
"
"------------------------------------------------------------------------------
" Convenções importantes:
"
"   - NÃO deve gerar DUMP em nenhuma situação.
"   - Todo erro deve:
"       * Ser capturado (TRY/CATCH)
"       * Ser gravado em ZTHOM_INTERF_LOT
"       * Permitir reprocessamento posterior
"
"   - Não usar PERFORM / FORM (classe 100% OO).
"   - Compatível com ABAP 7.01 (sem VALUE, sem expressões inline avançadas).
"
"------------------------------------------------------------------------------
" Pontos de extensão / evolução futura:
"
"   - Implementação de backoff exponencial no NEXT_RETRY_TS
"   - Report Worker para reenvio automático
"   - Centralização de logs em SLG1 (opcional)
"   - Reuso da base HTTP para outras interfaces SAP # THOM
"
"------------------------------------------------------------------------------
" Autor / Projeto:
"   Projeto : Integração SAP # THOM
"   Módulo  : MM / Integração
"
"==============================================================================
class ZCL_THOM_INTERF_LOTE definition
  public
  final
  create public

  global friends ZCL_IM_BATCH_MASTER_THOM
                 ZCL_IM_MB_DOCUMENT_BADI
                 ZCL_IM_MB_MIGO_THOM .

public section.

  interfaces ZCR_IF_INTF .

  types:
    BEGIN OF TY_CACHE_LOTES,
             MATNR TYPE MATNR,
             WERKS TYPE WERKS_D,
             LGORT TYPE LGORT_D,
             CHARG TYPE CHARG_D,
             CONSG TYPE ABAP_BOOL,
             SND   TYPE ZDE_FLAG_SEND_THOM,
             LOT   TYPE ZE_ADM_LOTES_THOM,
             CONS  TYPE MARA-ZMAT_CONSIG,
             VFDAT TYPE MCH1-VFDAT,
             CLABS TYPE MCHB-CLABS,
             LOTE  TYPE XCHPF,
           END OF TY_CACHE_LOTES .

  data:
    GT_CACHE_LOTES TYPE HASHED TABLE OF TY_CACHE_LOTES
          WITH UNIQUE KEY MATNR WERKS LGORT CHARG CONSG .
  constants C_SERVICE_LOTES type ZE_SERVICE_ID value 'LOTES' ##NO_TEXT.
  constants C_SERVICE_OAUTH type ZE_SERVICE_ID value 'OAUTH' ##NO_TEXT.
    "======================================================================
    " STATUS (domínio ZDE_THOM_STATUS / fixos)
    "======================================================================
  constants C_ST_NEW type ZDE_THOM_STATUS value 'NEW' ##NO_TEXT.
  constants C_ST_SENDING type ZDE_THOM_STATUS value 'SENDING' ##NO_TEXT.
  constants C_ST_SENT type ZDE_THOM_STATUS value 'SENT' ##NO_TEXT.
  constants C_ST_ERROR type ZDE_THOM_STATUS value 'ERROR' ##NO_TEXT.
  constants C_ST_DEAD type ZDE_THOM_STATUS value 'DEAD' ##NO_TEXT.
  constants C_ST_SUPPRESSED type ZDE_THOM_STATUS value 'SUPPRESSED' ##NO_TEXT.
    "======================================================================
    " EVENT TYPE (domínio ZE_EVENTTYP / fixos)
    "======================================================================
  constants C_EV_BATCH_NEW type ZE_EVENTTYP value 'BATCH_NEW' ##NO_TEXT.
  constants C_EV_BATCH_UPSE type ZE_EVENTTYP value 'BATCH_UPSE' ##NO_TEXT.
  constants C_EV_BATCH_INAC type ZE_EVENTTYP value 'BATCH_INAC' ##NO_TEXT.
  constants C_EV_STOCK_UPSE type ZE_EVENTTYP value 'STOCK_UPSE' ##NO_TEXT.

  methods CONSTRUCTOR
    importing
      value(IV_WSID) type ZCR_DE_WSID optional
      value(IV_WSAREA) type ZCR_DE_WSAREA optional
      value(IV_OBJECT) type BALOBJ_D optional
      value(IV_SUBOBJECT) type BALSUBOBJ optional
      value(IV_EXTNUMBER) type BALNREXT optional .
    " Método para reenvio do lote a partir de um registro já existente
    " na tabela ZTHOM_INTERF_LOT. Reprocessa tentativas anteriores.
  methods RESEND_BY_INTERF_ID
    importing
      !IV_INTERF_ID type ZCR_DE_WS_GUID_SAP
    exporting
      !EV_OK type BOOLEAN
      !EV_MESSAGE type STRING .
  methods SET_ENV
    importing
      !IV_ENV type ZE_ENV optional .
    " Consulta dados de endpoint configurado no SAP para comunicação com THOM
    " Baseia-se em ambiente (MV_ENV), serviço (LOTE, TOKEN etc).
  methods GET_ENDPOINT
    importing
      !IV_SERVICE_ID type ZE_SERVICE_ID
    exporting
      !ES_EP type ZTHOM_ENDPOINTS .
  methods GET_LOTES
    importing
      !IV_MATNR type MATNR
      !IV_WERKS type WERKS_D
      !IV_LGORT type LGORT_D optional
      !IV_CHARG type CHARG_D
      !IV_CONSG type BOOLEAN optional
    exporting
      !EV_CLABS type LABST
      !EV_VFDAT type VFDAT
      !EV_LOT_THOM type ZE_ADM_LOTES_THOM
      !EV_SND_THOM type ZDE_FLAG_SEND_THOM
      !EV_LOTE type XCHPF
      !EV_CONS type ZETHOM_MAT_CONSIG .
  methods SEND_LOTE
    importing
      !IV_WS_GUID_SAP type ZTHOM_INTERF_LOT-WS_GUID_SAP
    exporting
      !EV_OK type ABAP_BOOL
      !EV_MESSAGE type STRING
      !ES_RETURN type BAPIRET2 .
  methods INSERT_INTERF_LOT
    exporting
      !EV_SUBRC type SY-SUBRC
      !EV_MSG type STRING
    changing
      value(CH_LOTE) type ZTHOM_INTERF_LOT .
  methods CHECK_SERVICE_AVAILABLE
    importing
      !IV_SERVICE_ID type ZE_SERVICE_ID
    returning
      value(RV_OK) type ABAP_BOOL .
  class-methods NORMALIZE_AMOUNT_FOR_JSON
    importing
      !IV_VALUE type STRING
    returning
      value(RV_VALUE) type STRING .
