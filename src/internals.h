#ifndef __OS4_INTERNALS_H__
#define __OS4_INTERNALS_H__

Text1:        .equ    0xf1
Text2:        .equ    0xf2

// Macro to switch to given bank on the fly.
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
PRT12:        .equlab 0X6FD7
WKUP20:       .equlab 0x1a6
WKUP60:       .equlab 0x01d5
WKUP90:       .equlab 0x020f

enableBank1   .equlab 0x4fc7
enableBank2   .equlab 0x4fc9

#endif // __OS4_INTERNALS_H__
