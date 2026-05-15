  METHOD set_process_as_interface.
    DATA: lv_thom_document TYPE flag.

    lv_thom_document = abap_true.
    SET PARAMETER ID 'ZTHOM_ENMAT' FIELD lv_thom_document.
  ENDMETHOD.
