private section.

  data O_THOM_HTTP_SEND type ref to ZCL_THOM_HTTP_SEND .
  data C_WSID type ZCR_DE_WSID value '130' ##NO_TEXT.
  data S_STATUS type ZCR_TB_WS_STATUS .
  data V_OBJECT type BALOBJ_D .
  data V_SUBOBJECT type BALSUBOBJ .
  data V_EXTNUMBER type BALNREXT .
  data V_WSAREA type ZCR_DE_WSAREA .
  constants:
    BEGIN OF c_event,
      create TYPE c VALUE 'C',
      delete TYPE c VALUE 'I',
      edit   TYPE c VALUE 'U',
    END OF c_event .
  constants:
    BEGIN OF c_tipo_mensagem,
               centro   TYPE c VALUE 'C',
               deposito TYPE c VALUE 'D',
               basico   TYPE c VALUE 'B',
             END OF c_tipo_mensagem .
  data V_COMMIT type FLAG .
  data V_UPDATE_TASK type FLAG .

  methods SEND_ENMAT
    importing
      !IS_RESPONSE type TY_RESPONSE
      !I_FORCE type FLAG optional
    exporting
      value(EV_SUCESS) type ABAP_BOOL
      value(ES_MESSAGE) type BAPIRET2 .
  methods SAVE_DOCUMENT
    importing
      !IT_MESSAGES type TAB_BDCMSGCOLL optional
    changing
      !CS_THOM_ENMAT type ZTHOM_ENMAT .
