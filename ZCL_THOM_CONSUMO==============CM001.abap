METHOD POST_DOCUMENT.
** Códigos Possíveis
***********************************************************************
*01     MB01  - Entrada para Pedido
*02     MB31  - Entrada para Ordem
*03     MB1A  - Saídas
*04     MB1B  - Transferências
*05     MB1C  - Outras Entradas
*06     MB11  - Movimento Mercadorias (Genérico)
*07     MB04  - Subcontratação
***********************************************************************

** Campos Items
***********************************************************************
*  plant     = werks.
*  stge_loc  = lgort
*  material  = matnr
*  batch     = charg.
*  entry_qnt = menge.
*  entry_uom = meins.
*  po_number = ebeln.
*  po_item   = ebelp.
***********************************************************************

  DATA: LT_ZFI_XREF_THOM_T TYPE TABLE OF ZFI_XREF_THOM_T.

  DATA: LV_FLAG_BD         TYPE FLAG,
        LV_BWART           TYPE BWART,
        LS_CODE            TYPE BAPI2017_GM_CODE,
        LS_GOODSMVT_HEADER TYPE BAPI2017_GM_HEAD_01,
        LS_MESSAGE         TYPE BDCMSGCOLL,
        LS_GOODSMVT_ITEM   TYPE BAPI2017_GM_ITEM_CREATE,
        LS_RETURN          TYPE BAPIRET2,
        LV_TIMES           TYPE I,
        LV_KOSTL           TYPE KOSTL,
        LV_HAS_ERROR       TYPE ABAP_BOOL,
        LT_GOODSMVT_ITEM   TYPE TABLE OF BAPI2017_GM_ITEM_CREATE,
        LT_RETURN          TYPE TABLE OF BAPIRET2,
        LS_MSEG            TYPE MSEG.

  DATA: LS_DOCUMENT        TYPE TY_DOCUMENT,
        LS_ZFI_XREF_THOM_T TYPE ZFI_XREF_THOM_T,
        LS_MARA            TYPE MARA.

  DATA: LV_CHARG TYPE CHARG_D.

  DATA: BEGIN OF LS_EINA,
          MATNR TYPE EINA-MATNR,
          LIFNR TYPE EINA-LIFNR,
        END OF LS_EINA.

***********************************************************************
  CLEAR: ET_MESSAGES,
  E_MBLNR,
  E_MJAHR,
  ET_MSEG,
  LV_HAS_ERROR,
  LV_KOSTL,
  LV_FLAG_BD.

  CHECK CS_DOCUMENT IS NOT INITIAL.

  IF CS_DOCUMENT-MSGID IS INITIAL.
**  Número de mensagem inválido
    LS_MESSAGE-MSGTYP = 'E'.
    LS_MESSAGE-MSGID  = 'ZTHOM'.
    LS_MESSAGE-MSGNR  = '002'.
    APPEND LS_MESSAGE TO ET_MESSAGES.
    CLEAR LS_MESSAGE.
    RAISE ERROR_DATA.
  ENDIF.

  IF CS_DOCUMENT-WERKS IS INITIAL.
**  Centro inválido
    LS_MESSAGE-MSGTYP = 'E'.
    LS_MESSAGE-MSGID  = 'ZTHOM'.
    LS_MESSAGE-MSGNR  = '004'.
    APPEND LS_MESSAGE TO ET_MESSAGES.
    CLEAR LS_MESSAGE.
    RAISE ERROR_DATA.
  ENDIF.

  IF CS_DOCUMENT-LGORT IS INITIAL.
**  Depósito inválido
    LS_MESSAGE-MSGTYP = 'E'.
    LS_MESSAGE-MSGID  = 'ZTHOM'.
    LS_MESSAGE-MSGNR  = '005'.
    APPEND LS_MESSAGE TO ET_MESSAGES.
    CLEAR LS_MESSAGE.
    RAISE ERROR_DATA.
  ENDIF.

  IF CS_DOCUMENT-MATNR IS INITIAL.
**  Material inválido
    LS_MESSAGE-MSGTYP = 'E'.
    LS_MESSAGE-MSGID  = 'ZTHOM'.
    LS_MESSAGE-MSGNR  = '006'.
    APPEND LS_MESSAGE TO ET_MESSAGES.
    CLEAR LS_MESSAGE.
    RAISE ERROR_DATA.
  ENDIF.

  CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
    EXPORTING
      INPUT        = CS_DOCUMENT-MATNR
    IMPORTING
      OUTPUT       = CS_DOCUMENT-MATNR
    EXCEPTIONS
      LENGTH_ERROR = 1
      OTHERS       = 2.

  IF SY-SUBRC <> 0.
    LS_MESSAGE-MSGTYP = 'E'.
    LS_MESSAGE-MSGID  = 'ZTHOM'.
    LS_MESSAGE-MSGNR  = '006'.
    LS_MESSAGE-MSGV1  = CS_DOCUMENT-MATNR.
    APPEND LS_MESSAGE TO ET_MESSAGES.
    CLEAR LS_MESSAGE.
    RAISE ERROR_DATA.
  ENDIF.

  IF CS_DOCUMENT-MENGE <= 0.
**  Quantidade inválida
    LS_MESSAGE-MSGTYP = 'E'.
    LS_MESSAGE-MSGID  = 'ZTHOM'.
    LS_MESSAGE-MSGNR  = '007'.
    APPEND LS_MESSAGE TO ET_MESSAGES.
    CLEAR LS_MESSAGE.
    RAISE ERROR_DATA.
  ENDIF.

  IF CS_DOCUMENT-MBLNR IS NOT INITIAL.
**  Documento já foi processado
    LS_MESSAGE-MSGTYP = 'E'.
    LS_MESSAGE-MSGID  = 'ZTHOM'.
    LS_MESSAGE-MSGNR  = '008'.
    LS_MESSAGE-MSGV1  = CS_DOCUMENT-MBLNR.
    APPEND LS_MESSAGE TO ET_MESSAGES.
    CLEAR LS_MESSAGE.
    RAISE ERROR_DATA.
  ENDIF.

** Determina Centro de Custo
***********************************************************************
**>> Início Ajuste Score/JCS - bloqueio de execução da BAPI sem centro de custo
  CLEAR: LT_ZFI_XREF_THOM_T,
  LS_ZFI_XREF_THOM_T,
  LV_KOSTL.

** [AJUSTE] Primeiro tenta parametrização específica por WERKS + LGORT
  SELECT *
  FROM ZFI_XREF_THOM_T
  INTO TABLE LT_ZFI_XREF_THOM_T
  WHERE WERKS = CS_DOCUMENT-WERKS
  AND LGORT = CS_DOCUMENT-LGORT.

** [AJUSTE] Se não encontrar, tenta fallback com LGORT em branco
  IF LT_ZFI_XREF_THOM_T IS INITIAL.
    SELECT *
    FROM ZFI_XREF_THOM_T
    INTO TABLE LT_ZFI_XREF_THOM_T
    WHERE WERKS = CS_DOCUMENT-WERKS
    AND LGORT = ''.
  ENDIF.

** [AJUSTE] Remove entradas sem centro de custo
  DELETE LT_ZFI_XREF_THOM_T WHERE CENTRO_CUSTO IS INITIAL.

** [AJUSTE] Procura registo aplicável
  CLEAR LS_ZFI_XREF_THOM_T.
  LOOP AT LT_ZFI_XREF_THOM_T INTO LS_ZFI_XREF_THOM_T
  WHERE SERV_EXEC    = CS_DOCUMENT-COD_U_FUNC
  AND TIPO_NEGOCIO = CS_DOCUMENT-COD_U_OPER.
    EXIT.
  ENDLOOP.

** [AJUSTE] Se não encontrar determinação válida, grava erro e bloqueia apenas a BAPI
  IF SY-SUBRC <> 0 OR LS_ZFI_XREF_THOM_T-CENTRO_CUSTO IS INITIAL.
**  Não é possivel determinar Centro de Custo para C:"&" D:"&" CF:"&" CO:"&"
    LS_MESSAGE-MSGTYP = 'E'.
    LS_MESSAGE-MSGID  = 'ZTHOM'.
    LS_MESSAGE-MSGNR  = '040'.
    LS_MESSAGE-MSGV1  = CS_DOCUMENT-WERKS.
    LS_MESSAGE-MSGV2  = CS_DOCUMENT-LGORT.
    LS_MESSAGE-MSGV3  = CS_DOCUMENT-COD_U_FUNC.
    LS_MESSAGE-MSGV4  = CS_DOCUMENT-COD_U_OPER.
    APPEND LS_MESSAGE TO ET_MESSAGES.
    CLEAR LS_MESSAGE.

    LV_HAS_ERROR = ABAP_TRUE.
  ELSE.
    LV_KOSTL = LS_ZFI_XREF_THOM_T-CENTRO_CUSTO.
  ENDIF.
**<< Fim Ajuste Score/JCS

  SELECT SINGLE *
  FROM MARA
  INTO LS_MARA
  WHERE MATNR = CS_DOCUMENT-MATNR.

  IF SY-SUBRC <> 0.
    LS_MESSAGE-MSGTYP = 'E'.
    LS_MESSAGE-MSGID  = 'ZTHOM'.
    LS_MESSAGE-MSGNR  = '006'.
    LS_MESSAGE-MSGV1  = CS_DOCUMENT-MATNR.
    APPEND LS_MESSAGE TO ET_MESSAGES.
    CLEAR LS_MESSAGE.
    RAISE ERROR_DATA.
  ENDIF.

  CLEAR LS_GOODSMVT_ITEM.

  IF LS_MARA-ZMAT_CONSIG EQ ABAP_TRUE.
    LS_GOODSMVT_ITEM-SPEC_STOCK = 'K'.

    CLEAR LS_EINA.
    SELECT SINGLE A~MATNR A~LIFNR
    FROM EINA AS A
    INNER JOIN EINE AS B
    ON B~INFNR = A~INFNR
    INTO LS_EINA
    WHERE A~MATNR = CS_DOCUMENT-MATNR
    AND A~RELIF = ABAP_TRUE
    AND B~ESOKZ = '2'.

    IF SY-SUBRC <> 0.
      SELECT SINGLE A~MATNR A~LIFNR
      FROM EINA AS A
      INNER JOIN EINE AS B
      ON B~INFNR = A~INFNR
      INTO LS_EINA
      WHERE A~MATNR = CS_DOCUMENT-MATNR
      AND B~ESOKZ = '2'.
    ENDIF.

    LS_GOODSMVT_ITEM-VENDOR     = LS_EINA-LIFNR.
    LS_GOODSMVT_ITEM-SPEC_STOCK = 'K'.
  ENDIF.

** Cabeçalho
***********************************************************************
  GET TIME.
  LS_CODE-GM_CODE = '03'.

  IF CS_DOCUMENT-DATUM IS INITIAL.
    CS_DOCUMENT-DATUM = SY-DATUM.
  ENDIF.

  MOVE: CS_DOCUMENT-DATUM TO LS_GOODSMVT_HEADER-DOC_DATE,
  CS_DOCUMENT-DATUM TO LS_GOODSMVT_HEADER-PSTNG_DATE,
  CS_DOCUMENT-BKTXT TO LS_GOODSMVT_HEADER-HEADER_TXT.

  IF LS_MARA-XCHPF EQ ABAP_TRUE AND
  CS_DOCUMENT-CHARG IS INITIAL.
    CALL FUNCTION 'ZMM_PICK_OLDEST_BATCH'
      EXPORTING
        IV_MATNR = CS_DOCUMENT-MATNR
        IV_WERKS = CS_DOCUMENT-WERKS
        IV_LGORT = CS_DOCUMENT-LGORT
        IV_LIFNR = LS_EINA-LIFNR
      IMPORTING
        EV_CHARG = LV_CHARG.
  ELSEIF CS_DOCUMENT-CHARG IS NOT INITIAL.
    LV_CHARG = CS_DOCUMENT-CHARG.
  ENDIF.

** Items
***********************************************************************
"  CLEAR LS_GOODSMVT_ITEM.  "Score - APO - 23.04.2026
  LS_GOODSMVT_ITEM-MOVE_TYPE  = C_BWART_CONSUMO.
  LS_GOODSMVT_ITEM-MATERIAL   = CS_DOCUMENT-MATNR.
  LS_GOODSMVT_ITEM-BATCH      = LV_CHARG.
  LS_GOODSMVT_ITEM-PLANT      = CS_DOCUMENT-WERKS.
  LS_GOODSMVT_ITEM-STGE_LOC   = CS_DOCUMENT-LGORT.
  LS_GOODSMVT_ITEM-QUANTITY   = CS_DOCUMENT-MENGE.
  LS_GOODSMVT_ITEM-BASE_UOM   = LS_MARA-MEINS.
  LS_GOODSMVT_ITEM-ENTRY_QNT  = CS_DOCUMENT-MENGE.
  LS_GOODSMVT_ITEM-ENTRY_UOM  = LS_MARA-MEINS.
  LS_GOODSMVT_ITEM-ITEM_TEXT  = CS_DOCUMENT-TEXTO_ITEM.
  LS_GOODSMVT_ITEM-COSTCENTER = LV_KOSTL.
  LS_GOODSMVT_ITEM-WITHDRAWN  = ABAP_TRUE.
  LS_GOODSMVT_ITEM-NO_MORE_GR = ABAP_TRUE.

  CONCATENATE CS_DOCUMENT-COD_U_FUNC CS_DOCUMENT-COD_U_OPER
  INTO LS_GOODSMVT_ITEM-UNLOAD_PT
  SEPARATED BY SPACE.

  APPEND LS_GOODSMVT_ITEM TO LT_GOODSMVT_ITEM.

** Executa Movimento
***********************************************************************
  SET_PROCESS_AS_INTERFACE( ).

** [AJUSTE] Só executa a BAPI se não existir erro previamente registado no item corrente
  READ TABLE ET_MESSAGES INTO LS_MESSAGE WITH KEY MSGTYP = 'E'.
  IF SY-SUBRC <> 0 AND LV_HAS_ERROR IS INITIAL.

    CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
      EXPORTING
        GOODSMVT_HEADER  = LS_GOODSMVT_HEADER
        GOODSMVT_CODE    = LS_CODE
      IMPORTING
        MATERIALDOCUMENT = E_MBLNR
        MATDOCUMENTYEAR  = E_MJAHR
      TABLES
        GOODSMVT_ITEM    = LT_GOODSMVT_ITEM
        RETURN           = LT_RETURN.

** Pesquisa de Erros
***********************************************************************
    LOOP AT LT_RETURN INTO LS_RETURN
    WHERE TYPE = 'E'
    OR TYPE = 'A'.
      MOVE LS_RETURN-TYPE       TO LS_MESSAGE-MSGTYP.
      MOVE LS_RETURN-ID         TO LS_MESSAGE-MSGID.
      MOVE LS_RETURN-NUMBER     TO LS_MESSAGE-MSGNR.
      MOVE LS_RETURN-MESSAGE_V1 TO LS_MESSAGE-MSGV1.
      MOVE LS_RETURN-MESSAGE_V2 TO LS_MESSAGE-MSGV2.
      MOVE LS_RETURN-MESSAGE_V3 TO LS_MESSAGE-MSGV3.
      MOVE LS_RETURN-MESSAGE_V4 TO LS_MESSAGE-MSGV4.
      APPEND LS_MESSAGE TO ET_MESSAGES.
      CLEAR LS_MESSAGE.
    ENDLOOP.

    IF SY-SUBRC EQ 0.
      IF I_COMMIT EQ ABAP_TRUE.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ENDIF.
      RAISE ERROR.
    ENDIF.

** Finaliza
***********************************************************************
    IF I_COMMIT EQ ABAP_TRUE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          WAIT = 'X'.
    ENDIF.

** Aguarda por Actualização da Base de Dados
***********************************************************************
    CHECK NOT I_WAIT IS INITIAL.

    LV_TIMES = I_WAIT + 1.

    DO LV_TIMES TIMES.
      IF SY-INDEX > 1.
        WAIT UP TO 1 SECONDS.
      ENDIF.

      SELECT *
      FROM MSEG
      INTO TABLE ET_MSEG
      WHERE MBLNR EQ E_MBLNR
      AND MJAHR EQ E_MJAHR.

      CHECK SY-SUBRC = 0.
      LV_FLAG_BD = 'X'.
      CS_DOCUMENT-MBLNR = E_MBLNR.
      CS_DOCUMENT-MJAHR = E_MJAHR.
      EXIT.
    ENDDO.

    IF LV_FLAG_BD IS INITIAL.
**    Documento &(&) não foi encontrado na base de dados
      LS_MESSAGE-MSGTYP = 'E'.
      LS_MESSAGE-MSGID  = 'ZTHOM'.
      LS_MESSAGE-MSGNR  = '001'.
      LS_MESSAGE-MSGV1  = E_MBLNR.
      LS_MESSAGE-MSGV2  = E_MJAHR.
      APPEND LS_MESSAGE TO ET_MESSAGES.
      CLEAR LS_MESSAGE.
      RAISE ERROR.
    ENDIF.
  ENDIF.

ENDMETHOD.
