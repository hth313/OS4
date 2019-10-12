;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

#include "mainframe.i"

#define IN_RATATOSK
#include "ratatosk.h"

DSPLN:        .equlab 0xFC7
PAR110:       .equlab 0xCEB
ROW930:       .equlab 0x460

Text1:        .equ    0xf1

;;; **********************************************************************
;;;
;;; doPRGM - handle semi-merged instructions in program mode
;;;
;;; Deal with semi-merged instructions in program mode, handling
;;; completions of postfix entry and show semi-merged instructions
;;; with their arguments as appropriate.
;;; Returns by jumping back to LocalMEMCHK to do final processing
;;; before going to sleep.
;;;
;;; **********************************************************************

              .section code
              .public doPRGM
              .extern sysbuf, LocalMEMCHK, noSysBuf, jumpP2
doPRGM:       ?s12=1                ; PRIVATE ?
              goc     900$          ; yes
              gosub   sysbuf
              goto    900$          ; (P+1) no system buffer
              c=data                ; (P+2) read buffer header
              st=c
              st=0    Flag_Pause    ; always reset pause flag when entering
                                    ;  program mode
              st=0    Flag_Argument ; reset argument flag
              cstex                 ; keep old argument flag in ST
              data=c                ; write back

              rcr     2
              m=c                   ; M[1:0] - default postfix byte

              c=0     x             ; select chip 0
              dadd=c
              c=regn  15            ; Do not look for argument
              c=c-1   x             ; if LINNUM=0
              gonc    4$
              goto    900$

8$:           gosub   GETPC         ; abort entry of semi-merged instruction
              gosub   DELLIN        ;  remove the XROM instruction as well
              gosub   PUTPC
              gosub   BSTEP
              gosub   DFRST8
900$:         golong  LocalMEMCHK

4$:           ?s10=1                ; ROM?
              goc     10$           ; yes, no need to change it

              ?st=1   Flag_Argument ; check if inserting prompt
              gonc    10$           ; no

;;; Now change byte from $99 to $f1!!
              gosub   NXBYTP
              b=a
              a=c     x
              ldi     0x99
              ?a#c    x             ; MCODE prompt?
              goc     8$            ; no - it was aborted
              ldi     Text1
              abex                  ; get addr again
              gosub   PTBYTA        ; store text1

              gosub   INCADA        ; step forward to postfix byte
              gosub   GTBYTA
              acex
              cmex
              pt=     1
              ?a#c    wpt           ; same as default?
              goc     5$            ; no
              cmex                  ; yes, restore address to postfix byte
              a=c
              c=0     x             ; null
              gosub   PTBYTA        ; erase it
              gosub   DECADA        ; address of text 1
              c=0     x
              gosub   PTBYTA        ; clear it too
              gosub   PUTPC         ; go to previous line
              gosub   BSTEP
5$:           gosub   DFRST8        ; bring text1 line up

;;; ***********************************************
;;; See if current line is an MCODE prompt function
;;; ***********************************************

10$:          gosub   NXBYTP
              b=a     wpt           ; B[3:0]= address
              a=c     x             ; A.X= opcode
              ldi     0xa0          ; test if is an XROM
              ?a<c    x
              goc     900$          ; not XROM
              ldi     0xa8
              ?a<c    x
9000$:        gonc    900$          ; not XROM
              abex
              gosub   INCAD
              gosub   GTBYT         ; read next byte
              acex                  ; A[1:0]= byte
                                    ; C[3:0]= address
              m=c                   ; M[3:0]= address
              acex                  ; C[1:0]= byte
              abex                  ; A[0]= low nibble of XROM opcode
              asl     x             ; A[2] = low nibble of XROM opcode
              asl     x
              acex    xs            ; C[2:0]= lower 1 & half bytes of XROM function code
              gosub   GTRMAD
90000$:       goto    9000$         ; could not find it
              ?s3=1
              goc     9000$         ; user code
              acex
              rcr     11
              cxisa
              ?c#0    x             ; check if 2 nops
              goc     200$          ; no, it can still be a special form XROM
              c=c+1   m
              cxisa
              ?c#0    x
              goc     200$          ; no XROM XKD
              c=c+1   m             ; inspect next word which should be
                                    ;  gosub Argument for a semi-merged
              ldi     FirstGosub(argumentEntry)
              a=c     x
              cxisa
              ?a#c    x
              goc     200$          ; not normal semi-merged
              c=c+1   m
              ldi     SecondGosub(argumentEntry)
              a=c     x
              cxisa
              ?a#c    x
              goc     9000$         ; not any semi-merged

;;; **********************************************************************
;;;
;;; We have found an MCODE function with postfix argument.
;;; Now display it properly with its postfix argument.
;;;
;;; **********************************************************************

              c=c+1   m             ; step to default argument
              cxisa                 ; get default argument
              n=c                   ; save it in case we need it
              gosub   DFRST8        ; display normal line
              gosub   ENLCD
              gosub   RightJustify
              acex                  ; add a blank
              slsabc
              gosub   ENCP00
              gosub   NXBYTP
              gosub   INCAD
              gosub   NXBYT         ; get next byte
              b=a
              a=c     x
              ldi     Text1
              ?a#c    x             ; is it a text 1?
              gonc    35$           ; yes
              c=n                   ; no, use default argument instead
              goto    36$
35$:          abex
              gosub   INCAD
              gosub   GTBYT         ; get argument
36$:          s0=0                  ; ensure 2-digit operand
              gosub   ROW930        ; display argument
900000$:      goto    90000$

;;; **********************************************************************
;;;
;;; XKD XROM, but not an ordinary postfix semi-merged.
;;; Probe the XROM to see if it is some other special form.
;;;
;;; **********************************************************************

200$:         a=c     x             ; A.X= first ROM word
              ldi     FirstGosub(xargumentEntry)
              ?a#c    x
              goc     900000$       ; not xargument
              ldi     SecondGosub(xargumentEntry)
              a=c     x
              c=c+1   m
              cxisa
              ?a#c    x
              gsubnc  jumpP2        ; do display handler
              goto    900000$

;;; **********************************************************************
;;;
;;; Increment and get next byte from program memory.
;;;
;;; **********************************************************************

              .public NXBYTP, NXBYT
NXBYTP:       gosub   GETPC
NXBYT:        gosub   INCAD
              gosub   GTBYT
              c=0     xs
              ?c#0    x
              rtnc
              goto    NXBYT         ; skip null

;;; **********************************************************************
;;;
;;; Right justify display
;;;
;;; Leaves rightmost char in C[2:0] and 32 in A[2:0] (blank)
;;; Assume: LCD enabled
;;; Uses: A[2:0], C[2:0], PT=1
;;;
;;; **********************************************************************

RightJustify:
              ldi     ' '
              pt=     1
              a=c     x
1$:           frsabc
              ?a#c    wpt
              gonc    1$
              flsabc
              rtn

;;; ----------------------------------------------------------------------
;;;
;;; argument - handle numerical arguments for functions in XROMs
;;;
;;; Start MCODE function as follows:
;;; XADR  nop
;;;       nop
;;;       gosub   argument
;;;       .con    DefaultOperand + modifiers
;;;
;;; IN: SS0 UP, CHIP0 selected
;;; OUT:  ST - numeric argument
;;;       A[2:0] - numeric argument
;;;       B.M - numeric argument
;;;       G - numeric argument
;;;
;;; It is assumed here that processing of numbers to registers take
;;; place later.
;;;
;;; Possible modifiers are:
;;; 0x100 (sets S1), allow IND, but disallow ST
;;;       (bit 9 of second char in a prompting name label)
;;; 0x200 (sets S2), disallow IND and ST
;;;       (bit 8 of first char in a prompting name label)
;;;
;;; ----------------------------------------------------------------------

              .section code
              .public argument
noSysBuf0:    spopnd
              golong  noSysBuf

argument:     gosub   sysbuf        ; ensure we have the system buffer
              goto    noSysBuf0     ; (P+1) no buf
              data=c                ; read buffer header
              st=c                  ; ST= system buffer flags
              acex    x
              pt=     0
              cnex                  ; N.X= system buffer header address
              g=c                   ; G= potential entered postfix argument
              ?s13=1                ; running?
              goc     3$            ; yes
              c=0     x
              dadd=c
              c=regn  14
              cstex
              ?s4=1                 ; single step?
              gonc    91$           ; no
              cstex                 ; ST= system buffer flags

;;; We are executing the instruction from program memory
3$:           gosub   NXBYTP        ; examine argument byte
              b=a                   ; save address
              a=c     x             ; save operand byte
              st=0    Flag_Argument ; argument not known yet

;;; Entry point for executing from keyboard, in which case Flag_Argument
;;; must be set and the argument is in A[1:0]
50$:          c=stk
              cxisa                 ; get default argument
              m=c                   ; save for possible use
              c=c+1   m             ; update return address (skip over default argument)
              stk=c
              ?st=1   Flag_Argument   ; argument already known (before coming here)?
              gonc    2$            ; no
              c=g                   ; yes, move argument to C[1:0]
              goto    8$

91$:          goto    9$            ; relay

2$:           ldi     Text1
              ?a#c    x             ; argument?
              gonc    7$            ; yes
              c=m                   ; no, use default argument instead
              goto    8$
7$:           abex    wpt           ; argument follows in program
              gosub   INCAD
              gosub   PUTPC         ; store new pc (skip over Text1 instruction)
              c=regn  14
              st=c
              ?s4=1                 ; single step?
              gonc    71$           ; no
              c=regn  15            ; yes, bump line number
              c=c+1   x
              regn=c  15
71$:          gosub   GTBYT         ; get argument
8$:           pt=     0
              g=c                   ; put in G
              a=c                   ; and A
              rcr     -3            ; and finally to
              bcex    m             ; B.M
              c=0
              dadd=c                ; select chip 0
              rtn

51$:          goto    50$           ; relay

;;; ----------------------------------------------------------------------
;;;
;;; User executes the instruction from the keyboard
;;;
;;; ----------------------------------------------------------------------

9$:

;;; Load Flag_Argument flag to ST register. If it is set, then we are coming
;;; here the second time knowing the argument byte.
;;; In that case we also want to reset it as we are done with argument handing.
;;; On the other hand, if it is cleared, we set it to signal that we are looking
;;; for the argument.
;;; All boils down to that we want the current value of the Flag_Argument flag,
;;; and want to store it back toggled.
              c=n
              dadd=c
              c=data                ; read buffer header
              st=c
              ?st=1   Flag_Argument ; toggle Flag_Argument flag
              goc     12$
              st=1    Flag_Argument
              goto    13$
12$:          st=0    Flag_Argument
13$:          cstex
              data=c                ; save back toggled flag
              ?st=1   Flag_Argument ; (inspecting previous value of flag)
              goc     51$           ; with Flag_Argument set indicating found
              a=c
              c=stk
              cxisa                 ; C[1:0] = default argument
              n=c                   ; N[2:0]= modifier bits and default argument
              c=c+1   m             ; bump return address
              stk=c
              pt=     0
              g=c
              acex                  ; get header again
              pt=     2
              c=g                   ; put default arg into 'pf' field
              data=c                ; write back

              gosub   LDSST0        ; argument not obtained yet
              ?s3=1                 ; program mode?
              gonc    30$           ; no
              gosub   INSSUB        ; prepare for insert
              a=0     s             ; clear count of successful inserts
              c=regn  10            ; insert instruction in program memory
              rcr     3
              gosub   INBYTC
              c=regn  10
              rcr     1
              gosub   INBYTC
              gosub   LDSST0

;;; ************************************************************************
;;;
;;; If we are in program mode, fool the calculator that we are executing
;;; <sigma>REG function. The flag Flag_Argument has already been set above
;;; to signal to the I/O interrupt to change the 0x99 byte to 0xf1 (text 1).
;;; If not program mode, set up for prompting the current MCODE instruction
;;; and re-execute it with argument bit set to indicate that argument
;;; has been found.
;;;
;;; In other words, from the keyboard we will execute 'argument' twice, but
;;; in program mode we insert the instruction immediately and make it appear
;;; as we are executing <sigma>REG instead. Once that has been properly
;;; inserted into the program, we alter it to be the postfix argument.
;;;
;;; **********************************************************************

30$:          c=regn  10
              m=c
              ?s3=1                 ; program mode?
              gonc    40$           ; no
              pt=     4             ; yes sigma<reg> byte
              lc      9
              lc      9
              regn=c  10
              clrst
              s4=1                  ; insert bit
              goto    45$
40$:          clrst                 ; run mode
              s5=1
45$:          s0=1                  ; normal prompt
              c=n                   ; get modifier bits from default prompt
              c=c+c   xs
              c=c+c   xs
              c=c+c   xs
              gonc    46$
              s2=1
46$:          c=c+c   xs
              gonc    47$
              s1=1
47$:          pt=     0
              c=st
              g=c                   ; save PTEMP2
              gosub   OFSHFT
              c=regn  15            ; display line number
              bcex    x
              gosub   CLLCDE
              ?s4=1
              gonc    49$
              abex    x
              gosub   DSPLN+8       ; display line number
49$:          c=m
              rcr     1
              gosub   GTRMAD
              nop
              acex
              rcr     11
              gosub   PROMF2        ; prompt string

              pt=     0             ; restore PTEMP2
              c=g
              st=c
              ?s4=1                 ; program mode?
              golc    PAR110        ; yes, use ordinary prompt handler as we
                                    ;  are really entering a SIGMA-REG
                                    ;  instruction.

              ?s2=1                 ; prompt that does not allow IND/ST?
              golc    PAR110        ; yes, we can use the ordinary prompt
                                    ;  handler

;;; We may need to input stack registers. The mainframe code cannot handle
;;; this for XROM instructions, it will overwrite the second byte with the
;;; postfix byte, ruining the XROM instruction.
;;; To make it work, we need to provide out own prompt handler that can do
;;; it properly for 2-byte XROM instructions. We will in the end use the
;;; alternative way of giving the argument in B.X so everything comes
;;; together just fine.

              gosub   NEXT2         ; prompt using 2 digits
              goto    ABTSEQ_J1
              ?s6=1                 ; shift?
              goc     parseIndirect ; yes
              ?s1=1
              goc     10$
              ?s7=1                 ; DP?
              goc     parseStack    ; yes
10$:          golong  PAR111 + 1

ABTSEQ_J1:    golong  ABTSEQ

parseIndirect:
              gosub   ENCP00
              pt=     0
              c=g
              cstex
              s6=1
              cstex
              g=c
              gosub   ENLCD
              gosub   MESSL
              .messl  "IND "
20$:          gosub   NEXT2
              goto    ABTSEQ_J1
              ?s4=1                 ; A..J?
              golc    AJ2           ; yes
              ?s7=1                 ; DP?
              goc     parseStack    ; yes
              ?s3=1                 ; digit?
              gonc    30$
              gosub   FDIGIT
30$:          gosub   BLINK
              goto    20$

parseStack:   gosub   MESSL
              .messl  "ST "
              gosub   NEXT1
              goto    ABTSEQ_J1
              ldi     ' '
              srsabc
              srsabc
              srsabc
              gosub   GTACOD        ; get alpha code
              pt=     13
              lc      4             ; set for LASTX
              a=c                   ; A.S= reg index, A.X=char
              ldi     76
              ?a#c    x
              goc     20$
05$:          gosub   MASK
              gosub   LEFTJ
              gosub   ENCP00
              pt=     0             ; get PTEMP2
              c=g
              st=c
;;; Compared to the mainframe version, we do not overwrite the postfix
;;; byte of the instruction here, as it is part of the 2 byte XROM
;;; opcode.
              c=regn  10
              acex                  ; A[4:1]= current instruction
              lc      7
              ?s6=1                 ; indirect?
              gonc    10$           ; no
              pt=     0
              lc      15            ; yes
10$:          rcr     -1
              bcex    x             ; B.X=  postfix code
              golong  NLT020

15$:          gosub   BLINK
              goto    parseStack

20$:          ldi     'W'
30$:          a=a-1   s
              ?a#0    s
              gonc    40$
              c=c+1   x
              ?a#c    x
              goc     30$
              goto    05$
40$:          ldi     'T'
              ?a#c    x
              gonc    05$
              goto    15$
