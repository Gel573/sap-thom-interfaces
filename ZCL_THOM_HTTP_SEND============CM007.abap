  METHOD json_to_struct.

    DATA: lv_json    TYPE string.

    TRY.

        lv_json = i_json.

        /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = r_data ).

      CATCH cx_root.
        " não é JSON válido # ignorar
    ENDTRY.

  ENDMETHOD.
