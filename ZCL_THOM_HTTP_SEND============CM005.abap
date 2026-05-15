  METHOD response_to_json.
    CLEAR: e_hash.

    CALL METHOD /ui2/cl_json=>serialize
      EXPORTING
        data        = i_response
        pretty_name = i_pretty_name
      RECEIVING
        r_json      = r_json.

    e_hash = hash_response( r_json ).
  ENDMETHOD.
