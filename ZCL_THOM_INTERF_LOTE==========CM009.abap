  METHOD GET_ENDPOINT.
    DATA LO_CX TYPE REF TO CX_ROOT.

    CLEAR ES_EP.
    CLEAR: MV_LAST_CFG_SERVICE,
    MV_LAST_CFG_MESSAGE.

    IF MV_ENV IS INITIAL.
      ME->SET_ENV( ).
    ENDIF.

    TRY.
        SELECT SINGLE *
        FROM ZTHOM_ENDPOINTS
        INTO ES_EP
        WHERE SERVICE_ID = IV_SERVICE_ID
        AND ENV          = MV_ENV.

        IF SY-SUBRC <> 0.
          MV_LAST_CFG_SERVICE = IV_SERVICE_ID.
          MV_LAST_CFG_MESSAGE = |Endpoint não encontrado para SERVICE_ID { IV_SERVICE_ID } / ENV { MV_ENV }|.
          CLEAR ES_EP.
          RETURN.
        ENDIF.

      CATCH CX_ROOT INTO LO_CX.
        MV_LAST_CFG_SERVICE = IV_SERVICE_ID.
        MV_LAST_CFG_MESSAGE = LO_CX->GET_TEXT( ).
        CLEAR ES_EP.
        RETURN.
    ENDTRY.
  ENDMETHOD.
