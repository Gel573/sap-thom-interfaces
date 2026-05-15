METHOD _DETERMINE_SUCCESS_EVENT_TYPE.
*---------------------------------------------------------------------*
* Projeto   : THOM
* Objetivo  : Determinar o EVENT_TYPE final após envio com sucesso
*
* Regra:
*   - Se já existir registo anterior com:
*       EVENT_TYPE = 'BATCH_NEW'
*       STATUS     = 'SENT'
*       mesma chave MATNR+CHARG+WERKS+LGORT
*       e GUID diferente do atual
*     então o registo atual passa a 'BATCH_UPSE'
*
*   - Caso contrário, permanece 'BATCH_NEW'
*---------------------------------------------------------------------*

  DATA: LS_CURR TYPE ZTHOM_INTERF_LOT.

  CLEAR RV_EVENT_TYPE.

  SELECT SINGLE *
  INTO @LS_CURR
  FROM ZTHOM_INTERF_LOT
  WHERE WS_GUID_SAP = @IV_WS_GUID_SAP.

  IF SY-SUBRC <> 0.
    RV_EVENT_TYPE = 'BATCH_NEW'.
    RETURN.
  ENDIF.

  "Blindagem: se o registo atual já não for BATCH_NEW,
  "mantém o event type existente
  IF LS_CURR-EVENT_TYPE <> 'BATCH_NEW'.
    RV_EVENT_TYPE = LS_CURR-EVENT_TYPE.
    RETURN.
  ENDIF.

  SELECT SINGLE WS_GUID_SAP
  INTO @DATA(LV_GUID_PREV)
        FROM ZTHOM_INTERF_LOT
        WHERE MATNR       = @LS_CURR-MATNR
        AND CHARG       = @LS_CURR-CHARG
        AND WERKS       = @LS_CURR-WERKS
        AND LGORT       = @LS_CURR-LGORT
        AND EVENT_TYPE  = 'BATCH_NEW'
        AND STATUS      = 'SENT'
        AND WS_GUID_SAP <> @IV_WS_GUID_SAP.

  IF SY-SUBRC = 0.
    RV_EVENT_TYPE = 'BATCH_UPSE'.
  ELSE.
    RV_EVENT_TYPE = 'BATCH_NEW'.
  ENDIF.

ENDMETHOD.
