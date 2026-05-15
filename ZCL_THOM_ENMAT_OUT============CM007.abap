  METHOD PROCESS.
    DATA: LT_ZMM_MARD_EXT TYPE SORTED TABLE OF ZMM_MARD_EXT WITH UNIQUE KEY MATNR WERKS LGORT,
          LT_EINA         TYPE TABLE OF EINA,
          LT_EINE         TYPE TABLE OF EINE,
          LT_MARC         TYPE TABLE OF MARC,
          LT_MARD         TYPE TABLE OF MARD,
          LT_AUSP         TYPE TABLE OF AUSP.

    DATA: LS_RESPONSE     TYPE TY_RESPONSE,
          LS_ZMM_MARD_EXT TYPE ZMM_MARD_EXT,
          LS_MARC         TYPE MARC,
          LS_MARD         TYPE MARD,
          LS_EINA         TYPE EINA,
          LS_EINE         TYPE EINE,
          LS_MAKT         TYPE MAKT,
          LS_MARA         TYPE MARA,
          LS_AUSP         TYPE AUSP.

    DATA: LV_MATNR TYPE MATNR.

**    DO 30 TIMES.
**      WAIT UP TO 1 SECONDS.
**    ENDDO.

** Clean Matrial
******************************************************************
    CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
      EXPORTING
        INPUT        = I_MATNR
      IMPORTING
        OUTPUT       = LV_MATNR
      EXCEPTIONS
        LENGTH_ERROR = 1
        OTHERS       = 2.

    IF IS_MARA IS NOT INITIAL.
      LV_MATNR = IS_MARA-MATNR.
    ENDIF.

    CHECK LV_MATNR IS NOT INITIAL.

** Basic Data
******************************************************************

    IF IS_MARA IS INITIAL.
      SELECT SINGLE * FROM MARA
                      INTO LS_MARA
                      WHERE MATNR = LV_MATNR.
    ELSE.
      LS_MARA = IS_MARA.
    ENDIF.

    CHECK LS_MARA-ZSEND_THOM EQ ABAP_TRUE.

    SELECT SINGLE * FROM MAKT
                    INTO LS_MAKT
                    WHERE MATNR = LV_MATNR AND
                          SPRAS = 'P'.

** Plant Data
******************************************************************
    IF IS_MARC IS  INITIAL AND
       ( I_WERKS IS NOT INITIAL OR I_GET_ALL EQ ABAP_TRUE ).
      SELECT * FROM MARC
               INTO TABLE LT_MARC
               WHERE MATNR = LV_MATNR.
    ELSE.
      LS_MARC = IS_MARC.
      IF LS_MARC-MATNR IS INITIAL.
        LS_MARC-MATNR = LS_MARA-MATNR.
      ENDIF.
      APPEND LS_MARC TO LT_MARC.
    ENDIF.

** Stg Loc Data
******************************************************************
    IF IS_MARD IS INITIAL AND
       ( I_LGORT IS NOT INITIAL OR I_GET_ALL EQ ABAP_TRUE ).
      SELECT * FROM MARD
               INTO TABLE LT_MARD
               WHERE MATNR = LV_MATNR.
    ELSE.
      LS_MARD = IS_MARD.
      IF LS_MARD-MATNR IS INITIAL.
        LS_MARD-MATNR = LS_MARA-MATNR.
      ENDIF.
      IF LS_MARD-WERKS IS INITIAL.
        LS_MARD-WERKS = IS_MARC-WERKS.
      ENDIF.
      APPEND LS_MARD TO LT_MARD.
    ENDIF.

    SELECT * FROM ZMM_MARD_EXT
             INTO TABLE LT_ZMM_MARD_EXT
             WHERE MATNR = LV_MATNR.

    DO 1 TIMES.
      SELECT * FROM EINA
               INTO TABLE LT_EINA
               WHERE MATNR = LV_MATNR AND
                     RELIF = ABAP_TRUE.

      CHECK SY-SUBRC <> 0.

      SELECT * FROM EINA
               INTO TABLE LT_EINA
               WHERE MATNR = LV_MATNR.
    ENDDO.

** Other Data
******************************************************************
    IF LT_EINA IS NOT INITIAL.
      SELECT * FROM EINE
              INTO TABLE LT_EINE
              FOR ALL ENTRIES IN LT_EINA
              WHERE INFNR = LT_EINA-INFNR.
    ENDIF.

    DATA(LV_PATTERN) = |%{ LV_MATNR }%|.

    SELECT *
      FROM AUSP
      INTO TABLE LT_AUSP
      WHERE OBJEK LIKE LV_PATTERN AND
            ATINN = '0000000825'.

** Filter
******************************************************************
    IF I_WERKS IS NOT INITIAL.
      DELETE LT_MARC WHERE WERKS <> I_WERKS.
      DELETE LT_MARD WHERE WERKS <> I_WERKS.
      DELETE LT_ZMM_MARD_EXT WHERE WERKS <> I_WERKS.
    ENDIF.

    IF I_LGORT IS NOT INITIAL.
      DELETE LT_MARD WHERE LGORT <> I_LGORT.
      DELETE LT_ZMM_MARD_EXT WHERE LGORT <> I_LGORT.
    ENDIF.

** Default Data
******************************************************************
    IF LT_MARC IS INITIAL.
      CLEAR: LS_MARC.
      APPEND LS_MARC TO LT_MARC.
    ENDIF.

    IF LT_MARD IS INITIAL.
      CLEAR: LS_MARD.
      APPEND LS_MARD TO LT_MARD.
    ENDIF.

** Process
******************************************************************
    LOOP AT LT_MARC INTO LS_MARC.
      LOOP AT LT_MARD INTO LS_MARD WHERE ( WERKS = LS_MARC-WERKS ) OR
                                         ( WERKS IS INITIAL AND LGORT IS INITIAL ).

        MOVE-CORRESPONDING LS_MARA TO LS_RESPONSE.
        LS_RESPONSE-ZLONG_TEXT = LS_MARA-ZDESC_MAT.
        LS_RESPONSE-ZDESC_MAT  = LS_MARA-ZDESC_MAT.

        IF LS_MARC-MATNR IS NOT INITIAL AND LS_MARC-WERKS IS NOT INITIAL.
          MOVE-CORRESPONDING LS_MARC TO LS_RESPONSE.
        ENDIF.

        IF LS_MARD-MATNR IS NOT INITIAL AND LS_MARD-WERKS IS NOT INITIAL AND LS_MARD-LGORT IS NOT INITIAL.
          MOVE-CORRESPONDING LS_MARD TO LS_RESPONSE.

          CLEAR: LS_ZMM_MARD_EXT.
          READ TABLE LT_ZMM_MARD_EXT
                INTO LS_ZMM_MARD_EXT
                WITH TABLE KEY MATNR = LS_MARD-MATNR
                               WERKS = LS_MARD-WERKS
                               LGORT = LS_MARD-LGORT.

          IF LS_ZMM_MARD_EXT IS NOT INITIAL.
            MOVE-CORRESPONDING LS_ZMM_MARD_EXT TO LS_RESPONSE.
          ENDIF.
        ENDIF.

        IF LS_MAKT-MATNR IS NOT INITIAL AND LS_MAKT-MAKTX IS NOT INITIAL.
          LS_RESPONSE-MAKTX = LS_MAKT-MAKTX.
        ENDIF.

        IF LS_RESPONSE-ZDESC_MAT IS INITIAL.
          LS_RESPONSE-ZDESC_MAT = LS_RESPONSE-MAKTX.
        ENDIF.

        IF LS_RESPONSE-ZLONG_TEXT IS INITIAL.
          LS_RESPONSE-ZLONG_TEXT = LS_RESPONSE-MAKTX.
        ENDIF.

        "" Get Type of Message
        IF LS_RESPONSE-WERKS IS NOT INITIAL AND LS_RESPONSE-LGORT IS NOT INITIAL.
          LS_RESPONSE-TIPO_MENSAGEM = C_TIPO_MENSAGEM-DEPOSITO.
        ELSEIF LS_RESPONSE-WERKS IS NOT INITIAL.
          LS_RESPONSE-TIPO_MENSAGEM = C_TIPO_MENSAGEM-CENTRO.
        ELSE.
          LS_RESPONSE-TIPO_MENSAGEM = C_TIPO_MENSAGEM-BASICO.
        ENDIF.

        "" Delete Material
        IF LS_MARA-LVORM EQ ABAP_TRUE.
          LS_RESPONSE-EVENT_TYPE = C_EVENT-DELETE.
          LS_RESPONSE-TIPO_MENSAGEM = C_TIPO_MENSAGEM-BASICO.
        ELSEIF LS_MARC-WERKS IS NOT INITIAL AND LS_MARC-LVORM EQ ABAP_TRUE.
          LS_RESPONSE-EVENT_TYPE = C_EVENT-DELETE.
          CLEAR LS_RESPONSE-LVORM.
          LS_RESPONSE-TIPO_MENSAGEM = C_TIPO_MENSAGEM-CENTRO.
        ELSEIF LS_MARD-WERKS IS NOT INITIAL AND LS_MARD-LGORT IS NOT INITIAL AND LS_MARD-LVORM EQ ABAP_TRUE.
          LS_RESPONSE-EVENT_TYPE = C_EVENT-DELETE.
          CLEAR LS_RESPONSE-LVORM.
          LS_RESPONSE-TIPO_MENSAGEM = C_TIPO_MENSAGEM-DEPOSITO.
        ENDIF.


        "Validação ZZ_CONS_GERAL - Se campo estiver em branco, não deixa ser enviado
        "Begin - Insert by Score - APO - 17.04.2026
        IF LS_RESPONSE-TIPO_MENSAGEM <> C_TIPO_MENSAGEM-BASICO.

          DATA(LV_SEND) = ABAP_FALSE.

          ZCL_THOM_HELPER=>CHECK_CONS_GERAL(
          EXPORTING
            IV_CENTRO = LS_RESPONSE-WERKS
            IV_DEPOS  = LS_RESPONSE-LGORT
            IV_MATNR  = LS_RESPONSE-MATNR
            IV_OBJ    = 'ZTHOM'
            IV_SUBOBJ = 'ENVMAT'
          IMPORTING
            EV_SEND   = LV_SEND ).

          IF LV_SEND <> ABAP_TRUE.
            CONTINUE.
          ENDIF.
        ENDIF.
        "End - Insert by Score - APO - 17.04.2026
        LOOP AT LT_EINA INTO LS_EINA.
          LOOP AT LT_EINE INTO LS_EINE WHERE INFNR = LS_EINA-INFNR.
            IF LS_EINE-ZZ_EAN13 IS NOT INITIAL.
              APPEND LS_EINE-ZZ_EAN13 TO LS_RESPONSE-ZZEAN_13.
            ENDIF.

            IF LS_EINE-ZZ_EAN11 IS NOT INITIAL.
              APPEND LS_EINE-ZZ_EAN11 TO LS_RESPONSE-ZZEAN_11.
            ENDIF.
          ENDLOOP.
        ENDLOOP.

        IF LS_ZMM_MARD_EXT-ZZ_ADM_LOTES_THOM <> ABAP_TRUE.
          CLEAR: LS_RESPONSE-XCHPF.
        ENDIF.

        LOOP AT LT_AUSP INTO LS_AUSP.
          APPEND LS_AUSP-ATWRT TO LS_RESPONSE-URZNRX.
        ENDLOOP.

        SORT LS_RESPONSE-URZNRX.
        DELETE ADJACENT DUPLICATES FROM LS_RESPONSE-URZNRX COMPARING ALL FIELDS.

        READ TABLE LS_RESPONSE-URZNRX
              INTO LS_RESPONSE-URZNR
              INDEX 1.

        SORT LS_RESPONSE-ZZEAN_13.
        DELETE ADJACENT DUPLICATES FROM LS_RESPONSE-ZZEAN_13 COMPARING ALL FIELDS.

        SORT LS_RESPONSE-ZZEAN_11.
        DELETE ADJACENT DUPLICATES FROM LS_RESPONSE-ZZEAN_11 COMPARING ALL FIELDS.

        CALL FUNCTION 'CONVERSION_EXIT_MATN1_OUTPUT'
          EXPORTING
            INPUT  = LS_RESPONSE-MATNR
          IMPORTING
            OUTPUT = LS_RESPONSE-MATNR.

        IF I_EVENT_TYPE IS NOT INITIAL.
          LS_RESPONSE-EVENT_TYPE = I_EVENT_TYPE.
        ELSE.
          LS_RESPONSE-EVENT_TYPE = CHECK_MAT_CHANGES( IS_RESPONSE = LS_RESPONSE I_FORCE = ABAP_TRUE ).
        ENDIF.

        IF I_REPROCESS EQ ABAP_FALSE.
          CLEAR: S_STATUS-WS_GUID_SAP.
        ENDIF.
        SEND_ENMAT( IS_RESPONSE = LS_RESPONSE ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
