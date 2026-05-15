METHOD NORMALIZE_AMOUNT_FOR_JSON.

  DATA: LV_WORK      TYPE STRING,
        LV_LEN       TYPE I,
        LV_IDX       TYPE I,
        LV_COUNT_DOT TYPE I,
        LV_LAST_DOT  TYPE I,
        LV_START     TYPE I,
        LV_LEFT      TYPE STRING,
        LV_RIGHT     TYPE STRING.

  CLEAR: RV_VALUE,
  LV_WORK,
  LV_LEN,
  LV_IDX,
  LV_COUNT_DOT,
  LV_LAST_DOT,
  LV_START,
  LV_LEFT,
  LV_RIGHT.

  RV_VALUE = IV_VALUE.
  CONDENSE RV_VALUE NO-GAPS.

  IF RV_VALUE IS INITIAL.
    RV_VALUE = '0.000'.
    RETURN.
  ENDIF.

  "--------------------------------------------------------------
  " Caso 1: formato local com vírgula decimal
  " Ex.: 1.200,000 -> 1200.000
  "      999,5     -> 999.5
  "--------------------------------------------------------------
  IF RV_VALUE CS ','.
    REPLACE ALL OCCURRENCES OF '.' IN RV_VALUE WITH ''.
    REPLACE ALL OCCURRENCES OF ',' IN RV_VALUE WITH '.'.
    RETURN.
  ENDIF.

  "--------------------------------------------------------------
  " Caso 2: só pontos
  " Se houver mais de um ponto, manter apenas o último
  " Ex.: 1.200.000 -> 1200.000
  "--------------------------------------------------------------
  LV_WORK = RV_VALUE.
  LV_LEN  = STRLEN( LV_WORK ).

  CLEAR: LV_COUNT_DOT, LV_LAST_DOT.

  DO LV_LEN TIMES.
    LV_IDX = SY-INDEX - 1.
    IF LV_WORK+LV_IDX(1) = '.'.
      LV_COUNT_DOT = LV_COUNT_DOT + 1.
      LV_LAST_DOT  = LV_IDX.
    ENDIF.
  ENDDO.

  IF LV_COUNT_DOT > 1.

    LV_LEFT = LV_WORK(LV_LAST_DOT).

    LV_START = LV_LAST_DOT + 1.
    LV_RIGHT = LV_WORK+LV_START.

    REPLACE ALL OCCURRENCES OF '.' IN LV_LEFT WITH ''.

    CONCATENATE LV_LEFT '.' LV_RIGHT INTO RV_VALUE.

  ENDIF.

  IF RV_VALUE IS INITIAL.
    RV_VALUE = '0.000'.
  ENDIF.

ENDMETHOD.
