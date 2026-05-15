  METHOD _SET_SUCCESS.
    EV_OK      = ABAP_TRUE.
    EV_MESSAGE = IV_MESSAGE.

    ES_RETURN = ME->BUILD_BAPIRET2(
    IV_TYPE   = 'S'
    IV_ID     = 'ZTHOM'
    IV_NUMBER = '010'
    IV_V1     = IV_MSGV1 ).

  ENDMETHOD.
