private section.

  data V_ENV type ZE_ENV .
  data V_HTTP_DEST type RFCDEST .
  data V_URL type ZTHOM_ENDPOINTS-URL .
  data V_PATH type STRING .
  data V_TIMEOUT_SEC type I .
  data V_AUTH_USER type ZTHOM_ENDPOINTS-AUTH_USER .
  data V_AUTH_PASS type ZTHOM_ENDPOINTS-AUTH_PASS .
  data V_LAST_CFG_SERVICE type ZTHOM_ENDPOINTS-SERVICE_ID .
  data V_LAST_CFG_MESSAGE type STRING .
  data V_SERVICE_ID type ZE_SERVICE_ID .
  data V_BEARER type STRING .

  methods LOAD_PARAMS_STRICT .
  methods GET_ENDPOINT
    importing
      !I_SERVICE_ID type ZE_SERVICE_ID optional
    exporting
      !ES_EP type ZTHOM_ENDPOINTS .
