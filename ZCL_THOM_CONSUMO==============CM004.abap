  METHOD is_process_interface.
    DATA: lv_thom_document TYPE flag.

    GET PARAMETER ID 'ZTHOM_DOCUNENT' FIELD lv_thom_document.

    IF lv_thom_document IS NOT INITIAL.
      r_valid = abap_true.
    ENDIF.
  ENDMETHOD.
