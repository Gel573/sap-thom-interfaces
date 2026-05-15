METHOD GET_LOTES.

  DATA: LV_MATNR_DB TYPE MATNR,
        LS_CACHE    TYPE TY_CACHE_LOTES.

  CLEAR: EV_LOT_THOM,
         EV_SND_THOM,
         EV_VFDAT,
         EV_CLABS,
         EV_LOTE,
         EV_CONS.

  CLEAR: LV_MATNR_DB.

  LV_MATNR_DB = IV_MATNR.

  "--------------------------------------------------
  " Conversão do material
  "--------------------------------------------------
  IF LV_MATNR_DB IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        INPUT        = LV_MATNR_DB
      IMPORTING
        OUTPUT       = LV_MATNR_DB
      EXCEPTIONS
        LENGTH_ERROR = 1
        OTHERS       = 2.
    IF SY-SUBRC <> 0.
      CLEAR LV_MATNR_DB.
      RETURN.
    ENDIF.
  ENDIF. "IF LV_MATNR_DB IS NOT INITIAL.

  "--------------------------------------------------
  " Cache
  "--------------------------------------------------
  READ TABLE GT_CACHE_LOTES INTO LS_CACHE
  WITH TABLE KEY  MATNR = LV_MATNR_DB
                  WERKS = IV_WERKS
                  LGORT = IV_LGORT
                  CHARG = IV_CHARG
                  CONSG = IV_CONSG.

  IF SY-SUBRC = 0.
    EV_SND_THOM = LS_CACHE-SND.
    EV_LOT_THOM = LS_CACHE-LOT.
    EV_CONS     = LS_CACHE-CONS.
    EV_VFDAT    = LS_CACHE-VFDAT.
    EV_CLABS    = LS_CACHE-CLABS.
    EV_LOTE     = LS_CACHE-LOTE.
    RETURN.
  ENDIF.

  TRY.
      "--------------------------------------------------
      " MARA
      "    ZSEND_THOM
      "    XCHPF
      "    ZMAT_CONSIG
      "--------------------------------------------------
      SELECT SINGLE ZSEND_THOM
      XCHPF
      ZMAT_CONSIG
      INTO (EV_SND_THOM, EV_LOTE, EV_CONS)
      FROM MARA
      WHERE MATNR = LV_MATNR_DB.

      IF SY-SUBRC <> 0.
        CLEAR: EV_SND_THOM,
                EV_LOTE,
                EV_CONS.
      ENDIF.

      IF IV_LGORT IS INITIAL.

        SELECT SINGLE ZZ_ADM_LOTES_THOM
        INTO EV_LOT_THOM
        FROM ZMM_MARD_EXT
        WHERE MATNR = LV_MATNR_DB
        AND WERKS = IV_WERKS.

      ELSE. "IF IV_LGORT IS INITIAL.

        SELECT SINGLE ZZ_ADM_LOTES_THOM
        INTO EV_LOT_THOM
        FROM ZMM_MARD_EXT
        WHERE MATNR = LV_MATNR_DB
        AND WERKS = IV_WERKS
        AND LGORT = IV_LGORT.

      ENDIF. "IF IV_LGORT IS INITIAL.

      IF SY-SUBRC <> 0.
        CLEAR EV_LOT_THOM.
      ENDIF.

      "--------------------------------------------------
      " Normalização flags
      "--------------------------------------------------
      TRANSLATE EV_SND_THOM TO UPPER CASE.
      TRANSLATE EV_LOT_THOM TO UPPER CASE.
      TRANSLATE EV_CONS     TO UPPER CASE.

      "--------------------------------------------------
      " Data de validade do lote
      "--------------------------------------------------
      IF LV_MATNR_DB IS NOT INITIAL
      AND IV_CHARG    IS NOT INITIAL.

        SELECT SINGLE VFDAT
        INTO EV_VFDAT
        FROM MCH1
        WHERE MATNR = LV_MATNR_DB
        AND CHARG = IV_CHARG.

        IF SY-SUBRC <> 0.
          CLEAR EV_VFDAT.
        ENDIF.
      ENDIF. "IF LV_MATNR_DB IS NOT INITIAL

      "--------------------------------------------------
      " Stock
      "    Normal     -> MCHB-CLABS
      "    Consignado -> MKOL-SLABS
      "--------------------------------------------------
      IF IV_CONSG EQ ABAP_FALSE.
        IF IV_LGORT IS NOT INITIAL.

          SELECT SINGLE CLABS
          INTO EV_CLABS
          FROM MCHB
          WHERE MATNR = LV_MATNR_DB
          AND WERKS = IV_WERKS
          AND LGORT = IV_LGORT
          AND CHARG = IV_CHARG.

          IF SY-SUBRC <> 0.
            CLEAR EV_CLABS.
          ENDIF.

        ELSE."IF iv_lgort IS NOT INITIAL.

          SELECT SUM( CLABS )
          INTO EV_CLABS
          FROM MCHB
          WHERE MATNR = LV_MATNR_DB
          AND WERKS = IV_WERKS
          AND CHARG = IV_CHARG.

          IF SY-SUBRC <> 0.
            CLEAR EV_CLABS.
          ENDIF.
        ENDIF. "IF IV_LGORT IS NOT INITIAL.

      ELSE. "IF IV_CONSG EQ ABAP_FALSE.
        IF IV_LGORT IS NOT INITIAL.
          SELECT SUM( SLABS )
          INTO EV_CLABS
          FROM MKOL
          WHERE MATNR = LV_MATNR_DB
          AND WERKS = IV_WERKS
          AND LGORT = IV_LGORT
          AND CHARG = IV_CHARG.

          IF SY-SUBRC <> 0.
            CLEAR EV_CLABS.
          ENDIF.

        ELSE. "IF IV_LGORT IS NOT INITIAL.
          SELECT SUM( SLABS )
          INTO EV_CLABS
          FROM MKOL
          WHERE MATNR = LV_MATNR_DB
          AND WERKS = IV_WERKS
          AND CHARG = IV_CHARG.

          IF SY-SUBRC <> 0.
            CLEAR EV_CLABS.
          ENDIF.
        ENDIF. "IF IV_LGORT IS NOT INITIAL.
      ENDIF. "IF IV_CONSG EQ ABAP_FALSE.

    CATCH CX_ROOT.
      CLEAR: EV_LOT_THOM,
             EV_SND_THOM,
             EV_VFDAT,
             EV_CLABS,
             EV_LOTE,
             EV_CONS.
  ENDTRY.

  "--------------------------------------------------
  " Guardar cache
  "--------------------------------------------------
  CLEAR LS_CACHE.
  LS_CACHE-MATNR = LV_MATNR_DB.
  LS_CACHE-WERKS = IV_WERKS.
  LS_CACHE-LGORT = IV_LGORT.
  LS_CACHE-CHARG = IV_CHARG.
  LS_CACHE-CONSG = IV_CONSG.
  LS_CACHE-SND   = EV_SND_THOM.
  LS_CACHE-LOT   = EV_LOT_THOM.
  LS_CACHE-CONS  = EV_CONS.
  LS_CACHE-VFDAT = EV_VFDAT.
  LS_CACHE-CLABS = EV_CLABS.
  LS_CACHE-LOTE  = EV_LOTE.

  INSERT LS_CACHE INTO TABLE GT_CACHE_LOTES.

ENDMETHOD.
