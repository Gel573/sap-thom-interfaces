METHOD ADD_BAL_MESSAGE.

  DATA: LS_LOG        TYPE BAL_S_LOG,
        LS_MSG        TYPE BAL_S_MSG,
        LV_LOG_HANDLE TYPE BALLOGHNDL,
        LT_LOG_HANDLE TYPE BAL_T_LOGH,
        LV_TEXT1      TYPE SYMSGV,
        LV_TEXT2      TYPE SYMSGV,
        LV_TEXT3      TYPE SYMSGV,
        LV_TEXT4      TYPE SYMSGV,
        LV_LEN        TYPE I,
        LV_PART_LEN   TYPE I.

  CLEAR: LS_LOG, LS_MSG, LV_LOG_HANDLE,
  LV_TEXT1, LV_TEXT2, LV_TEXT3, LV_TEXT4.
  REFRESH LT_LOG_HANDLE.

  TRY.

      "--------------------------------------------------------
      " Cria log
      "--------------------------------------------------------
      LS_LOG-OBJECT    = IV_OBJ.
      LS_LOG-SUBOBJECT = IV_SUBOBJ.
      LS_LOG-ALUSER    = SY-UNAME.
      LS_LOG-ALPROG    = SY-REPID.
      LS_LOG-ALTCODE   = SY-TCODE.
      LS_LOG-ALDATE    = SY-DATUM.
      LS_LOG-ALTIME    = SY-UZEIT.

      CALL FUNCTION 'BAL_LOG_CREATE'
        EXPORTING
          I_S_LOG                 = LS_LOG
        IMPORTING
          E_LOG_HANDLE            = LV_LOG_HANDLE
        EXCEPTIONS
          LOG_HEADER_INCONSISTENT = 1
          OTHERS                  = 2.

      IF SY-SUBRC <> 0 OR LV_LOG_HANDLE IS INITIAL.
        RETURN.
      ENDIF.

      "--------------------------------------------------------
      " Quebra segura da mensagem em 4 partes de até 50 chars
      "--------------------------------------------------------
      LV_LEN = STRLEN( IV_MSGTXT ).

      IF LV_LEN > 0.
        LV_PART_LEN = LV_LEN.
        IF LV_PART_LEN > 50.
          LV_PART_LEN = 50.
        ENDIF.
        LV_TEXT1 = IV_MSGTXT+0(LV_PART_LEN).
      ENDIF.

      IF LV_LEN > 50.
        LV_PART_LEN = LV_LEN - 50.
        IF LV_PART_LEN > 50.
          LV_PART_LEN = 50.
        ENDIF.
        LV_TEXT2 = IV_MSGTXT+50(LV_PART_LEN).
      ENDIF.

      IF LV_LEN > 100.
        LV_PART_LEN = LV_LEN - 100.
        IF LV_PART_LEN > 50.
          LV_PART_LEN = 50.
        ENDIF.
        LV_TEXT3 = IV_MSGTXT+100(LV_PART_LEN).
      ENDIF.

      IF LV_LEN > 150.
        LV_PART_LEN = LV_LEN - 150.
        IF LV_PART_LEN > 50.
          LV_PART_LEN = 50.
        ENDIF.
        LV_TEXT4 = IV_MSGTXT+150(LV_PART_LEN).
      ENDIF.

      "--------------------------------------------------------
      " Monta mensagem
      "--------------------------------------------------------
      LS_MSG-MSGTY = IV_MSGTY.
      LS_MSG-MSGID = '00'.
      LS_MSG-MSGNO = '398'.
      LS_MSG-MSGV1 = LV_TEXT1.
      LS_MSG-MSGV2 = LV_TEXT2.
      LS_MSG-MSGV3 = LV_TEXT3.
      LS_MSG-MSGV4 = LV_TEXT4.

      CALL FUNCTION 'BAL_LOG_MSG_ADD'
        EXPORTING
          I_LOG_HANDLE     = LV_LOG_HANDLE
          I_S_MSG          = LS_MSG
        EXCEPTIONS
          LOG_NOT_FOUND    = 1
          MSG_INCONSISTENT = 2
          LOG_IS_FULL      = 3
          OTHERS           = 4.

      IF SY-SUBRC <> 0.
        RETURN.
      ENDIF.

      "--------------------------------------------------------
      " Salva no banco
      "--------------------------------------------------------
      APPEND LV_LOG_HANDLE TO LT_LOG_HANDLE.

      CALL FUNCTION 'BAL_DB_SAVE'
        EXPORTING
          I_T_LOG_HANDLE   = LT_LOG_HANDLE
        EXCEPTIONS
          LOG_NOT_FOUND    = 1
          SAVE_NOT_ALLOWED = 2
          NUMBERING_ERROR  = 3
          OTHERS           = 4.

      IF SY-SUBRC <> 0.
        RETURN.
      ENDIF.

    CATCH CX_ROOT.
      RETURN.
  ENDTRY.

ENDMETHOD.
