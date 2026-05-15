  METHOD hash_response.
    DATA: lv_payload  TYPE string,
          lv_payloadx TYPE xstring,
          lv_hash_hex TYPE string,
          lv_md5      TYPE c LENGTH 32.

    lv_payload = i_payload.

    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = lv_payload
      IMPORTING
        buffer = lv_payloadx
      EXCEPTIONS
        OTHERS = 1.


    TRY.
        CALL FUNCTION 'CALCULATE_HASH_FOR_RAW'
          EXPORTING
            alg        = 'SHA1'
            data       = lv_payloadx
          IMPORTING
            hashstring = lv_hash_hex
          EXCEPTIONS
            OTHERS     = 1.
        IF sy-subrc = 0 AND lv_hash_hex IS NOT INITIAL.
          r_hash = lv_hash_hex.
          RETURN.
        ENDIF.
      CATCH cx_root.
    ENDTRY.

    TRY.
        CALL FUNCTION 'MD5_CALCULATE_HASH_FOR_RAW'
          EXPORTING
            data   = lv_payloadx
          IMPORTING
            hash   = lv_md5
          EXCEPTIONS
            OTHERS = 1.
        IF sy-subrc = 0 AND lv_md5 IS NOT INITIAL.
          r_hash = lv_md5.
          RETURN.
        ENDIF.
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.
