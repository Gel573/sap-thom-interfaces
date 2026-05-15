  METHOD constructor.


    IF iv_wsid IS NOT INITIAL.
      s_status-wsid = iv_wsid.
    ELSE.
      s_status-wsid = c_wsid.
    ENDIF.

    IF iv_wsarea IS NOT INITIAL.
      v_wsarea = iv_wsarea.
    ELSE.
      v_wsarea = zcr_cl_intf_gen=>c_ws_wsarea_mm.
    ENDIF.

    IF iv_object IS NOT INITIAL.
      v_object = iv_object.
    ELSE.
      v_object = CONV balobj_d( zcr_cl_pre_defined_values=>get_value( iv_repid     = 'ZMM_INTF'
                                                                           iv_parid     = 'OBJETO_LOG_INTERFACES'
                                                                           iv_tablename = 'ZMM_TB_CONST' ) ).
    ENDIF.

    IF iv_subobject IS NOT INITIAL.
      v_subobject = iv_subobject.
    ELSE.
      v_subobject = CONV balsubobj( zcr_cl_pre_defined_values=>get_value( iv_repid     = 'ZMM_INTF'
                                                                                     iv_parid     = 'SUBOBJ_LOG_INTERF_OUT'
                                                                                     iv_tablename = 'ZMM_TB_CONST' ) ).
    ENDIF.

    IF iv_extnumber IS NOT INITIAL.
      v_extnumber = iv_extnumber.
      s_status-ws_guid_sap = iv_extnumber.
    ENDIF.

    o_thom_http_send = NEW zcl_thom_http_send( i_service_id = 'ENMAT' ).

    v_commit = iv_commit.

    IF v_commit EQ abap_false.
      v_update_task = abap_true.
    ENDIF.

  ENDMETHOD.
