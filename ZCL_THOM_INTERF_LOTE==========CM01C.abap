  METHOD _MAP_EVENT_TYPE.
    CLEAR: EV_EVENT_CUI,
    EV_OK,
    EV_MESSAGE.

    CASE IV_EVENT_TYPE.
      WHEN 'BATCH_NEW'.
        EV_EVENT_CUI = 'C'.
      WHEN 'BATCH_UPSE'.
        EV_EVENT_CUI = 'U'.
      WHEN 'BATCH_INAC'.
        EV_EVENT_CUI = 'I'.
      WHEN OTHERS.
        EV_OK      = ABAP_FALSE.
        EV_MESSAGE = 'EVENT_TYPE inválido (esperado BATCH_NEW/BATCH_UPSE/BATCH_INAC).'.
        RETURN.
    ENDCASE.

    EV_OK = ABAP_TRUE.
  ENDMETHOD.
