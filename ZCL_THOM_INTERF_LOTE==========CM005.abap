METHOD RESEND_BY_INTERF_ID.

  TYPES: BEGIN OF TY_RESP,
           SUCCESS TYPE ABAP_BOOL,
           MESSAGE TYPE STRING,
         END OF TY_RESP.

  DATA: LS_ROW      TYPE ZTHOM_INTERF_LOT,
        LS_RESP     TYPE TY_RESP,
        LO_CX       TYPE REF TO CX_ROOT,
        LV_REQ_JSON TYPE STRING,
        LV_RESP     TYPE STRING,
        LV_HTTP     TYPE I,
        LV_MSG      TYPE STRING,
        LV_ATTEMPTS TYPE I,
        LV_OK       TYPE ABAP_BOOL,
        LV_PAYLOADX TYPE XSTRING,
        LV_RESPX    TYPE XSTRING.

  CLEAR: LS_ROW,
  LS_RESP,
  LV_REQ_JSON,
  LV_RESP,
  LV_HTTP,
  LV_MSG,
  LV_ATTEMPTS,
  LV_OK,
  LV_PAYLOADX,
  LV_RESPX.

  IF ME->CHECK_SERVICE_AVAILABLE( IV_SERVICE_ID = 'LOTES' ) <> ABAP_TRUE.
    RETURN.
  ENDIF.

  " Inicializar log
  MO_LOG = ZCR_CL_INTF_GEN=>GET_INSTANCE_LOG(  IV_OBJECT    = V_OBJECT
                                               IV_SUBOBJECT = V_SUBOBJECT
"                                               IV_EXTNUMBER = |{ S_STATUS-WS_GUID_SAP }|
                                               IV_EXTNUMBER = |{ IV_INTERF_ID }|
                                               IV_NEW_LOG   = ABAP_TRUE ).

  TRY.
      " Ler interface
      SELECT SINGLE *
      INTO LS_ROW
      FROM ZTHOM_INTERF_LOT
      WHERE WS_GUID_SAP = IV_INTERF_ID.

      IF SY-SUBRC <> 0.
        EV_OK      = ABAP_FALSE.
        EV_MESSAGE = 'Registo da interface não encontrado em ZTHOM_INTERF_LOT.'.

        ME->_FINISH_ERROR(
        IV_INTERF_ID = IV_INTERF_ID
        IV_HTTP_CODE = 404
        IV_MESSAGE   = EV_MESSAGE
        IV_ATTEMPTS  = 0
        IV_RESPONSEX = LV_RESPX ).
        RETURN.
      ENDIF.

      LV_ATTEMPTS = LS_ROW-ATTEMPTS.
      LV_ATTEMPTS = LV_ATTEMPTS + 1.

      " Validar evento
      ME->VALIDATE_DOMAIN_VALUES(
      EXPORTING
        IV_EVENT_TYPE = LS_ROW-EVENT_TYPE
        IV_STATUS     = C_ST_SENDING
      IMPORTING
        EV_OK         = LV_OK ).

      IF LV_OK <> ABAP_TRUE.
        EV_OK      = ABAP_FALSE.
        EV_MESSAGE = 'EVENT_TYPE inválido na fila (ZTHOM_INTERF_LOT).'.

        ME->_FINISH_ERROR(
        IV_INTERF_ID = IV_INTERF_ID
        IV_HTTP_CODE = 422
        IV_MESSAGE   = EV_MESSAGE
        IV_ATTEMPTS  = LV_ATTEMPTS
        IV_RESPONSEX = LV_RESPX ).
        RETURN.
      ENDIF.

      " Preparar payload
      LV_PAYLOADX = LS_ROW-PAYLOAD_JSON.

      IF LV_PAYLOADX IS INITIAL.
        EV_OK      = ABAP_FALSE.
        EV_MESSAGE = 'PAYLOAD_JSON vazio (RAWSTRING).'.

        ME->_FINISH_ERROR(
        IV_INTERF_ID = IV_INTERF_ID
        IV_HTTP_CODE = 400
        IV_MESSAGE   = EV_MESSAGE
        IV_ATTEMPTS  = LV_ATTEMPTS
        IV_RESPONSEX = LV_RESPX ).
        RETURN.
      ENDIF.

      ME->XSTRING_TO_STRING_SAFE(
      EXPORTING
        IV_XSTR   = LV_PAYLOADX
      IMPORTING
        EV_STRING = LV_REQ_JSON ).

      IF LV_REQ_JSON IS INITIAL.
        EV_OK      = ABAP_FALSE.
        EV_MESSAGE = 'Falha conversão PAYLOAD_JSON (XSTRING->STRING).'.

        ME->_FINISH_ERROR(
        IV_INTERF_ID = IV_INTERF_ID
        IV_HTTP_CODE = 400
        IV_MESSAGE   = EV_MESSAGE
        IV_ATTEMPTS  = LV_ATTEMPTS
        IV_RESPONSEX = LV_RESPX ).
        RETURN.
      ENDIF.

      " Marcar como envio em curso
      ME->_UPDATE_STATUS_SENDING(
      EXPORTING
        IV_WS_GUID_SAP = IV_INTERF_ID ).

      " Chamada HTTP
      O_THOM_HTTP_SEND->HTTP_POST_JSON(
      EXPORTING
        I_JSON      = LV_REQ_JSON
      IMPORTING
        E_HTTP_CODE = LV_HTTP
        E_RESPONSE  = LV_RESP ).

      IF LV_RESP IS NOT INITIAL.
        ME->STRING_TO_XSTRING_SAFE(
        EXPORTING
          IV_STRING = LV_RESP
        IMPORTING
          EV_XSTR   = LV_RESPX ).
      ENDIF.

      " Interpretar resposta
      CLEAR LS_RESP.
      TRY.
          /UI2/CL_JSON=>DESERIALIZE(
          EXPORTING
            JSON = LV_RESP
          CHANGING
          DATA = LS_RESP ).
        CATCH CX_ROOT.
          CLEAR LS_RESP.
      ENDTRY.

      LV_MSG = LS_RESP-MESSAGE.
      IF LV_MSG IS INITIAL.
        LV_MSG = LV_RESP.
      ENDIF.

      " Tratar retorno
      IF LV_HTTP BETWEEN 200 AND 299.

        EV_OK      = ABAP_TRUE.
        EV_MESSAGE = 'Reenvio executado com sucesso.'.

        ME->_FINISH_SUCCESS(
        IV_INTERF_ID = IV_INTERF_ID
        IV_HTTP_CODE = LV_HTTP
        IV_ATTEMPTS  = LV_ATTEMPTS
        IV_RESPONSEX = LV_RESPX ).

      ELSE.

        IF LV_HTTP IS INITIAL OR LV_HTTP = 0.
          LV_MSG = 'Erro técnico HTTP (timeout/communication failure).'.
        ELSEIF LV_MSG IS INITIAL.
          LV_MSG = |Erro THOM HTTP { LV_HTTP }|.
        ENDIF.

        EV_OK      = ABAP_FALSE.
        EV_MESSAGE = LV_MSG.

        ME->_FINISH_ERROR(
        IV_INTERF_ID = IV_INTERF_ID
        IV_HTTP_CODE = LV_HTTP
        IV_MESSAGE   = LV_MSG
        IV_ATTEMPTS  = LV_ATTEMPTS
        IV_RESPONSEX = LV_RESPX ).

      ENDIF.

    CATCH CX_ROOT INTO LO_CX.

      EV_OK      = ABAP_FALSE.
      EV_MESSAGE = LO_CX->GET_TEXT( ).

      ME->_FINISH_ERROR(
      IV_INTERF_ID = IV_INTERF_ID
      IV_HTTP_CODE = 0
      IV_MESSAGE   = EV_MESSAGE
      IV_ATTEMPTS  = LV_ATTEMPTS
      IV_RESPONSEX = LV_RESPX ).

  ENDTRY.
ENDMETHOD.
