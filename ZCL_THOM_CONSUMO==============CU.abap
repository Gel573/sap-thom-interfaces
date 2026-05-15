class ZCL_THOM_CONSUMO definition
  public
  final
  create public .

public section.

  types:
    ty_t_mseg TYPE TABLE OF mseg .
  types:
    BEGIN OF ty_document.
        INCLUDE TYPE zthom_consumos.
    TYPES:
      saved TYPE flag,
      END OF ty_document .

  methods POST_DOCUMENT
    importing
      !I_COMMIT type FLAG default 'X'
      !I_WAIT type NUMC2 default '20'
    exporting
      !E_MBLNR type MBLNR
      !E_MJAHR type MJAHR
      !ET_MSEG type TY_T_MSEG
      !ET_MESSAGES type TAB_BDCMSGCOLL
    changing
      !CS_DOCUMENT type TY_DOCUMENT
    exceptions
      ERROR
      ERROR_DATA .
  methods CONSTRUCTOR .
  methods CANCEL_DOCUMENT
    importing
      !I_COMMIT type FLAG default 'X'
      !I_WAIT type NUMC2 default '20'
    exporting
      !E_MBLNR type MBLNR
      !E_MJAHR type MJAHR
      !ET_MSEG type TY_T_MSEG
      !ET_MESSAGES type TAB_BDCMSGCOLL
    changing
      !CS_DOCUMENT type TY_DOCUMENT
    exceptions
      ERROR
      ERROR_DATA .
  class-methods IS_PROCESS_INTERFACE
    returning
      value(R_VALID) type FLAG .
