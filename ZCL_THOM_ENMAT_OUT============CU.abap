class ZCL_THOM_ENMAT_OUT definition
  public
  final
  create public .

public section.

  interfaces ZCR_IF_INTF .

  aliases CALL_ADD_STEP
    for ZCR_IF_INTF~CALL_ADD_STEP .
  aliases CALL_INSERT_INTO_DB_REPROC
    for ZCR_IF_INTF~CALL_INSERT_INTO_DB_REPROC .
  aliases EXECUTE_INTERFACE_OPERATION
    for ZCR_IF_INTF~EXECUTE_INTERFACE_OPERATION .

  types:
    tt_zz_ean13 TYPE STANDARD TABLE OF ze_ean13 WITH DEFAULT KEY .
  types:
    tt_zz_ean11 TYPE STANDARD TABLE OF ze_ean11 WITH DEFAULT KEY .
  types:
    tt_urznr   TYPE STANDARD TABLE OF urznr WITH DEFAULT KEY .
  types:
    BEGIN OF ty_response,
        event_type     TYPE char1,
        tipo_mensagem  TYPE char1,
        matnr          TYPE matnr,
        zlong_text     TYPE zlong_text_e,
        zdesc_mat      TYPE zlong_text_e,
        maktx          TYPE maktx,
        meins          TYPE meins,
        zz_cons_doente TYPE flag,
        zinfarmed      TYPE zinfarmed,
        lvorm          TYPE lvorm,
        xchpf          TYPE xchpf,
        urznr          TYPE urznr,
        urznrx         TYPE tt_urznr,
        zzean_11       TYPE tt_zz_ean11,
        zzean_13       TYPE tt_zz_ean13,
        matkl          TYPE matkl,
        werks          TYPE werks_d,
        lgort          TYPE lgort_d,
      END OF ty_response .
  types:
    tyt_short_desc TYPE TABLE OF short_desc .
  types:
    ty_t_zthom_enmat TYPE STANDARD TABLE OF zthom_enmat WITH NON-UNIQUE DEFAULT KEY .

  methods CONSTRUCTOR
    importing
      value(IV_WSID) type ZCR_DE_WSID optional
      value(IV_WSAREA) type ZCR_DE_WSAREA optional
      value(IV_OBJECT) type BALOBJ_D optional
      value(IV_SUBOBJECT) type BALSUBOBJ optional
      value(IV_EXTNUMBER) type BALNREXT optional
      value(IV_COMMIT) type FLAG default 'X' .
  methods CHECK_MAT_CHANGES
    importing
      !IS_RESPONSE type TY_RESPONSE optional
      !I_HASH type ZDE_THOM_PAYHASH optional
      !I_FORCE type FLAG optional
    preferred parameter IS_RESPONSE
    returning
      value(R_STATUS) type CHAR1 .
  methods PROCESS
    importing
      !I_WERKS type WERKS_D optional
      !I_LGORT type LGORT_D optional
      !I_MATNR type MATNR optional
      !IS_MARA type MARA optional
      !IS_MARC type MARC optional
      !IS_MARD type MARD optional
      !I_GET_ALL type FLAG optional
      !I_EVENT_TYPE type ZTHOM_EVENT_TYPE optional
      !I_REPROCESS type FLAG optional
      !I_FORCE type FLAG optional .
  class-methods SET_PROCESS_AS_INTERFACE .
  class-methods IS_PROCESS_INTERFACE
    returning
      value(R_VALID) type FLAG .
