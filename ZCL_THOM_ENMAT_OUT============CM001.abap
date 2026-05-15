  METHOD check_mat_changes.
    DATA: lr_structdescr TYPE REF TO cl_abap_structdescr.

    DATA: lt_enmat      TYPE TABLE OF zthom_enmat,
          lt_components TYPE cl_abap_structdescr=>component_table.

    DATA: ls_mara      TYPE mara,
          ls_marc      TYPE marc,
          ls_mard      TYPE mard,
          ls_enmat_new TYPE zthom_enmat,
          ls_enmat_old TYPE zthom_enmat,
          ls_enmat     TYPE zthom_enmat,
          ls_component LIKE LINE OF lt_components.

    DATA: lv_checked TYPE flag.

    FIELD-SYMBOLS: <lv_old> TYPE any,
                   <lv_new> TYPE any.

    CHECK is_response IS NOT INITIAL.

    lr_structdescr ?= cl_abap_typedescr=>describe_by_data( is_response ).
    lt_components = lr_structdescr->get_components( ).

    IF is_response-event_type EQ c_event-delete.
      r_status = is_response-event_type.
      EXIT.
    ENDIF.

    SELECT * FROM zthom_enmat AS a
             INNER JOIN zcr_tb_ws_status AS b
                     ON b~ws_guid_sap = a~ws_guid_sap
              INTO CORRESPONDING FIELDS OF TABLE @lt_enmat
              WHERE a~tipo_mensagem = @is_response-tipo_mensagem AND
                    a~matnr = @is_response-matnr AND
                    b~status = @zcr_cl_intf_gen=>c_ws_status_suc
              ORDER BY erdat DESCENDING, erzet DESCENDING.


    IF is_response-werks IS NOT INITIAL.
      DELETE lt_enmat WHERE werks <> is_response-werks.
      DELETE lt_enmat WHERE werks <> is_response-werks.
    ENDIF.

    IF is_response-lgort IS NOT INITIAL.
      DELETE lt_enmat WHERE lgort <> is_response-lgort.
    ENDIF.

    IF lt_enmat IS INITIAL.
      r_status = c_event-create.
      RETURN.
    ELSEIF i_force EQ abap_true.
      r_status = c_event-edit.
      RETURN.
    ENDIF.

    LOOP AT lt_enmat INTO ls_enmat.

      IF i_hash IS NOT INITIAL AND
         ls_enmat-payload_hash IS NOT INITIAL AND
        i_hash EQ ls_enmat-payload_hash.
        CLEAR: r_status.
        RETURN.
      ENDIF.


      LOOP AT lt_components INTO ls_component.
        UNASSIGN <lv_old>.
        ASSIGN COMPONENT ls_component-name OF STRUCTURE ls_enmat TO <lv_old>.
        CHECK <lv_old> IS ASSIGNED.

        UNASSIGN <lv_new>.
        ASSIGN COMPONENT ls_component-name OF STRUCTURE is_response TO <lv_new>.
        CHECK <lv_new> IS ASSIGNED.

        lv_checked = abap_true.

        CHECK <lv_new> <> <lv_old>.

        r_status = c_event-edit.
        RETURN.
      ENDLOOP.

      IF lv_checked EQ abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
