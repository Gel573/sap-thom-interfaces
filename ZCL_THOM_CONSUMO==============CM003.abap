  METHOD cancel_document.

    DATA: lt_zfi_xref_thom_t TYPE TABLE OF zfi_xref_thom_t.

    DATA: ls_message          TYPE bdcmsgcoll,
          ls_goodsmvt_item    TYPE bapi2017_gm_item_create,
          ls_return           TYPE bapiret2,
          lt_return           TYPE TABLE OF bapiret2,
          ls_goodsmvt_headret	TYPE bapi2017_gm_head_ret.

    DATA: ls_document        TYPE ty_document.

***********************************************************************
    CLEAR: et_messages, e_mblnr, e_mjahr, et_mseg.

    CHECK cs_document IS NOT INITIAL.

    IF cs_document-msgid IS INITIAL.
**    Número de mensagem inválido
      ls_message-msgtyp = 'E'.
      ls_message-msgid  = 'ZTHOM'.
      ls_message-msgnr  = '002'.
      APPEND ls_message TO et_messages.
      CLEAR  ls_message.
      RAISE error_data.
    ENDIF.

    IF cs_document-mblnr IS INITIAL.
**    Número de Documento Material & inválido
      ls_message-msgtyp = 'E'.
      ls_message-msgid  = 'ZTHOM'.
      ls_message-msgnr  = '009'.
      ls_message-msgv1  = cs_document-mblnr.
      APPEND ls_message TO et_messages.
      CLEAR  ls_message.
      RAISE error_data.
    ENDIF.

    IF cs_document-mjahr IS INITIAL.
**    Número de Documento Material & inválido
      ls_message-msgtyp = 'E'.
      ls_message-msgid  = 'ZTHOM'.
      ls_message-msgnr  = '010'.
      ls_message-msgv1  = cs_document-mjahr.
      APPEND ls_message TO et_messages.
      CLEAR  ls_message.
      RAISE error_data.
    ENDIF.

** Executa Movimento
***********************************************************************
    set_process_as_interface( ).
    CALL FUNCTION 'BAPI_GOODSMVT_CANCEL'
      EXPORTING
        materialdocument = cs_document-mblnr
        matdocumentyear  = cs_document-mjahr
      IMPORTING
        goodsmvt_headret = ls_goodsmvt_headret
      TABLES
        return           = lt_return.

** Pesquisa de Erros
***********************************************************************
    LOOP AT lt_return INTO ls_return WHERE type = 'E'
                                        OR type = 'A'.
      MOVE ls_return-type       TO ls_message-msgtyp.
      MOVE ls_return-id         TO ls_message-msgid.
      MOVE ls_return-number     TO ls_message-msgnr.
      MOVE ls_return-message_v1 TO ls_message-msgv1.
      MOVE ls_return-message_v2 TO ls_message-msgv2.
      MOVE ls_return-message_v3 TO ls_message-msgv3.
      MOVE ls_return-message_v4 TO ls_message-msgv4.
      APPEND ls_message TO et_messages.
      CLEAR  ls_message.
    ENDLOOP.
    IF sy-subrc EQ 0.
      IF i_commit EQ abap_true.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      ENDIF.
      RAISE error.
    ENDIF.

** Finaliza
***********************************************************************
    IF i_commit EQ abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
    ENDIF.

    cs_document-mblnr = ls_goodsmvt_headret-mat_doc.
    cs_document-mjahr = ls_goodsmvt_headret-doc_year.
  ENDMETHOD.
