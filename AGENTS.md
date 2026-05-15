# Project instructions for Codex

This repository contains SAP ABAP source code exported from SAP / abapGit.

## Language and platform

- Main language: SAP ABAP.
- Target system: SAP ECC / S/4HANA, depending on the object.
- Do not assume that ABAP code can be compiled or executed locally.
- Do not invent SAP Dictionary objects, tables, function modules, methods, domains, data elements, or transactions.
- If an object is not present in the repository, explicitly say that it must be checked in SAP.

## Coding style

- Prefer compatibility with older ABAP syntax when possible.
- Avoid modern syntax that may not exist in ABAP 7.1, unless explicitly requested.
- Avoid inline declarations if compatibility is uncertain.
- Avoid expressions such as VALUE #( ), NEW #( ), REDUCE, FILTER, CORRESPONDING #( ) unless the task explicitly allows modern ABAP.
- Use defensive programming with TRY/CATCH where a dump is possible.
- Avoid early RETURN in exits, BADIs, workflows, and interfaces when it can skip logging or status updates.
- Prefer flags such as LV_ABORT, LV_ERROR, or LV_SKIP when the process must continue safely.

## Naming conventions

- Custom objects usually start with Z.
- THOM interface objects often use names such as:
  - ZCL_THOM_*
  - ZTHOM_*
  - ZCR_*
  - ZMM_*
  - ZFI_*
- Preserve existing naming conventions from the repository.

## Logging

- Prefer BAL application log when appropriate.
- Typical SAP transactions for analysis:
  - SLG1 for application logs
  - ST22 for dumps
  - SM21 for system log
  - SM37 for jobs
  - WE02/WE05 for IDocs when applicable
  - /IWFND/GW_CLIENT for OData tests when applicable

## Review behavior

When reviewing ABAP code, check especially for:

- Possible dumps due to empty reads, unassigned field-symbols, invalid dynamic access, or missing checks.
- SELECT SINGLE without proper key.
- SELECT inside LOOP performance problems.
- Missing SY-SUBRC checks.
- Missing authority, customizing, or master data validation.
- Hardcoded values that should be customizing.
- Missing COMMIT/ROLLBACK considerations.
- Incorrect use of update task, background task, or RFC.
- Places where an early RETURN can prevent logs or status updates.
- Incorrect handling of dates, quantities, currencies, units, leading zeros, MATNR conversion, ALPHA/MATN1 conversions.
- Interface status inconsistencies between processing tables and status/control tables.

## Output expected from Codex

When proposing a change:

1. Explain the problem.
2. Identify the exact ABAP object/method/include affected.
3. Propose the corrected ABAP code.
4. Mention assumptions.
5. Mention what must be tested in SAP.
6. Do not claim that the code was compiled unless a real SAP syntax check was performed.

## Testing limitations

Since this environment cannot connect to SAP by default:

- Do not say "tests passed" for ABAP syntax or runtime.
- Instead say "static review completed" or "logic reviewed".
- Provide manual SAP test steps when needed.
