  METHOD send_enmat.
    DATA: ls_response TYPE ty_response,
          ls_enmat    TYPE zthom_enmat,
          ls_message  TYPE zcr_s_ws_output.

    DATA: lv_json        TYPE string,
          lv_http        TYPE i,
          lv_resp        TYPE string.

    DATA: lref_resp TYPE REF TO data.

    FIELD-SYMBOLS: <ls_resp>    TYPE any,
                   <lv_message> TYPE any.

    ev_sucess = abap_true.

    MOVE-CORRESPONDING is_response TO ls_enmat.
    ls_response = is_response.


    IF s_status-ws_guid_sap IS INITIAL.
      zcr_cl_intf_gen=>update_status_ws( EXPORTING iv_wsarea = v_wsarea
                                         CHANGING  cs_status  = s_status ).
      IF v_commit EQ abap_true.
        COMMIT WORK.
      ENDIF.
    ENDIF.

    mo_log = zcr_cl_intf_gen=>get_instance_log( iv_object    = v_object
                                                iv_subobject = v_subobject
                                                iv_extnumber = |{ s_status-ws_guid_sap }|
                                                iv_new_log   = abap_true ).

    IF ls_enmat-ws_guid_sap IS INITIAL.
      ls_enmat-ws_guid_sap = s_status-ws_guid_sap.
    ENDIF.

    lv_json = o_thom_http_send->response_to_json(
      EXPORTING
        i_response = ls_response
      IMPORTING
        e_hash = ls_enmat-payload_hash
    ).

    IF check_mat_changes( is_response = ls_response i_hash = ls_enmat-payload_hash i_force = i_force ) EQ abap_false.
      s_status-status = zcr_cl_intf_gen=>c_ws_status_suc.

      zcr_cl_intf_gen=>update_status_ws( IMPORTING es_message = ls_message
                                         CHANGING  cs_status  = s_status ).

      IF ls_message IS NOT INITIAL.
        mo_log->add_from_bapi( is_bapiret = ls_message ).
      ENDIF.

      mo_log->store( v_update_task ).

      EXIT.
    ENDIF.

    save_document( CHANGING cs_thom_enmat = ls_enmat ).

    o_thom_http_send->http_post_json(
    EXPORTING
      i_json      = lv_json
    IMPORTING
      e_http_code = lv_http
      e_response  = lv_resp ).

    IF lv_http <> 200.
      DO 1 TIMES.
        lref_resp = o_thom_http_send->json_to_struct( lv_resp ).
        CHECK lref_resp IS BOUND.
        ASSIGN lref_resp->* TO <ls_resp>.
        CHECK <ls_resp> IS ASSIGNED.

        ASSIGN COMPONENT 'MESSAGE' OF STRUCTURE <ls_resp> TO <lv_message>.
        CHECK <lv_message> IS ASSIGNED.
        ASSIGN <lv_message>->* TO <lv_message>.

        lv_resp = CONV string( <lv_message> ).
      ENDDO.


*     Erro no envio HTTP - &
      mo_log->add(
      EXPORTING
      id_msgty = 'E'
      id_msgid = 'ZTHOM'
      id_msgno = '011'
      id_msgv1 = lv_resp
        ).

      s_status-status = zcr_cl_intf_gen=>c_ws_status_err.
    ELSE.
      s_status-status = zcr_cl_intf_gen=>c_ws_status_suc.
    ENDIF.

    zcr_cl_intf_gen=>update_status_ws( IMPORTING es_message = ls_message
                                       CHANGING  cs_status  = s_status ).

    IF ls_message IS NOT INITIAL.
      mo_log->add_from_bapi( is_bapiret = ls_message ).
    ENDIF.

    mo_log->store( ).

    IF v_commit EQ abap_true.
      COMMIT WORK AND WAIT.
    ENDIF.

  ENDMETHOD.
