;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

#include "mainframe.i"

#define IN_OS4
#include "OS4.h"

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

              .section code, reorder
              .public doPRGM
              .extern sysbuf, LocalMEMCHK, noSysBuf, jumpP2
              .extern inProgramSecondary, resetBank, secondaryProgram
doPRGM:       ?s12=1                ; PRIVATE ?
              goc     900$          ; yes
              gosub   sysbuf
              goto    900$          ; (P+1) no system buffer
              c=data                ; (P+2) read buffer header
              st=c
              st=0    Flag_Pause    ; always reset pause flag when entering
                                    ;  program mode
              st=0    Flag_Argument ; reset argument flag
              st=0    Flag_SEC_Argument
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
              goc     100$          ; yes, no need to change it

              ?st=1   Flag_Argument ; check if inserting prompt
100$          golnc   10$           ; no

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
              n=c                   ; N[1:0]= postfix byte
              acex
              cmex
              pt=     1
              ?a#c    wpt           ; same as default?
              goc     6$            ; no
              cmex                  ; yes, restore address to postfix byte
              a=c
              c=0     x             ; null
              gosub   PTBYTA        ; erase it
              gosub   DECADA        ; address of text 1
              c=0     x
              gosub   PTBYTA        ; clear it too
              gosub   PUTPC         ; go to previous line
              gosub   BSTEP
              goto    5$

6$:           ?st=1   Flag_SEC_Argument ; are we dealing with a secondary?
              gonc    5$            ; no
              gosub   GETPC
              gosub   NXBYTA        ; read Text1 (postfix operand)
              b=a
              a=c     x
              ldi     Text1
              pt=     1
              ?a#c    wpt
              goc     5$            ; hmm, not Text1
              c=0     x             ; clear it
              abex
              gosub   PTBYTA
              gosub   INCADA
              c=0     x
              gosub   PTBYTA
              gosub   PUTPC
              gosub   BSTEP         ; step back to Text1 for secondary
              gosub   GETPC
              gosub   NXBYTA        ; read Text1 (secondary suffix)
              abex
              a=c     x
              ldi     Text1
              pt=     1
              ?a#c    wpt
              goc     5$            ; hmm, not Text1
              c=c+1   x             ; now it is Text2 !
              abex
              gosub   PTBYTA
              gosub   INCADA
              gosub   INCADA
              c=n
              gosub   PTBYTA        ; write postfix byte

5$:           gosub   DFRST8        ; bring instruction line up

;;; ***********************************************
;;; See if current line is an MCODE prompt function
;;; ***********************************************

10$:          gosub   NXBYTP
              b=a     wpt           ; B[3:0]= address
              a=c     x             ; A.X= opcode
              ldi     0xa0          ; test if is an XROM
              ?a<c    x
              goc     9000$         ; not XROM
              ldi     0xa8
              ?a<c    x
9000$:        golnc   900$          ; not XROM
              abex
              gosub   INCAD
              gosub   GTBYT         ; read next byte
              acex                  ; A[1:0]= byte
                                    ; C[3:0]= address
              m=c                   ; M[3:0]= address
              acex                  ; C[1:0]= byte
              abex                  ; A[0]= low nibble of XROM opcode
              asl     x             ; A[2]= low nibble of XROM opcode
              asl     x
              acex    xs            ; C[2:0]= lower 1 & half bytes of XROM function code
              gosub   GTRMAD
90000$:       goto    9000$         ; could not find it
              ?s3=1
              goc     9000$         ; user code
              acex
              rcr     11
              s2=0                  ; not a secondary
              gosub   isArgument
              goto    200$

;;; **********************************************************************
;;;
;;; We have found an MCODE function with postfix argument.
;;; Now display it properly with its postfix argument.
;;;
;;; **********************************************************************

400$:         c=c+1   m             ; step to default argument
              cxisa                 ; get default argument
              n=c                   ; save it in case we need it
              ?s2=1                 ; secondary?
              gsubnc  DFRST8        ; no, display normal line
              gosub   ENLCD
              gosub   RightJustify
              acex                  ; add a blank
              slsabc
              gosub   ENCP00
              ?s2=1                 ; secondary?
              gonc    410$          ; no
              ?s0=1                 ; do we have a text 2?
              gonc    420$          ; no, default argument
              c=m                   ; C[3:0]= get address of text2 line (plus 1)
              rcr     4
              a=c
              gosub   INCAD         ; step to postfix argument
              gosub   INCAD
              goto    430$

410$:         gosub   NXBYTP
              gosub   INCAD
              gosub   NXBYT         ; get next byte
              b=a
              a=c     x
              ldi     Text1
              ?a#c    x             ; is it a text 1?
              gonc    35$           ; yes
420$:         c=n                   ; no, use default argument instead
              goto    36$
35$:          abex
              gosub   INCAD
430$:         gosub   GTBYT         ; get argument
36$:          s0=0                  ; ensure 2-digit operand
              gosub   ROW930        ; display argument
              golong  320$          ; @@

900000$:      goto    90000$

;;; **********************************************************************
;;;
;;; Probe the XROM to see if it is some other special form.
;;;
;;; **********************************************************************

200$:         a=c     x             ; A.X= first ROM word
              ldi     FirstGosub(xargumentEntry)
              ?a#c    x
              goc     300$          ; not xargument
              ldi     SecondGosub(xargumentEntry)
              a=c     x
              c=c+1   m
              cxisa
              ?a#c    x
              gsubnc  jumpP2        ; do display handler
9000000$:     goto    900000$

;;; Check for secondary function.
300$:         ldi     FirstGosub(runSecondaryEntry)
              ?a#c    x
              goc     900000$       ; not runSecondary
              ldi     SecondGosub(runSecondaryEntry)
              a=c     x
              c=c+1   m
              cxisa
              ?a#c    x
              goc     900000$       ; not runSecondary
              rcr     -6            ; C[12:9]= ROM pointer
              bcex                  ; B[12:9]= ROM pointer
              gosub   ENCP00
              gosub   NXBYTP
              gosub   INCAD
              gosub   NXBYT         ; get next byte
              acex                  ; A[1:0]= program memory byte
                                    ; C[3:0]= program memory address
              rcr     -5            ; C[8:5]= program memory address
              pt=     8
              bcex    wpt           ; B[8:5]= program memory address
                                    ;  (saved for LINNUM)

              ldi     Text1
              a=0     s             ; say no argument
              ?a#c    x             ; is it a text 1?
              gonc    310$          ; yes
              c=c+1                 ; opcode for text 2
              a=a+1   s             ; say argument in text 2
              ?a#c    x             ; is it a text 2?
              goc     900000$       ; no
310$:         b=a     s             ; B.S= text1/2 flag
              bsr                   ; B[12]= text1/2 flag
                                    ; B[7:4]= program memory address
                                    ; B[11:8]= ROM page pointer
              s8=     0             ; say no prompt, scrolling
              s1=     0             ; say lcd not full yet
              s0=     0             ; assume 2nd operand
              gosub   ENCP00
              gosub   LINNUM
              bcex    x             ; B.X= line number
              c=b
              rcr     4             ; C[3:0]= program memory address
              a=c                   ; A[3:0]= program memory address
              rcr     -5            ; C[13]= text 1/2 flag
              s0=0
              ?c#0    s             ; text2?
              gonc    312$          ; no
              s0=1                  ; yes
312$:         gosub   INCAD
              gosub   GTBYT         ; get argument
              c=0     xs
              bcex                  ; B.X= prefix XROM number
                                    ; C[11:8]= ROM page pointer
                                    ; C[7:4]= program memory address
                                    ; C[3:0]= address
              n=c                   ; save in N

              rcr     5             ; C[6:3]= ROM page pointer
              m=c                   ; M[6:3]= ROM page pointer
              gosub   ENLCD
              gosub   inProgramSecondary
              goto    90000000$     ; (P+1) not available
                                    ;   We know the ROM is there as we looked
                                    ;   it, so the problem is really that its
                                    ;   FAT structure has been altered in a way
                                    ;   that makes it impossible to find it.
                                    ;   Just use the default display, we cannot
                                    ;   make anything meaningful out of it
                                    ;   anyway.
              b=a     m
              c=n                   ; C.X= line number
              a=c     x
              a=0     s
              gosub   CLLCDE
              gosub   GENNUM        ; output line #
              ldi     0x20
              slsabc                ; output a blank

              c=b     m
              gosub   PROMF2
              c=b     m
              gosub   isArgument    ; postfix argument?
              goto    320$          ; no
              s2=1                  ; yes, indicate this is a secondary
              cnex                  ; M[3:0]=address (preserve C)
              m=c
              c=n
              golong  400$


320$:         gosub   DF150         ; normal secondary, finalize line
              c=b     m
              gosub   resetBank     ; restore to primary bank
90000000$:    golong  9000000$

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
;;;       C[2:0] - numeric argument
;;;       A[2:0] - numeric argument
;;;       B[2:0] - numeric argument
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

              .section code, reorder
              .public argument
noSysBuf0:    spopnd
              gosub   LDSST0        ; need to reset partial key flag
              rcr     2             ;  as not done by ordinary error handlers
              cstex
              s1=0
              cstex
              rcr     -2
              regn=c  14
              golong  noSysBuf

argument:     gosub   sysbuf        ; ensure we have the system buffer
              goto    noSysBuf0     ; (P+1) no buf
              c=data                ; read buffer header
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
              gonc    9$            ; no
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
              c=0
              dadd=c                ; select chip 0
              c=g
              a=c                   ; in A.X
              b=c     x             ; in B.X
              rcr     -3            ; and finally to
              bcex    m             ; B.M
              c=b     x
              rtn

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
              goc     50$           ; with Flag_Argument set indicating found
              a=c
              c=n
              rcr     3             ; C[13:11]= buffer address
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
              golnc   30$           ; no
              a=0     x
              a=a+1   x             ; 001, lower 3 nibbles of A001
              c=regn  10
              rcr     1
              ?a#c    x             ; is this a secondary?
              goc     16$           ; no

              c=n                   ; yes, set the Flag_SEC_Argument flag
              rcr     -3
              dadd=c
              c=data                ; read buffer header
              cstex
              st=1    Flag_SEC_Argument
              cstex
              data=c
              c=0     x
              dadd=c

              c=m                   ; C.X= secondary function number
              n=c                   ; N[6:3]= secondary XADR
              a=c     x
              gosub   secondaryProgram
              nop                   ; (P+1) will not happen
                                    ;       (because we are called from the function
                                    ;        so it must exist!)
              acex
              rcr     -3
              c=b     x
              rcr     -4
              bcex
              gosub   INSSUB        ; prepare for insert
              a=0     s             ; clear count of successful inserts
              c=b
              rcr     9
              gosub   INBYTC
              c=b
              rcr     7
              gosub   INBYTC
              gosub   INSSUB
              a=0     s
              ldi     Text1
              gosub   INBYTC
              c=b
              rcr     4
              goto    18$

16$:          c=0                   ; N[6:3]= 0 (no secondary XADR)
              n=c
              gosub   INSSUB        ; prepare for insert
              a=0     s             ; clear count of successful inserts
              c=regn  10            ; insert instruction in program memory
              rcr     3
              gosub   INBYTC
              c=regn  10
              rcr     1
18$:          gosub   INBYTC
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
49$:          c=n
              ?c#0    m             ; do we have a secondary XADR?
              goc     52$           ; yes
              c=m                   ; no
              rcr     1
              gosub   GTRMAD
              nop
              acex
              rcr     11
52$:          gosub   PROMF2        ; prompt string
              c=n
              ?c#0    m             ; secondary XADR?
              gsubc   resetBank     ; yes, reset to primary bank

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


;;; **********************************************************************
;;;
;;; It this a postfix argument?
;;;
;;; In: C[6:3] - XADR
;;; Out: Returns to (P+1) if not an argument style function
;;;      Returns to (P+1) if it is argument, with
;;;     C[6:3] - points to second byte of 'gosub argument'
;;; Uses: A, C
;;;
;;; **********************************************************************

isArgument:   cxisa
              ?c#0    x             ; check if 2 nops
              rtnc                  ; no
              c=c+1   m
              cxisa
              ?c#0    x
              rtnc                  ; no XROM XKD
              c=c+1   m             ; inspect next word which should be
                                    ;  gosub Argument for a semi-merged
              ldi     FirstGosub(argumentEntry)
              a=c     x
              cxisa
              ?a#c    x
              rtnc                  ; not normal semi-merged
              c=c+1   m
              ldi     SecondGosub(argumentEntry)
              a=c     x
              cxisa
              ?a#c    x
              rtnc                  ; not normal semi-merged
              acex    m             ; match, return to P+2, preserving C.M
              c=stk
              c=c+1   m
              stk=c
              acex    m
              rtn
