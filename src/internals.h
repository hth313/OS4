Text1:        .equ    0xf1
Text2:        .equ    0xf2

;;; Macro to switch to given bank on the fly.
switchBank:   .macro  n
              enrom\n
10$:
              .section code\n
              .shadow 10$
              .endm

DSPLN:        .equlab 0xfc7
PAR110:       .equlab 0xceb
ROW930:       .equlab 0x460
DF050         .equlab 0x584
PARS60:       .equlab 0xcb4
PRT5:         .equlab 0x6fe5
