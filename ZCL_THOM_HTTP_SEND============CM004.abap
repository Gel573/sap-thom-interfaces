  METHOD get_endpoint.
    DATA: lv_service_id TYPE ze_service_id.

    DATA lo_cx TYPE REF TO cx_root.

    CLEAR es_ep.
    CLEAR: v_last_cfg_service, v_last_cfg_message.

    lv_service_id = v_service_id.
    IF i_service_id IS NOT INITIAL.
      lv_service_id = i_service_id.
    ENDIF.

    TRY.
        SELECT SINGLE *
        FROM zthom_endpoints
        INTO es_ep
        WHERE service_id = lv_service_id
        AND env        = v_env.

        IF sy-subrc <> 0.
          v_last_cfg_service = lv_service_id.
          v_last_cfg_message = 'Endpoint não encontrado para SERVICE_ID/ENV.'.
        ENDIF.

      CATCH cx_sy_open_sql_db INTO lo_cx.
        v_last_cfg_service = lv_service_id.
        v_last_cfg_message = lo_cx->get_text( ).
        CLEAR es_ep.
      CATCH cx_root INTO lo_cx.
        v_last_cfg_service = lv_service_id.
        v_last_cfg_message = lo_cx->get_text( ).
        CLEAR es_ep.
    ENDTRY.
  ENDMETHOD.
