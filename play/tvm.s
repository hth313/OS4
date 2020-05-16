#include "mainframe.h"
#include "OS4.h"

;;; ************************************************************
;;;
;;; tvmShell - the application shell definition
;;;
;;; This record describes to OS4 that we are an application
;;; with suitable key and display handlers.
;;;
;;; ************************************************************

              .section PlayTable, rodata
              .align  4
tvmShell:     .con    AppShell
              .con    0                 ; no display handler defined
              .con    .low12 keyHandler ; standard keys
              .con    .low12 keyHandler ; user keys
              .con    0                 ; alpha keys, use default
              .con    .low12 myName
              .con    0                 ; no timeout handler

              .section PlayCode
              .align  4
myName:       .messl  "TVM"


              .section PlayCode
              .public TVM
              .name   "TVM"         ; enable the TVM shell
TVM:          ldi     .low12 tvmShell
              gosub   activateShell
              goto    10$           ; (P+1) out of memory
              rtn                   ; (P+2) success
10$:          golong  noRoom

              .section PlayCode
              .public TVMEXIT
              .name   "TVMEXIT"
TVMEXIT:      ldi     .low12 tvmShell
              gosub   exitShell     ; must be a gosub to provide page address
              golong  NFRPU         ; must golong as exitShell uses +3 levels

              .section PlayCode
              .public N
              .name   "N"
N:            a=0     x             ; destination register = 1
              a=a+1   x
              gsbp    INTRO
              ?c#0                  ; I=0?
              goc     5$            ; no, general case
              c=regn  2
              a=c                   ; A= PV
              c=regn  4             ; C= FV
              gosub   AD2_10        ; PV + FV
              c=regn  3             ; C= PMT
              ?c#0                  ; PMT=0?
              golc    ERRDE         ; yes
              gosub   DV1_10        ; (PV + FV) / PMT
              goto    EXIT22

5$:           c=regn  1
              a=c                   ; A= I
              c=regn  2             ; C= PV
              gosub   MP2_10        ; PV * I
              gosub   STSCR
              clrabc
              ?s9=1
              gsubc   ADDONE        ; load 13-digit 1
              c=regn  1             ; C= i = I/100
              gosub   MP1_10        ; ip
              gosub   ADDONE        ; 1 + ip
              c=regn  3             ; C= PMT
              gosub   MP1_10        ; PMT * (1 + ip)
              n=c
              gosub   RCSCR         ; PV * I
              gosub   AD2_13        ; PMT * (1 + ip) + PV * I
              ?c#0
              golnc  ERRDE
skip:         gosub   STSCR
              c=regn  2
              a=c                   ; A= PV
              c=regn  4             ; C= FV
              gosub   AD2_10        ; PV + FV
              c=regn  1             ; I/100
              c=-c-1  s             ; change sign
              nop
              gosub   MP1_10        ; -I * (PV + FV)
              regn=c  0             ; save for later
              gosub   RCSCR         ; PMT * (1 + ip) + PV * I
              gosub   DV2_13
              ?c#0    s             ; negative?
              goc     BRANCH2       ; yes
BRANCH1:      s9=     0
MERGE:        s5=     0             ; natural LN
              gosub   XLN1_PLUS_X
              gosub   STSCR         ; Ln (1 + (PMT * (1 + ip) + PV * I))
              c=regn  1             ; C= I
              s5=     0             ; natural LN
              gosub   XLN1_PLUS_X   ; LN (1 + I)
              gosub   RCSCR
              gosub   X_BY_Y13
              ?s9=1                 ; branch 2?
EXIT22:       gonc    EXIT2         ; no (instruction also used as relay)
              c=-c-1  s             ; yes, change sign
EXIT2:        regn=c  3
              a=0
              a=a+1   x             ; A= destination register = 1
              golp    EXIT1

BRANCH2:      c=regn  4
              a=c                   ; A= FV
              c=regn  1             ; C= I
              gosub   MP2_10        ; FV * I
              c=-c-1  s             ; change sign
              a=c     s             ; ditto in 13-digit form
              c=n                   ; PMT * (1 + ip)
              gosub   AD1_10        ; PMT * (1 + ip) - FV * I
              gosub   ONE_BY_X13
              c=0     x
              dadd=c
              c=data                ; -I * (PV + FV)
              c=-c-1  s             ; change sign
              nop
              gosub   MP1_10
              ?c#0    s             ; negative?
              golc    ERRDE         ; yes
              s9=     1
              gonc    MERGE


INTRO:        ?s13=1                ; running?
              goc     INTRO2        ; yes, skip all
              c=regn  14            ; check user flag 22, data entry
              rcr     8
              cstex
              ?s1=1
              gonc    INTRO2        ; not set
              spopnd                ; cancel and return

EXIT1:        ?s13=1                ; running?
              goc     10$           ; yes
              gsbp    SHOW          ; no, show it
10$:          c=regn  3
              bcex
              c=regn  13
              rcr     3             ; C.X= data register base
              c=a+c   x             ; C.X= address of desired register
              dadd=c
              c=b
              data=c                ; write to register
              c=0     x             ; select chip 0
              dadd=c
              c=regn  14            ; clear user flag 22
              rcr     8
              cstex
              s1=     0
              cstex
              rcr     6
              regn=c  14
              rtn

;;; Copy R01 - R05 to TZYXL
INTRO2:       cstex
              s9=     0             ; S9 = user flag 00
              c=regn  14
              c=c+c   s
              gonc    10$
              s9=     1
10$:          c=regn  13
              rcr     3             ; C.X= data register base
              pt=     5             ; counter
              b=0     x             ; B.X= address of register T
20$:          c=c+1   x
              a=c     x
              dadd=c
              c=data
              bcex    x
              dadd=c
              c=c+1   x
              bcex    x
              data=c
              acex    x
              dec     pt
              ?pt=    0
              gonc    20$
              setdec
              c=regn  1             ; C= stack Z register
              ?c#0                  ; is it zero?
              rtnnc                 ; yes, then return zero
              c=c-1   x             ; divide by 100
              c=c-1   x
              regn=c  1
              rtn

SHOW:         rtn                   ; TBD

              .public I
              .name   "I"
I:            rtn

              .public PV
              .name   "PV"
PV:           rtn

              .public PMT
              .name   "PMT"
PMT:          rtn

              .public FV
              .name "FV"
FV:           rtn


;;; **********************************************************************
;;;
;;; The keyboard description. We provide handlers for digit entry and ending
;;; digit entry and point to the keyboard table to use.
;;; Do not support auto assigned top keys, it slows things down too much and
;;; we rely on it for hexadecimal digit entry which should be fast.
;;;
;;; **********************************************************************

              .section PlayCode
              .extern keyTableTVM
              .align  4
keyHandler:   gosub   keyKeyboard   ; does not return
              .con    (1 << KeyFlagSparseTable) ; flags
              .con    0             ; handle a digit
              .con    0             ; end digit entry
              .con    .low12 keyTableTVM
                                    ; no transient termination entry needed
                                    ; we do not have keyboard secondaries
