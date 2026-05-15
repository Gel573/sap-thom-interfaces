  METHOD CHECK_CONS_GERAL.
    DATA: LS_MARD_EXT TYPE ZMM_MARD_EXT,
          LV_MATNR    TYPE MATNR,
          LV_MSGTXT   TYPE STRING.

    CLEAR: EV_SEND, LS_MARD_EXT.
    EV_SEND = ABAP_FALSE.

    "------------------------------------------------------------
    " Conversão do material para formato interno
    "------------------------------------------------------------
    LV_MATNR = IV_MATNR.

    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        INPUT        = LV_MATNR
      IMPORTING
        OUTPUT       = LV_MATNR
      EXCEPTIONS
        LENGTH_ERROR = 1
        OTHERS       = 2.

    IF SY-SUBRC <> 0.
      LV_MATNR = IV_MATNR.
    ENDIF.

    "------------------------------------------------------------
    " Leitura da ZMM_MARD_EXT
    " Se LGORT vier preenchido, usa MATNR+WERKS+LGORT
    " Se LGORT vier vazio, usa MATNR+WERKS
    "------------------------------------------------------------
    IF IV_DEPOS IS INITIAL.

      SELECT SINGLE *
      INTO LS_MARD_EXT
      FROM ZMM_MARD_EXT
      WHERE MATNR = LV_MATNR
      AND WERKS = IV_CENTRO.

    ELSE.

      SELECT SINGLE *
      INTO LS_MARD_EXT
      FROM ZMM_MARD_EXT
      WHERE MATNR = LV_MATNR
      AND WERKS = IV_CENTRO
      AND LGORT = IV_DEPOS.

    ENDIF.

    "------------------------------------------------------------
    " Se não encontrou registo, bloqueia o envio
    "------------------------------------------------------------
    IF SY-SUBRC <> 0.

      EV_SEND = ABAP_FALSE.

      IF IV_DEPOS IS INITIAL.
        CONCATENATE
        'Registo não encontrado na ZMM_MARD_EXT para'
        'MATNR=' LV_MATNR
        'WERKS=' IV_CENTRO
        INTO LV_MSGTXT SEPARATED BY SPACE.
      ELSE.
        CONCATENATE
        'Registo não encontrado na ZMM_MARD_EXT para'
        'MATNR=' LV_MATNR
        'WERKS=' IV_CENTRO
        'LGORT=' IV_DEPOS
        INTO LV_MSGTXT SEPARATED BY SPACE.
      ENDIF.

      ZCL_THOM_HELPER=>ADD_BAL_MESSAGE(
      EXPORTING
        IV_OBJ    = IV_OBJ
        IV_SUBOBJ = IV_SUBOBJ
        IV_MSGTY  = 'E'
        IV_MSGTXT = LV_MSGTXT ).

      RETURN.
    ENDIF.

    "------------------------------------------------------------
    " Se ZZ_CONS_GERAL não estiver marcado, bloqueia
    "------------------------------------------------------------
    IF LS_MARD_EXT-ZZ_CONS_GERAL IS INITIAL
    OR LS_MARD_EXT-ZZ_CONS_GERAL = ABAP_FALSE.

      EV_SEND = ABAP_FALSE.

      IF IV_DEPOS IS INITIAL.
        CONCATENATE
        'Material bloqueado: ZZ_CONS_GERAL não marcado na ZMM_MARD_EXT para'
        'MATNR=' LV_MATNR
        'WERKS=' IV_CENTRO
        INTO LV_MSGTXT SEPARATED BY SPACE.
      ELSE.
        CONCATENATE
        'Material bloqueado: ZZ_CONS_GERAL não marcado na ZMM_MARD_EXT para'
        'MATNR=' LV_MATNR
        'WERKS=' IV_CENTRO
        'LGORT=' IV_DEPOS
        INTO LV_MSGTXT SEPARATED BY SPACE.
      ENDIF.

      ZCL_THOM_HELPER=>ADD_BAL_MESSAGE(
      EXPORTING
        IV_OBJ    = IV_OBJ
        IV_SUBOBJ = IV_SUBOBJ
        IV_MSGTY  = 'E'
        IV_MSGTXT = LV_MSGTXT ).

      RETURN.
    ENDIF.

    "------------------------------------------------------------
    " Permitido continuar
    "------------------------------------------------------------
    EV_SEND = ABAP_TRUE.
  ENDMETHOD.
