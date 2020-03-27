;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

#include "mainframe.h"
#include "internals.h"
#define IN_OS4
#include "OS4.h"

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
              .extern systemBuffer, LocalMEMCHK, noSysBuf, jumpP1
              .extern inProgramSecondary, resetBank, secondaryProgram
              .extern XABTSEQ
doPRGM:       ?s12=1                ; PRIVATE ?
              goc     900$          ; yes
              gosub   systemBuffer
              goto    900$          ; (P+1) no system buffer
              c=data                ; (P+2) read buffer header
              st=c
              st=0    Flag_Pause    ; always reset pause flag when entering
                                    ;  program mode
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

;;; Abort entry of semi-merged instruction, remove XROM instruction as well.
;;; This has to done expanded as DELLIN cannot be called from a subroutine.

8$:           ?st=1   Flag_SEC_Argument
              gonc    7$
              gosub   GETPC
              gosub   DELLIN
              gosub   PUTPC
              gosub   BSTEP
7$:           gosub   GETPC
              gosub   DELLIN
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
              ?st=1   Flag_ArgumentDual
              golc    210$          ; dual argument
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
              goto    10$

6$:           ?st=1   Flag_SEC_Argument ; are we dealing with a secondary?
              gsubc   mergeTextLiterals ; yes, merge text literals

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
              goto    2000$         ; not semi-merged (must be short branch)

;;; **********************************************************************
;;;
;;; We have found an MCODE function with postfix argument.
;;; Now display it properly with its postfix argument.
;;;
;;; **********************************************************************

400$:         c=c+1   m             ; step to default argument
              cxisa                 ; get default argument
              n=c                   ; save it in case we need it
              ?s7=1                 ; dual argument function?
              goc     470$          ; yes
              ?s2=1                 ; secondary?
              gsubnc  DFRST8        ; no, display normal line
              gosub   RightJustify
              acex                  ; add a blank
              slsabc
              gosub   ENCP00
              ?s2=1                 ; secondary?
              gonc    410$          ; no
              ?s0=1                 ; do we have a text 2 (or 3)?
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
              golong  320$

2000$:        golong  200$

470$:         s8=     0             ; say no prompt, scrolling
              s1=     0             ; say lcd notl full yet
              gosub   ENCP00
              gosub   LINNUM        ; load line #
              a=c     x             ; A.X _ line #
              b=a     x             ; save line # in B.X
              gosub   CLLCDE
              a=0     s
              gosub   GENNUM        ; output line #
              ldi     ' '
              slsabc                ; and a space
              gosub   ENCP00
              gosub   NXBYTP
              gosub   INCAD
              gosub   NXBYT         ; get next byte
              b=a
              a=c     x
              ldi     Text2
              ?s2=1                 ; secondary?
              gonc    472$          ; no
              c=c+1   x             ; yes, make it a Text 3
472$:         ?a#c    x             ; is it a text 2?
              goc     480$          ; no, we do not have default for duals
              abex
              ?s2=1
              gsubc   INCAD         ; skip past secondary function #
              gosub   INCAD
              gosub   GTBYT
              acex
              rcr     -3            ; save program address on stack
              stk=c
              acex
              s0=0
              s1=1
              gosub   ROW930        ; first argument
              gosub   ENLCD
              ldi     ' '
              slsabc
              c=n                   ; yes, pick up the right XADR
              c=c-1   m
              c=c-1   m
              c=c-1   m
              c=c-1   m
              gosub   PROMF2
              gosub   RightJustify
              acex    x             ; add a space
              slsabc
              gosub   ENCP00
              c=stk                 ; restore program address
              rcr     3
              pt=     3
              a=c     wpt
              gosub   INCAD         ; step to second argument
              gosub   GTBYT
              gosub   ROW930
              gosub   RightJustify
              c=n
              c=0     xs
              ?c#0    x             ; postfix character?
              gonc    3200$         ; no (also relay)
              slsabc                ; yes
              goto    3200$

480$:         gosub   DFRST8        ; display normal line (when no text literal)
3200$:        golong  320$

900000$:      golong  900$

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
              gsubnc  jumpP1        ; do display handler
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
              c=c+1   x             ; opcode for text 2
              a=a+1   s             ; say argument in text 2
              ?a#c    x             ; is it a text 2?
              gonc    310$          ; yes
              c=c+1   x             ; opcode for text 3
              a=a+1   s             ; say argument in text 3
              ?a#c    x             ; is it a text 3?
              goc     900000$       ; no
310$:         b=a     s             ; B.S= text1/2/3 flag
              bsr                   ; B[12]= text1/2/3 flag
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
              rcr     -5            ; C[13]= text 1/2/3 flag
              s0=0
              ?c#0    s             ; text 2 or 3?
              gonc    312$          ; no
              s0=1                  ; yes
312$:         gosub   INCAD
              gosub   GTBYT         ; get argument
              c=0     xs
              bcex                  ; B.X= secondary function after XROM prefix
                                    ; C[11:8]= ROM page pointer
                                    ; C[7:4]= program memory address
                                    ; C[3:0]= line number
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
;;; Dual argument.
;;; When requesting the second argument the entire LCD needs to be
;;; recreated as it shows SIGMA-REG at this point!
;;;
;;; **********************************************************************

210$:         ?st=1   Flag_SEC_Argument ; are we dealing with a secondary?
              gsubc   mergeTextLiterals ; yes, merge text literals
              gosub   systemBuffer
              nop                   ; (P+1) filler, we know it exists
              c=data
              st=c
              pt=     13
              c=c+c   s             ; second argument?
              goc     220$          ; yes
              lc      9             ; no, we need second argument
              st=1    Flag_Argument ; need another argument
              cstex
              data=c
              rcr     2             ; C[1:0]= first argument
              bcex    x             ; B[1:0]= first argument
              c=0     x
              dadd=c
              c=regn  15            ; display line number
              a=c     x             ; A.X= line number
              c=regn  9
              bcex    m             ; B[6:3]= XADR
              gosub   CLLCDE
              gosub   DSPLN+8       ; display line number
              c=b     m             ; C[6:3]= XADR
              gosub   PROMF2        ; prompt string
              bcex    x             ; C[1:0]= first postfix argument
              s0=0                  ; 2 digit argument
              gosub   0x464         ; display first argument (ROW931+1)
              golong  requestArgument

220$:         lc      1             ; second argument entered, reset
              st=0    Flag_SEC_Argument
              cstex
              data=c                ; intermediate flag
              ?st=1   Flag_SEC_Argument
              gsubnc  mergeTextLiterals
              golong  10$

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

RightJustify: gosub   ENLCD
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
              .public argument, dualArgument
noSysBuf0:    spopnd
              gosub   LDSST0        ; need to reset partial key flag
              rcr     2             ;  as not done by ordinary error handlers
              cstex
              s1=0
              cstex
              rcr     -2
              regn=c  14
              golong  noSysBuf

dualReady:    c=0     s
              c=c+1   s
              st=0    Flag_ArgumentDual
              c=st
              data=c
              pt=     0
              c=g
              a=c                   ; A[3:2]= first argument
                                    ; A[1:0]= second argument
              c=stk
              c=c+1   m
              gotoc

dualArgument: s8=1
              goto    argument10
argument:     s8=0
argument10:   gosub   systemBuffer  ; ensure we have the system buffer
              goto    noSysBuf0     ; (P+1) no buf
              c=data                ; read buffer header
              st=c                  ; ST= system buffer flags
              acex    x
              pt=     0
              cnex                  ; N.X= system buffer header address
              g=c                   ; G= potential entered postfix argument
              ?s8=1                 ; dual argument?
              gonc    1$            ; no
              c=data                ; C[13]= high nibble of buffer header
              c=c+c   s             ; do we have a second argument ready?
              goc     dualReady     ; yes
1$:           ?s13=1                ; running?
              goc     3$            ; yes
              c=0     x
              dadd=c
              ?st=1   Flag_ArgumentDual
              goc     2$            ; skip saving secondary second time for duals,
                                    ;  it is already in place and second time we
                                    ;  come here M is most likely clobbered!
              c=m                   ; save potential secondary function in REG9/Q
              regn=c  9             ; needed when doing direct execution
2$:           c=regn  14
              cstex
              ?s4=1                 ; single step?
              golnc   xeqKeyboard   ; no
              cstex                 ; ST= system buffer flags

;;; We are executing the instruction from program memory
3$:           gosub   NXBYTP        ; examine argument byte
              b=a                   ; save address
              a=c     x             ; save operand byte
              st=0    Flag_Argument ; argument not known yet

;;; Entry point for executing from keyboard, in which case Flag_Argument
;;; must be set and the argument is in G
xeqWithArg:   c=stk
              cxisa                 ; get default argument
              m=c                   ; save for possible use
              c=c+1   m             ; update return address (skip over default argument)
              stk=c
              ?st=1   Flag_Argument ; argument already known (before coming here)?
              gonc    argNotKnown   ; no
              ?s8=1                 ; dual argument?
              gonc    singleArg     ; no
              c=data                ; yes, store first argument in buffer header[3:2]
              pt=     13
              lc      9             ; set highest bit, indicating we have first
                                    ; argument

              pt=     2
              c=g
              data=c
requestArgument:
              gosub   ENCP00
              c=regn  15
              rcr     3
              pt=     0
              g=c                   ; G= PTEMP2
              st=c                  ; ST= PTEMP2
              gosub   RightJustify  ; output a space
              acex    x
              slsabc
              golong  requestArgument10

singleArg:    c=g                   ; yes, move argument to C[1:0]
              goto    finalize

argNotKnown:  ldi     Text1
              ?st=1   Flag_SEC_Argument ; secondary?
              gonc    10$           ; no
              c=n
              dadd=c                ; select system buffer header
              st=0    Flag_SEC_Argument ; reset flag
              c=data
              c=st
              data=c
              abex                  ; yes, step over the secondary identifier
              gosub   INCAD
              abex
              ldi     Text2
10$:          ?s8=1                 ; dual argument?
              gonc    15$           ; no
              c=c+1   x
15$:          ?a#c    x             ; expected text literal follows?
              gonc    fetch10       ; yes
              ?s8=1                 ; no, dual argument?
              goc     toERRNE       ; yes, these have no default so it must match
              c=c-1   x             ; check one less
              ?a#c    x             ; default single argument?
toERRNE:      golnc   ERRNE         ; no
              c=m                   ; yes, use default argument instead
              goto    finalize
fetch10:      abex    wpt           ; argument follows in program
              gosub   INCAD
              gosub   PUTPC         ; store new pc (skip over Text instruction)
              c=regn  14
              st=c
              ?s4=1                 ; single step?
              gonc    71$           ; no
              c=regn  15            ; yes, bump line number
              c=c+1   x
              regn=c  15
71$:          gosub   GTBYT         ; get (first) argument
              ?s8=1                 ; dual?
              gonc    finalize      ; no
              pt=     0             ; yes
              g=c                   ; G= first argument
              gosub   INCAD         ; step ahead
              gosub   PUTPC
              gosub   GTBYT
              pt=     2
              c=g
              a=c                   ; A[3:2]= argument 1
                                    ; A[1:0]= argument 2
              golong  ENCP00
finalize:     pt=     0
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

xeqKeyboard:

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
13$:          ?s8=1                 ; are we doing two arguments?
              gonc    130$          ; no
              st=1    Flag_ArgumentDual ; remember argument2
130$:         cstex
              data=c                ; save back toggled flag
              ?st=1   Flag_Argument ; (inspecting previous value of flag)
              golc    xeqWithArg    ; with Flag_Argument set indicating found
              a=c
              c=n
              rcr     3             ; C[13:11]= buffer address
              c=stk
              cxisa                 ; C[1:0] = default argument
              c=c+1   m             ; bump return address
              stk=c
              rcr     4
              c=0     x
              c=0     s
              rcr     -4
              n=c                   ; N[2:0]= modifier bits and default argument
                                    ; N[6:3]= 0 (no secondary XADR, for a start)
                                    ; N[13:11]= buffer address
              pt=     0
              g=c
              acex                  ; get header again
              pt=     2
              c=g                   ; put default arg into 'DF' field
              ?s8=1                 ; doing 2 arguments?
              goc     132$          ; yes, DF field does not store default
              data=c                ; write back (if doing single argument)
132$:         c=0     x
              dadd=c
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
              gosub   LDSST0
              c=m                   ; C.X= secondary function number
                                    ; C[6:3]= XADR for secondary
              a=c
              c=n
              acex    m
              n=c                   ; N[6:3]= secondary XADR
                                    ; N[2:0]= modifier bits and default argument
              ?s3=1                 ; program mode?
              golnc   40$           ; no
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

16$:          c=regn  14
              st=c
              ?s3=1                 ; program mode
              gonc    30$           ; no
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
              c=0     x
              pt=     6
              ?c#0    wpt           ; do we have a secondary XADR?
              gonc    51$           ; no
              ?s4=1                 ; program mode?
              goc     52$           ; yes

;;; When executing from the keyboard we need to find the instruction again later.
;;; Change the XROM to be the prefix instruction of the secondary.
;;; Later when argument is given it is called and we can sort out
;;; how to call the secondary.
              gosub   ENCP00
              c=regn  9
              a=c     x             ; A.X= function number
                                    ; C[6:3]= XADR
              gosub   secondaryProgram
              nop                   ; (P+1) we know this exists
              bcex    x             ; C[1:0]= adjusted function number
              regn=c  9             ; save in REGN9/Q
              c=regn  10
              pt=     4
              asl                   ; A[4:1]= XROM prefix
              acex    wpt
              regn=c  10            ; REGN10[4:1]= XROM prefix
              gosub   ENLCD
              c=n                   ; C[6:3]= XADR
              goto    52$

51$:          c=m                   ; primary XROM
              rcr     1
              gosub   GTRMAD
              nop
              gosub   ENCP00
              acex
              rcr     11
              regn=c  9             ; REGN9[6:3]= XADR (ordinary XROM)
              gosub   ENLCD
52$:          gosub   PROMF2        ; prompt string
              c=n
              ?c#0    m             ; secondary XADR?
              gsubc   resetBank     ; yes, reset to primary bank

              pt=     0             ; restore PTEMP2
              c=g
              st=c
requestArgument10:
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

ABTSEQ_J1:    golong  XABTSEQ

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
;;;      Returns to (P+2) if it is single argument, with
;;;        C[6:3] - points to second byte of 'gosub argument'
;;;        S7=0 indicates one argument
;;;        S7=1 indicates dual arguments
;;; Uses: A, C
;;;
;;; **********************************************************************

              .public isArgument
isArgument:   cxisa
              ?c#0    x             ; check if 2 nops
              rtnc                  ; no
              c=c+1   m
              cxisa
              ?c#0    x
              rtnc                  ; no XROM XKD
              c=c+1   m             ; inspect next word which should be
                                    ;  gosub Argument for a semi-merged
              cxisa
              a=c     x
              ldi     FirstGosub(argumentEntry)
              ?a#c    x
              goc     10$           ; not normal semi-merged
              c=c+1   m
              cxisa
              a=c     x
              ldi     SecondGosub(argumentEntry)
              ?a#c    x
              goc     8$            ; not normal semi-merged
              s7=0
5$:           acex    m             ; match, return to P+2, preserving C.M
              c=stk
              c=c+1   m
              stk=c
              acex    m
              rtn

8$:           c=c-1   m
              cxisa
              a=c     x
10$:          ldi     FirstGosub(dualArgumentEntry)
              ?a#c    x
              rtnc
              c=c+1   m
              cxisa
              a=c     x
              ldi     SecondGosub(dualArgumentEntry)
              ?a#c    x
              rtnc
              s7=1
              goto    5$

;;; **********************************************************************
;;;
;;; Merge two text literals.
;;;
;;; Expects that we are standing at the second one which is a Text1.
;;; Its postfix byte is already in N[1:0]. This instruction is removed
;;; and we step back to the preceeding instruction which is either a
;;; Text1 or Text2 to which the postfix byte is added.
;;;
;;; In: N[1:0] - the byte of the latest postfix argument
;;; Uses: A, B, C
;;;
;;; **********************************************************************

mergeTextLiterals:
              gosub   GETPC
              gosub   NXBYTA        ; read Text1 (postfix operand)
              b=a
              a=c     x
              ldi     Text1
              pt=     1
              ?a#c    wpt
              rtnc                  ; hmm, not Text1
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
              a=0     s             ; Text1 or Text2 flag
              ldi     Text1
              pt=     1
              ?a#c    wpt
              gonc    10$
              c=c+1   x             ; C[1:0]= Text2
              a=a+1   s
              ?a#c    wpt
              rtnc                  ; hmm, not Text1 or Text2
10$:          c=c+1   x             ; now it is TextN + 1
              abex
              gosub   PTBYTA
              gosub   INCADA
              gosub   INCADA
              ?b#0    s             ; is it a Text3 (previously Text2)?
              gsubc   INCADA        ; yes, step one further
              c=n
              gosub   PTBYTA        ; write postfix byte
              golong  DFRST8        ; bring instruction line up
