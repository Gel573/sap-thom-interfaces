  METHOD save_document.
    DATA: ls_zthom_enmat TYPE zthom_enmat.

    DATA: lv_error TYPE flag.

    ls_zthom_enmat = cs_thom_enmat.

    MODIFY zthom_enmat FROM ls_zthom_enmat.
    CHECK sy-subrc EQ 0.

    IF v_commit EQ abap_true.
      COMMIT WORK.
    ENDIF.
  ENDMETHOD.
