METHOD SEND_LOTE.
  DATA: LS_DB        TYPE ZTHOM_INTERF_LOT,
        LS_PAYLOAD   TYPE TY_PAYLOAD,
        LO_CX        TYPE REF TO CX_ROOT,
        LV_JSON      TYPE STRING,
        LV_PAYLOAD_X TYPE XSTRING,
        LV_HASH64    TYPE ZTHOM_INTERF_LOT-PAYLOAD_HASH,
        LV_EVT_CUI   TYPE STRING,
        LV_MSG       TYPE SYMSGV,
        LV_OK_DOM    TYPE ABAP_BOOL.

  CLEAR: EV_OK,
  EV_MESSAGE,
  ES_RETURN,
  LS_DB,
  LS_PAYLOAD,
  LV_JSON,
  LV_PAYLOAD_X,
  LV_HASH64,
  LV_EVT_CUI,
  LV_OK_DOM.

  IF ME->CHECK_SERVICE_AVAILABLE( IV_SERVICE_ID = 'LOTES' ) <> ABAP_TRUE.
    RETURN.
  ENDIF.
  " Ler interface
  SELECT SINGLE WS_GUID_SAP
  EVENT_TYPE
  MATNR
  CHARG
  VFDAT
  WERKS
  LGORT
  CLABS
  INTO CORRESPONDING FIELDS OF LS_DB
  FROM ZTHOM_INTERF_LOT
  WHERE WS_GUID_SAP = IV_WS_GUID_SAP.

  IF SY-SUBRC <> 0.
    ME->_SET_ERROR(
    EXPORTING
      IV_MESSAGE = 'Registo não encontrado na ZTHOM_INTERF_LOT (WS_GUID_SAP).'
    IMPORTING
      EV_OK      = EV_OK
      EV_MESSAGE = EV_MESSAGE
      ES_RETURN  = ES_RETURN ).
    RETURN.
  ENDIF.

  " Validar dados mínimos
  IF LS_DB-EVENT_TYPE IS INITIAL
  OR LS_DB-MATNR      IS INITIAL
  OR LS_DB-CHARG      IS INITIAL.
    ME->_SET_ERROR(
    EXPORTING
      IV_MESSAGE = 'Dados mínimos em falta (EVENT_TYPE/MATNR/CHARG).'
    IMPORTING
      EV_OK      = EV_OK
      EV_MESSAGE = EV_MESSAGE
      ES_RETURN  = ES_RETURN ).
    RETURN.
  ENDIF.

  " Validar domínio
  TRY.
      ME->VALIDATE_DOMAIN_VALUES(
      EXPORTING
        IV_EVENT_TYPE = LS_DB-EVENT_TYPE
        IV_STATUS     = C_ST_NEW
      IMPORTING
        EV_OK         = LV_OK_DOM ).
    CATCH CX_ROOT.
      LV_OK_DOM = ABAP_TRUE.
  ENDTRY.

  IF LV_OK_DOM <> ABAP_TRUE.
    ME->_SET_ERROR(
    EXPORTING
      IV_MESSAGE = 'EVENT_TYPE/STATUS inválido (domínio).'
    IMPORTING
      EV_OK      = EV_OK
      EV_MESSAGE = EV_MESSAGE
      ES_RETURN  = ES_RETURN ).
    RETURN.
  ENDIF.

  " Mapear tipo de evento
  ME->_MAP_EVENT_TYPE(
  EXPORTING
    IV_EVENT_TYPE = LS_DB-EVENT_TYPE
  IMPORTING
    EV_EVENT_CUI  = LV_EVT_CUI
    EV_OK         = EV_OK
    EV_MESSAGE    = EV_MESSAGE ).

  IF EV_OK <> ABAP_TRUE.
    LV_MSG = EV_MESSAGE(50).
    ES_RETURN = ME->BUILD_BAPIRET2(
    IV_TYPE   = 'E'
    IV_ID     = 'ZTHOM'
    IV_NUMBER = '011'
    IV_V1     = LV_MSG ).
    RETURN.
  ENDIF.

  " Montar payload
  ME->_BUILD_LOTE_PAYLOAD(
  EXPORTING
    IS_DB        = LS_DB
    IV_EVENT_CUI = LV_EVT_CUI
  IMPORTING
    ES_PAYLOAD   = LS_PAYLOAD
    EV_OK        = EV_OK
    EV_MESSAGE   = EV_MESSAGE ).

  IF EV_OK <> ABAP_TRUE.
    LV_MSG  = EV_MESSAGE(50).
    ES_RETURN = ME->BUILD_BAPIRET2(
    IV_TYPE   = 'E'
    IV_ID     = 'ZTHOM'
    IV_NUMBER = '011'
    IV_V1     = LV_MSG ).
    RETURN.
  ENDIF.

  " Serializar JSON
  TRY.
      LV_JSON = /UI2/CL_JSON=>SERIALIZE(
      DATA        = LS_PAYLOAD
            COMPRESS    = ABAP_TRUE
            PRETTY_NAME = /UI2/CL_JSON=>PRETTY_MODE-LOW_CASE ).
    CATCH CX_ROOT INTO LO_CX.
      ME->_SET_ERROR(
      EXPORTING
        IV_MESSAGE = LO_CX->GET_TEXT( )
      IMPORTING
        EV_OK      = EV_OK
        EV_MESSAGE = EV_MESSAGE
        ES_RETURN  = ES_RETURN ).
      RETURN.
  ENDTRY.

  IF LV_JSON IS INITIAL.
    ME->_SET_ERROR(
    EXPORTING
      IV_MESSAGE = 'Falha ao serializar JSON (resultado vazio).'
    IMPORTING
      EV_OK      = EV_OK
      EV_MESSAGE = EV_MESSAGE
      ES_RETURN  = ES_RETURN ).
    RETURN.
  ENDIF.

  " Converter payload para XSTRING
  ME->STRING_TO_XSTRING_SAFE(
  EXPORTING
    IV_STRING = LV_JSON
  IMPORTING
    EV_XSTR   = LV_PAYLOAD_X ).

  IF LV_PAYLOAD_X IS INITIAL.
    ME->_SET_ERROR(
    EXPORTING
      IV_MESSAGE = 'Falha conversão STRING->XSTRING (payload vazio).'
    IMPORTING
      EV_OK      = EV_OK
      EV_MESSAGE = EV_MESSAGE
      ES_RETURN  = ES_RETURN ).
    RETURN.
  ENDIF.

  " Calcular hash
  ME->CALC_SHA256_HEX64(
  EXPORTING
    IV_XSTR   = LV_PAYLOAD_X
  IMPORTING
    EV_HASH64 = LV_HASH64 ).

  " Persistir payload
  ME->_PERSIST_PAYLOAD(
  EXPORTING
    IV_WS_GUID_SAP = IV_WS_GUID_SAP
    IV_PAYLOAD_X   = LV_PAYLOAD_X
    IV_HASH64      = LV_HASH64
  IMPORTING
    EV_OK          = EV_OK
    EV_MESSAGE     = EV_MESSAGE ).

  IF EV_OK <> ABAP_TRUE.
    LV_MSG  = EV_MESSAGE(50).
    ES_RETURN = ME->BUILD_BAPIRET2(
    IV_TYPE   = 'E'
    IV_ID     = 'ZTHOM'
    IV_NUMBER = '011'
    IV_V1     = LV_MSG ).
    RETURN.
  ENDIF.

  ME->_SET_SUCCESS(
  EXPORTING
    IV_MESSAGE = 'Payload gerado e gravado em PAYLOAD_JSON com sucesso.'
    IV_MSGV1   = LV_MSG
  IMPORTING
    EV_OK      = EV_OK
    EV_MESSAGE = EV_MESSAGE
    ES_RETURN  = ES_RETURN ).
ENDMETHOD.
