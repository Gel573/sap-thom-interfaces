  METHOD http_post_json.
    DATA: lo_http   TYPE REF TO if_http_client,
          lv_code   TYPE i,
          lv_reason TYPE string,
          lv_auth   TYPE string,
          lv_userpw TYPE string,
          lv_b64    TYPE string,
          lo_cx     TYPE REF TO cx_root.

    CLEAR: e_http_code, e_response.


    DATA: lv_url  TYPE string.

*    v_http_dest = 'https://thompre.jcs.pt'.
    "v_http_dest = '10.241.70.107'.
*    v_auth_user = 'SapStockApiUser'.
*    v_auth_pass = '4v9cmnUMmkCwY3esLWGq'.

    lv_url = v_url.

    TRY.
        cl_http_client=>create_by_url(
        EXPORTING url = lv_url
        IMPORTING client      = lo_http
        EXCEPTIONS
          argument_not_found = 1
          plugin_not_active = 2
          internal_error = 3
          OTHERS = 4
          ).

        IF sy-subrc <> 0.
          e_http_code = 0.
          e_response  = ''.
          RETURN.
        ENDIF.

      CATCH cx_root INTO lo_cx.
        e_http_code = 0.
        e_response  = lo_cx->get_text( ).
        RETURN.
    ENDTRY.

    "Evitar popup
    TRY.
        lo_http->propertytype_logon_popup = lo_http->co_disabled.
      CATCH cx_root.
    ENDTRY.

**    v_path = '/JCSErp/ProductCreatedOrChanged'.

    "URI
    IF v_path IS NOT INITIAL.
      TRY.
          cl_http_utility=>set_request_uri(
          request = lo_http->request
          uri     = v_path ).
        CATCH cx_root INTO lo_cx.
          e_http_code = 0.
          e_response  = lo_cx->get_text( ).
          TRY.
              lo_http->close( ).
            CATCH cx_root.
          ENDTRY.
          RETURN.
      ENDTRY.
    ENDIF.

    lo_http->request->set_method( if_http_request=>co_request_method_post ).
    lo_http->request->set_header_field( name = 'Content-Type' value = 'application/json' ).
    lo_http->request->set_header_field( name = 'Accept'       value = 'application/json' ).

    "Auth: Basic primeiro
    IF v_auth_user IS NOT INITIAL OR v_auth_pass IS NOT INITIAL.
      CONCATENATE v_auth_user v_auth_pass INTO lv_userpw SEPARATED BY ':'.
      TRY.
          lv_b64 = cl_http_utility=>encode_base64( unencoded = lv_userpw ).
          CONCATENATE 'Basic' lv_b64 INTO lv_auth SEPARATED BY space.
          lo_http->request->set_header_field( name = 'Authorization' value = lv_auth ).
        CATCH cx_root.
          "sem dump
      ENDTRY.
    ELSEIF v_bearer IS NOT INITIAL.
      CONCATENATE 'Bearer' v_bearer INTO lv_auth SEPARATED BY space.
      lo_http->request->set_header_field( name = 'Authorization' value = lv_auth ).
    ENDIF.

    lo_http->request->set_cdata( i_json ).

    TRY.
        lo_http->send( timeout = v_timeout_sec ).
        lo_http->receive(
        EXCEPTIONS
          http_communication_failure = 1
          http_invalid_state         = 2
          http_processing_failed     = 3
          OTHERS                     = 4  ).

        lo_http->response->get_status( IMPORTING code = lv_code reason = lv_reason ).
        e_http_code = lv_code.
        e_response  = lo_http->response->get_cdata( ).
      CATCH cx_root INTO lo_cx.
        e_http_code = 0.
        e_response  = lo_cx->get_text( ).
    ENDTRY.

    TRY.
        lo_http->close( ).
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.
