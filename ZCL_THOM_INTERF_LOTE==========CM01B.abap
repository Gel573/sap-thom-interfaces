  METHOD _FORMAT_VFDAT_ISO.
    DATA LV_LEN TYPE I.

    CLEAR: EV_VFDAT,
    EV_OK,
    EV_MESSAGE,
    LV_LEN.

    IF IV_VFDAT IS INITIAL.
      EV_OK = ABAP_TRUE.
      RETURN.
    ENDIF.

    LV_LEN = STRLEN( IV_VFDAT ).

    IF LV_LEN <> 8.
      EV_OK      = ABAP_FALSE.
      EV_MESSAGE = 'VFDAT inválida: formato esperado YYYYMMDD.'.
      RETURN.
    ENDIF.

    IF IV_VFDAT CN '0123456789'.
      EV_OK      = ABAP_FALSE.
      EV_MESSAGE = 'VFDAT inválida: contém caracteres não numéricos.'.
      RETURN.
    ENDIF.

    CONCATENATE IV_VFDAT+0(4)
    '-'
    IV_VFDAT+4(2)
    '-'
    IV_VFDAT+6(2)
    'T00:00:00'
    INTO EV_VFDAT.

    EV_OK = ABAP_TRUE.

  ENDMETHOD.
