METHOD _UPDATE_AFTER_SEND.
*---------------------------------------------------------------------*
* Projeto   : THOM
* Objetivo  : Atualizar o registo da interface após tentativa de envio
*
* Regras para sucesso:
*
*   1) Primeiro sucesso da chave MATNR+CHARG+WERKS+LGORT
*      - EVENT_TYPE = 'BATCH_NEW'
*      - STATUS     = 'SENT'
*      - ATTEMPTS   = 1
*
*   2) Se já existir envio anterior com sucesso para a mesma chave
*      - EVENT_TYPE = 'BATCH_UPSE'
*      - STATUS     = 'SENT'
*      - ATTEMPTS   = 1
*
* Atualizar também:
*   - LAST_HTTP_CODE
*   - LAST_ERROR
*   - RESPONSE
*   - SENT_TS
*   - DT_SEND
*   - TIME_SEND
*   - USER_SEND
*---------------------------------------------------------------------*

  DATA: LS_CURR       TYPE ZTHOM_INTERF_LOT,
        LV_EVENT_TYPE TYPE ZTHOM_INTERF_LOT-EVENT_TYPE,
        LV_DT_SEND    TYPE SYDATUM,
        LV_TIME_SEND  TYPE SYUZEIT,
        LV_USER_SEND  TYPE SYUNAME,
        LV_ATTEMPTS   TYPE ZTHOM_INTERF_LOT-ATTEMPTS.

  CLEAR: LS_CURR,
  LV_EVENT_TYPE,
  LV_DT_SEND,
  LV_TIME_SEND,
  LV_USER_SEND,
  LV_ATTEMPTS.

  LV_DT_SEND   = SY-DATUM.
  LV_TIME_SEND = SY-UZEIT.
  LV_USER_SEND = SY-UNAME.

  "---------------------------------------------------------------
  "Ler o registo atual da interface
  "---------------------------------------------------------------
  SELECT SINGLE *
  INTO @LS_CURR
  FROM ZTHOM_INTERF_LOT
  WHERE WS_GUID_SAP = @IV_WS_GUID_SAP.

  IF SY-SUBRC <> 0.
    RETURN.
  ENDIF.

  LV_EVENT_TYPE = LS_CURR-EVENT_TYPE.
  "---------------------------------------------------------------
  "Em caso de sucesso, decidir o event type final
  "---------------------------------------------------------------
  IF IV_STATUS = 'SENT'.
    LV_EVENT_TYPE = ME->_DETERMINE_SUCCESS_EVENT_TYPE(
    IV_WS_GUID_SAP = IV_WS_GUID_SAP ).
    LV_ATTEMPTS = 1.
  ELSE.
    "Para erro, mantém o event type atual
    "e controla tentativas com fallback
    IF IV_ATTEMPTS IS INITIAL.
      LV_ATTEMPTS = LS_CURR-ATTEMPTS + 1.
    ELSE.
      LV_ATTEMPTS = IV_ATTEMPTS.
    ENDIF.

  ENDIF.

  "---------------------------------------------------------------
  "Atualizar a tabela da interface
  "---------------------------------------------------------------
  UPDATE ZTHOM_INTERF_LOT
  SET  EVENT_TYPE     = @LV_EVENT_TYPE,
       STATUS         = @IV_STATUS,
       ATTEMPTS       = @LV_ATTEMPTS,
       DT_SEND        = @LV_DT_SEND,
       TIME_SEND      = @LV_TIME_SEND,
       USER_SEND      = @LV_USER_SEND,
       SENT_TS        = @IV_SENT_TS,
       LAST_HTTP_CODE = @IV_HTTP_CODE,
       LAST_ERROR     = @IV_MESSAGE,
       RESPONSE       = @IV_RESPONSE_X
  WHERE WS_GUID_SAP    = @IV_WS_GUID_SAP.

  IF SY-SUBRC = 0.
    COMMIT WORK AND WAIT.
  ENDIF.

ENDMETHOD.
