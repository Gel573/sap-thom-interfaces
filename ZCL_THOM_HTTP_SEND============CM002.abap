  METHOD LOAD_PARAMS_STRICT.

    DATA: LS_EP TYPE ZTHOM_ENDPOINTS,
          LO_CX TYPE REF TO CX_ROOT.

    CLEAR: V_HTTP_DEST, V_PATH, V_TIMEOUT_SEC,
    V_AUTH_USER, V_AUTH_PASS,
    V_LAST_CFG_SERVICE, V_LAST_CFG_MESSAGE.

    TRY.
        ME->GET_ENDPOINT(
        EXPORTING
          I_SERVICE_ID = V_SERVICE_ID
        IMPORTING
          ES_EP         = LS_EP ).

        "        IF ls_ep-service_id IS INITIAL.  "Modificado por Score - APO 16.04.2026
        IF LS_EP-ACTIVE NE ABAP_TRUE.  "Verifica se serviço esta ativo
          RETURN.
        ENDIF.

        "Ajusta nomes conforme SE11:
        V_HTTP_DEST   = LS_EP-DEST_SM59.
        V_URL         = LS_EP-URL.
        V_PATH  = LS_EP-RESOURCE_PATH.
        V_TIMEOUT_SEC = LS_EP-TIMEOUT_SEC.

        V_AUTH_USER   = LS_EP-AUTH_USER.
        V_AUTH_PASS   = LS_EP-AUTH_PASS.

      CATCH CX_ROOT INTO LO_CX.
        V_LAST_CFG_SERVICE = V_SERVICE_ID.
        V_LAST_CFG_MESSAGE = LO_CX->GET_TEXT( ).
        CLEAR: V_HTTP_DEST, V_PATH, V_TIMEOUT_SEC, V_AUTH_USER, V_AUTH_PASS.
    ENDTRY.

  ENDMETHOD.
