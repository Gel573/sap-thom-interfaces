  METHOD CONSTRUCTOR.
    CLEAR: MV_ENV,
           MV_HTTP_DEST,
           MV_LOTES_PATH,
           MV_OAUTH_TOKEN_PATH,
           MV_HANDLE_LOG,
           MV_AUTH_USER,
           MV_AUTH_PASS,
           MV_TIMEOUT_SEC,
           MV_BALNREXT,
           MV_AUTH_PROFILE,
           MV_TOKEN,
           MV_TOKEN_EXP_TS,
           MV_LAST_CFG_SERVICE,
           MV_LAST_CFG_MESSAGE.

           ME->SET_ENV( MV_ENV ).

    TRY.
        MV_BALNREXT = ME->GENERATED_GUID( ).
        MV_HANDLE_LOG =  ME->LOG_INIT( MV_BALNREXT ).
      CATCH CX_ROOT.
    ENDTRY.

*    IF IV_WSID IS NOT INITIAL.

    IF IV_WSID IS NOT INITIAL.
      S_STATUS-WSID = IV_WSID.
    ELSE.
      S_STATUS-WSID = C_WSID.
    ENDIF.

    IF IV_WSAREA IS NOT INITIAL.
      V_WSAREA = IV_WSAREA.
    ELSE.
      V_WSAREA = ZCR_CL_INTF_GEN=>C_WS_WSAREA_MM.
    ENDIF.

    IF IV_OBJECT IS NOT INITIAL.
      V_OBJECT = IV_OBJECT.
    ELSE.
      V_OBJECT = CONV BALOBJ_D( ZCR_CL_PRE_DEFINED_VALUES=>GET_VALUE(  IV_REPID     = 'ZMM_INTF'
                                                                       IV_PARID     = 'OBJETO_LOG_INTERFACES'
                                                                       IV_TABLENAME = 'ZMM_TB_CONST' ) ).
    ENDIF.

    IF IV_SUBOBJECT IS NOT INITIAL.
      V_SUBOBJECT = IV_SUBOBJECT.
    ELSE.
      V_SUBOBJECT = CONV BALSUBOBJ( ZCR_CL_PRE_DEFINED_VALUES=>GET_VALUE( IV_REPID  = 'ZMM_INTF'
                                                                          IV_PARID     = 'SUBOBJ_LOG_INTERF_OUT'
                                                                          IV_TABLENAME = 'ZMM_TB_CONST' ) ).
    ENDIF.

    IF IV_EXTNUMBER IS NOT INITIAL.
      V_EXTNUMBER = IV_EXTNUMBER.
      S_STATUS-WS_GUID_SAP = IV_EXTNUMBER.
    ENDIF.

    O_THOM_HTTP_SEND = NEW ZCL_THOM_HTTP_SEND( I_SERVICE_ID = 'LOTES' ).
*    ENDIF.

  ENDMETHOD.
