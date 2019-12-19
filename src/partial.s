#include "mainframe.i"

#define IN_OS4
#include "OS4.h"


;;; **********************************************************************
;;;
;;; Support module for key sequence parsing.
;;;
;;; **********************************************************************


;;; **********************************************************************
;;;
;;; parseNumber - parse numeric input
;;; parseNumberInput - parse numeric input with first key ready
;;;
;;; Support routines to perform numeric input using the key sequence
;;; parser. These routines can be called to handle a single value
;;; input, keeping its work state in status register 9 (Q).
;;;
;;; Typical calling sequence:
;;;     gosub   parseNumber
;;;     .con    .low12 accept_1_31     ; some acceptor
;;;     .con    0x200 | 1 << ParseNumber_BaseSwitch
;;;
;;; This routine keeps a state in REGN9, but also allow the caller to
;;; share some space in it, to allow for intermediate values entered
;;; when doing multiple parseNumber calls.
;;;   REG9[1:0] contains flags controlling the mode
;;;   REG9[2] is the number of digits to request minus 1, basically
;;;           telling which NEXTx routine to use
;;;   REG9[6:3] is the acceptor call back pointer
;;;   REG9[12:7] can be used to keep some kind of state information outside
;;;              the digit handler, i.e. to store intermediate input when
;;;              using multiple calls to the key sequence parser.
;;;    REG9[13] is used to keep track of the number of digits entered so far.
;;;
;;; In: C.X= packed pointer to an input validator
;;;          to accept any value:
;;;              ldi .low12 acceptAllValues
;;;              gosub parseDec2
;;; Out: Returns to (P+1) if input was aborted.
;;;      Returns to (P+2) if final valid input with:
;;;        C.X= binary value entered
;;;      Chip 0 selected
;;;
;;; Uses: A, B, C, REG9[13,6:0], ST, +3 sub levels
;;;
;;; **********************************************************************

              .section code, reorder
              .public parseNumber, parseNumberInput
              .extern unpack, RTNP2, callInd
parseNumberInput:
              a=0     x
              a=a+1   x
              goto    parseNumber10
parseNumber:  a=0     x
parseNumber10:
              b=a                   ; B.X= input flag
                                    ; B.S= potential digit entry
              c=stk
              a=c     m
              cxisa
              gosub   unpack        ; C[6:3]= validator
              acex    m             ; A[6:3]= validator
              c=c+1   m
              cxisa                 ; read control word
              c=c+1   m
              stk=c                 ; push updated return address
              c=c-1   xs            ; use 0-based digit counter
              a=c     x             ; A.X= control word
              rcr     3             ; C.S= number of digits left - 1
              a=c     s             ; A.S= number of digits left - 1
              gosub   ENCP00
              pt=     6
              c=regn  9             ; C[12:7]= outside state
              acex    s
              acex    wpt
              regn=c  9             ; save full state in REGN9
              gosub   ENLCD
              abex    s             ; A.S= potential digit entry
              ?b#0    x             ; do we already have input ready?
              goc     200$          ; yes

20$:          gosub   dispatch
              goto    21$
              goto    22$
              gosub   NEXT3
              rtn
              goto    200$
21$:          gosub   NEXT1
              rtn                   ; cancelled
              goto 200$
22$:          gosub   NEXT2
              rtn                   ; cancelled
200$:         ?s4=1                 ; A..J ?
              gonc    23$           ; no
              gosub   dispatch      ; yes
              goto    201$
              goto    202$
              gosub   OS4_AJ3
              goto    24$

201$:         nop                   ; TBD: single digit input from A..J
              goto    24$

202$:         gosub   OS4_AJ2
              goto    24$           ; value not accepted
23$:          ?s3=1                 ; digit key?
              goc     30$           ; yes
              c=keys                ; check for EEX
              rcr     3
              c=0     xs
              a=c     x
              ldi     0x83          ; KC for EEX
              ?a#c    x
              gonc    25$           ; this is EEX
24$:          gosub   ENLCD         ; not accepted key
              gosub   BLINK
              goto    20$

;;; * Handle initial EEX
25$:          gosub   ENCP00
              c=regn  9
              cstex
              ?st=1   ParseNumber_AllowEEX ; EEX allowed ?
              gonc    24$           ; no

;;; * Handle a single digit, after we have one in place we stay
;;; * around here to accept further digits (ignore A..J, EEX etc).
30$:          ldi     3
              acex    s
              rcr     13
              slsabc
              gosub   ENCP00
              c=regn  9
              c=c-1   s
              gonc    35$           ; not complete
              gosub   ENLCD
              gosub   validateClear
              goto    37$           ; not accepted

35$:          regn=c  9
              bcex                  ; try to accept a digit for incomplete input
                                    ; B= REGN9, with decremented char count left

              gosub   ENLCD
              gosub   lcdValue
              c=b
350$:         gosub   mul10         ; assume 0 for the not yet seen digits
              c=c-1   s
              gonc    350$
              c=b     m             ; C[6:3]= validator
              gosub   callInd       ; validate value
              goto    37$           ; not accepted
              gosub   ENCP00

36$:          gosub   dispatch
              goto    31$
              goto    32$
                                    ; we do not expect to have 3 digits
                                    ;   left after at least one is entered

31$:          gosub   NEXT1
              goto    37$
              ?s3=1                 ; digit key?
              goc     30$           ; yes
              goto    39$           ; no, blink

32$:          gosub   NEXT2
              goto    37$
              ?s3=1                 ; digit key?
              goc     30$           ; yes

39$:          gosub   BLINK         ; blink and try input again
              goto    36$

37$:          rabcr                 ; backspace, remove one digit
              gosub   ENCP00
              c=regn  9
              c=c+1   s
              regn=c  9
              a=c     s
              rcr     3
              ?a#c    s             ; have we erased all digits now?
              golnc   20$           ; yes, start over
              goto    36$           ; no

;;; * A..J input handling
OS4_AJ3:      ldi     '0'
              slsabc
              goto    AJ210
OS4_AJ2:      ldi     '0'
AJ210:        ?a#0    s
              goc     AJ220
              c=c+1
AJ220:        slsabc
              rcr     1
              acex    s
              rcr     13
              slsabc

;;; * Validate complete input, remove digits in case of
;;; * unaccepted input.
validateClear:
              gosub   lcdValue
              gosub   ENCP00
              c=regn  9             ; C[6:3]= validator
              gosub   callInd
              goto    90$           ; not good
              spopnd                ; drop return to digit input
              golong  RTNP2         ; accept
90$:          gosub   ENLCD
              ?s3=1                 ; doing single digit entry?
              gonc    95$           ; no, shift off all digits
              rabcr                 ; yes, remove single digit
              rtn                   ; return to (P+1) not accepted
95$:          rabcr                 ; shift off all digits
              st=c
              ?s4=1
              goc     95$
              rtn                   ; return to (P+1) not accepted

lcdValue:     a=0                   ; A.X= sum
              a=a-1   s             ; A.S= digit counter
10$:          rabcr
              a=a+1   s
              st=c
              ?s7=1                 ; comma or colon?
              goc     19$           ; yes, stop
              ?s4=1
              goc     10$           ; shift until " " or " ."
19$:          pt=     1
              rabcl                 ; restore digit we do not want
              goto    22$
20$:          rabcl
              c=0     pt
              c=0     xs
              a=a+c   x
22$:          a=a-1   s             ; decrement # of digits
              rtnc
              gosub   mul10
              goto    20$

mul10:        acex    x             ; multiply by 10
              c=c+c   x
              a=c     x
              c=c+c   x
              c=c+c   x
              a=a+c   x
              rtn

;;; * Dispatch on number of digits to prompt for
dispatch:     gosub   ENCP00
              c=regn  9
              gosub   ENLCD
              c=stk
              c=c-1   s
              gonc    10$
              gotoc                 ; return to (P+1) for 1 digit
10$:          c=c+1   m
              c=c-1   s
              gonc    20$
              gotoc                 ; return to (P+2) for 2 digits
20$:          c=c+1   m
              gotoc                 ; return to (P+3) for 3 digits

;;; **********************************************************************
;;;
;;; XABTSEQ - abort partial key sequence
;;;
;;; This function terminates partial key sequence, typically when pressing
;;; backarrow to get out of it.
;;; Compared to the ABTSEQ routine in mainframe, this will also clear alpha
;;; mode and properly reset the Flag_SEC_PROXY in the system buffer header
;;; which should be done for secondary functions that have partial key
;;; sequence handling (it does not harm to do it for all partial key
;;; handling).
;;;
;;; **********************************************************************

              .section code, reorder
              .public XABTSEQ
              .extern sysbuf
XABTSEQ:      gosub   ENCP00
              gosub   sysbuf
              goto    10$
              c=data
              cstex
              st=0    Flag_SEC_PROXY
              cstex
              data=c
10$:          golong  NAME33
