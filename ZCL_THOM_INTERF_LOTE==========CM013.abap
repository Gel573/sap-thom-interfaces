  METHOD BUILD_BAPIRET2.
    DATA LV_MESSAGE_TEXT TYPE BAPI_MSG.

    CLEAR RS_MSG.

    "--- Dados técnicos da mensagem
    RS_MSG-TYPE       = IV_TYPE.
    RS_MSG-ID         = IV_ID.
    RS_MSG-NUMBER     = IV_NUMBER.
    RS_MSG-MESSAGE_V1 = IV_V1.
    RS_MSG-MESSAGE_V2 = IV_V2.
    RS_MSG-MESSAGE_V3 = IV_V3.
    RS_MSG-MESSAGE_V4 = IV_V4.

    "--- Texto formatado da mensagem
    MESSAGE ID IV_ID
    TYPE IV_TYPE
    NUMBER IV_NUMBER
    WITH IV_V1 IV_V2 IV_V3 IV_V4
    INTO LV_MESSAGE_TEXT.

    RS_MSG-MESSAGE = LV_MESSAGE_TEXT.

  ENDMETHOD.
