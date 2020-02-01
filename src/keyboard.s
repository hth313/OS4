#include "mainframe.i"

#define IN_OS4
#include "OS4.h"

PARS60:       .equlab 0xcb4
PRT5:         .equlab 0x6fe5

Text1:        .equ    0xf1

;;; **********************************************************************
;;;
;;; keyKeyboard - act on a key using the given keyboard definition
;;;
;;; Handle a key press according to the given keyboard. This will resolve
;;; auto assignment, assignments, decode and execute instructions according
;;; to a keyboard table. Additionally, it allows for custom digit entry
;;; and termination.
;;;
;;; Invoke this routine using:
;;;          gosub keyKeyboard
;;;          .con ...       ; keyboard descriptor
;;; The 'gosub' is to get the page address to be coupled with the lower
;;; 12 bits. This function will not return to that caller, instead it is
;;; assumed that the real return address is located in the previous slot
;;; on the stack (typically goes back to 'core' to try another shell
;;; when the key is not handled. If we do handle the key, we also drop
;;; that return address from the stack.
;;;
;;; In: KY - key register holds the key
;;;     Chip 0 selected
;;;     A.S - 0 if user mode (set in keyHandler)
;;;
;;; **********************************************************************

              .section code, reorder
              .public keyKeyboard, invokeSecondary
              .extern sysbuf, jumpC1, jumpC2, jumpC4, jumpPacked
              .extern disableThisShell, unpack0, testAssignBit
              .extern secondaryAssignment, secondaryAddress
              .extern resetBank, secondaryProgram
keyKeyboard:  c=regn  14            ; load status set 1/2
              rcr     1
              st=c
              c=stk                 ; get keyboard descriptor
              a=c     m             ; A[6:3] = keyboard descriptor
              c=keys
              rcr     5             ; KC to C[13:12]
              ldi     0x2a4
              c=c+c   xs            ; C.X= 0x4a4
              rcr     10
              pt=     3
              gotoc

              .section keycode      ; place at 0x4a40 using linker
              nop                   ; causes col 0 to map
                                    ; onto column 1
              lc      0             ; 1
              goto    20$           ; 2
              lc      1             ; 3
              goto    20$           ; 4
10$:          lc      2             ; 5
              goto    20$           ; 6
              goto    10$           ; 7
              lc      3             ; 8
              goto    20$           ; 9
              nop                   ; A (not used)
              nop                   ; B (not used)
              lc      4             ; C
20$:          rcr     1
              a=c     x
              ?s4=1                 ; shiftset?
              gonc    22$           ; no
              ldi     0x80          ; adj row for shift
              c=a+c   x
              a=c     x
22$:          acex    m
              n=c                   ; N[2:1]= logical key code
                                    ; N[6:3]= keyboard descriptor
              c=regn  14            ; put up SS0
              st=c
              ?s7=1                 ; alpha mode?
              goc     400$          ; yes, skip all reassigned tests
              ?a#0    s             ; user mode?
              goc     400$          ; no
              c=m                   ; M normally contains shell scan state
              rcr     -4            ; The [2:0] field is busted, but we know
                                    ;   [12:6] is 0, so align [12:10] over [2:0]
              bcex                  ; preserve it in B
              asr     x             ; A[1:0]= keycode, 0-79 form
              a=a+1   x             ; to 1-80 form
              gosub   testAssignBit
              goto    24$           ; (P+1) not reassigned
              goto    23$           ; (P+2) normal reassigned
              golong  secondaryASN  ; (P+3) secondary reassigned
23$:          c=0     x
              dadd=c
              golong  RAK60

24$:          bcex                  ; not reassigned
              c=0     x             ; restore scan state to M
              dadd=c
              rcr     4
              m=c

              ?s3=1                 ; program mode?
              goc     40$           ; yes, skip auto-assign tests

              c=n
              cxisa                 ; C.X= keyboard flags
              cstex
              ?st=1   KeyAutoAssign ; use auto-assigns?
400$:         gonc    40$           ; no (also relay)

              c=n
              c=0     m
              rcr     2             ; logical row to C.S
              a=c     x             ; logical col to A.X
              ldi     0x66          ; row 0 offset
              c=c-1   s             ; row 0?
              goc     25$           ; yes
              pt=     0
              lc      11            ; set up for row 1 test
              ?c#0    s
              gonc    25$           ; row 1
              pt=     1
              lc      7             ; shifted row 0 test
              c=c+1   s
              c=c+c   s             ; shifted?
              gonc    40$           ; no
              ?c#0    s             ; not shifted row 0?
              goc     40$           ; not auto assigned
25$:          c=a+c   x             ; C.X = implied local label
              m=c                   ; save operand in M
              a=c                   ; set up A[1:0] for search
              gosub   SEARCH
              ?c#0                  ; found?
              gonc    40$           ; no

              bcex                  ; yes, save adr in B
              c=n
              gosub   appClearDigitEntry ; clear digit entry flag
              bcex
              golong  PARS60        ; do auto assigned user language label

30$:          c=n                   ; no key behavior defined
              cxisa                 ; read descriptor word
              rcr     -1
              c=c+c   s             ; is this a transient App that ends on
                                    ;  undefined key?
                                    ; (KeyFlagTransientApp, assumed to be 7)
              gonc    35$           ; no
              c=n                   ; yes, terminate it
              gosub   jumpC4        ; call the transient termination vector
              golong  disableThisShell
35$:          c=n                   ; use system replacement
              golong  appClearDigitEntry ; clear app digit first

40$:          c=regn  14            ; key not reassigned
              cstex                 ; bring up SS0
              c=n
              csr     x
              a=c     x             ; A[1:0]= keycode
                                    ; A[2]= 0
                                    ; C[6:3]= keyboard descriptor
              cxisa                 ; read keyboard flags
              c=c+1   m             ; step to keyboard table pointer
              c=c+1   m
              c=c+1   m
              cstex                 ; ST= keyboard flags
              ?st=1   KeyFlagSparseTable
              gonc    44$
              cstex                 ; restore SS0
              gosub   unpack0       ; C= packed page pointer to keyboard
                                    ; C[6:3]= keyboard table
              a=0     m             ; reset XKD counter

42$:          cxisa                 ; search table for key
              c=c+1   m             ; step to its key definition
              ?c#0    xs
              goc     30$           ; key not defined, try another keyboard
              ?a#c    x
              gonc    43$           ; key found
              cxisa                 ; fetch handler
              c=c+1   m             ; step to next entry
              ?c#0    x             ; XKD special?
              goc     42$           ; no
              a=a+1   m             ; yes, step XKD counter
              goto    42$
43$:          cxisa                 ; read key definition
              ?c#0    x             ; XKD special key?
              goc     48$           ; no, ordinary key
              spopnd                ; we are handling it
431$:         c=c+1   m             ; step to end of table to find XKD handlers
              cxisa
              c=c+1   m
              ?c#0    xs
              gonc    431$
              c=a+c   m             ; point to XKD handler
              cxisa                 ; fetch it
              golong  jumpPacked

44$:          cstex                 ; restore SS0
              cxisa
              c=c+c   x
              c=c+c   x
              bcex    x             ; B.X= low 12 bits of keyboard table start
              rcr     3             ; C[3]= page address
              a=a+b   x             ; A.X= keyboard table + key code
              acex    x
              rcr     -3            ; C[6:3]= keyboard table adr
              cxisa                 ; fetch key table entry
              ?c#0    x             ; something there?
              golnc   30$           ; no, try another keyboard
48$:          spopnd                ; we will handle the key, no going back now
              c=c-1   xs            ; XROM override?
              goc     50$           ; yes
              c=c-1   xs            ; digit entry?
              golc    digitEntry    ; yes
              c=c-1   xs            ; built-in, ends digit entry?
              gonc    45$           ; no
;;; Builtin function. We always end digit entry here. There are some builtins
;;; that do not clear digit entry, but that should be handled by having 000 and
;;; falling back to default keyboard, not by coming here.
              cnex                  ; save function code
              gosub   appClearDigitEntry
              c=n                   ; restore function code
              c=c-1   x             ; adjust function code, it is offset by
                                    ; one to allow for 000 meaning pass through
                                    ; but the real 000 is CAT, and that is
                                    ; probably more useful than Text 15 (which
                                    ; is 0FF and that is now not possible to
                                    ; have on a key)
45$:          golong  PARS56

50$:          c=0     xs            ; decode XROM
              a=c     x
              ldi     64
              ?a<c    x             ; local XROM function?
              golnc   secondary     ; no, need to look at secondaries

              pt=     5             ; yes, local XROM
              c=0     wpt           ; point to XROM ID
              cxisa                 ; C.X= XROM ID
              c=c+c   x             ; divide by 4
              c=c+c   x
              c=0     s
              rcr     1             ; C.X= XROM / 4
                                    ; C[13:12]= 64 * (XROM % 4)
              b=a     x             ; B.X= instruction number
              a=c     x
              ldi     160
              c=a+c   x             ; calculate upper byte
              rcr     -2            ; C[3:2]= upper byte
              abex    x
              c=c+a   x             ; C[3:0]= complete 2 byte XROM
              cnex                  ; N[3:0]= complete 2 byte XROM
              gosub   appClearDigitEntry ; XROM ends digit entry
              c=n
58$:          golong  RAK70

noXXROM:      gosub   CLLCDE        ; display it as XXROM nn,func
              ldi     'X'-64
              slsabc
              asl
              asl
              asl
              c=n
              a=c     x
              b=a                   ; B.X= funcId, B[5:3] = xrom Id
              gosub   XROMNF
              s9=0                  ; we did not find it
              golong  nullTest

;;; * Handle secondary reassigned keys.
secondaryASN: c=n                   ; convert keycode to 1-80 form
              csr     x
              c=c+1   x
              n=c                   ; N[1:0]= keycode to 1-80 form
              gosub   secondaryAssignment
              goto    noXXROM       ; (P+1) not plugged in
foundXXROM:   acex                  ; C[6:3]= XADR
                                    ; C.X= secondary function identity
              s9=1                  ; found
              m=c                   ; M[6:3]= XADR
                                    ; M.X= secondary function identity
              c=regn  10            ; set XROM 0,1 as function code
                                    ;  (This is an impossible XROM as 0 is
                                    ;   not valid. We are not going to execute
                                    ;   it, rather use it as a marker for
                                    ;   partialKeyTakeOver to redirect it).
                                    ;  (It is also used by semi-merged operand
                                    ;   handling to see that we are actually
                                    ;   executing a secondary function and the
                                    ;   function number will be in M.X)
              pt=     4
              lc      10            ; A001
              lc      0
              lc      0
              lc      1
              regn=c  10
              c=m
              cxisa                 ; C.X= first word
              pt=     13
              lc      2             ; XROM bit to be part of ptemp2
              ?c#0    x             ; programmable?
              goc     65$           ; yes
              c=c+1   m             ; no, check for XKD
              cxisa                 ; fetch next word
              ?c#0    x             ; is C(XADR+1) non-zero?
              goc     70$           ; yes
              gotoc                 ; no -> XKD function - go do it
65$:          ?s3=1                 ; program mode?
              gonc    70$           ; no
              c=c+1   s             ; yes, set insert bit
70$:          g=c                   ; save upper nibble in ptemp2
              rcr     12
              st=c                  ; bring up ptemp2
              gosub   OFSHFT
              gosub   DSPLN_
              c=m
              gosub   PROMF2
              c=m                   ; retrieve XADR again
              c=c-1   m             ; point to XADR-1
              cxisa                 ; op1 to C.XS
              ?c#0    xs            ; op1 # 0?
              gonc    noOperand
              n=c
              rcr     3
              a=c
              a=a+1                 ; A[3:0]= XADR
              gosub   ENCP00
              pt=     3
              c=regn  8             ; REG8[13:10] = XADR of secondary
              rcr     -4
              acex    wpt
              rcr     4
              regn=c  8
              gosub   sysbuf
              goto    noOperand     ; (P+1) should not happen
              c=data                ; set secondary proxy bit to indicate
              cstex                 ;  that we are doing secondary prompt handling
              st=1    Flag_SEC_PROXY
              cstex
              data=c
              gosub   ENLCD
              c=n
              golong  0xcda         ; start argument parsing

noOperand:    gosub   LEFTJ
              gosub   ENCP00
nullTest:     ldi     200
              .newt_timing_start
              disoff
72$:          rst kb
              chk kb
              gonc    73$
              c=c-1   x
              gonc    72$
              distog
              .newt_timing_end
              gosub   NULTST
              goto    74$
73$:          gosub   RST05         ; debounce key up
              gosub   CLLCDE
              distog
              gosub   ENCP00
74$:                                ; key is up. go execute FCN
                                    ; first give printer a chance
              ?s9=1
              gsubc   PRT5          ; only print if found
              gosub   RSTSEQ        ; clear SHIFTSET, PKSEQ,
                                    ; MSGFLAG, DATAENTRY,
                                    ; CATALOGFLAG, & PAUSING
                                    ; leaves SS0 up
              ?s9=1
99$:          golnc   ERRNE         ; we did not find it

              pt=     0
              c=g
              cstex                 ; get ptemp2
              ?s4=1                 ; insert?
              gonc    76$           ; no
              ?s12=1                ; private?
              golc    ABTS10        ; yes
              c=m                   ; C[6]= page address
              gosub   resetBank     ; reset to bank 1, we are not going to execute it
              c=m
              a=c     x
              gosub   secondaryProgram
              goto    99$           ; (P+1) not found
              acex
              rcr     -3
              c=b     x
              n=c                   ; N[6:3]= prefix XROM function code
                                    ; N[1:0]= secondary byte index for it
              gosub   INSSUB        ; prepare for insert
              a=0     s             ; number of inserts so far
              c=n
              rcr     5
              gosub   INBYTC
              c=n
              rcr     3
              gosub   INBYTC
              gosub   INSSUB
              a=0     s
              ldi     Text1
              gosub   INBYTC
              c=n
              gosub   INBYTC        ; adjust secondary function identity
              golong  NFRC

76$:          c=m                   ; get XADR
              a=c     m
              .public gotoFunction
gotoFunction: c=0
              pt=     4
              lc      15            ; put NFRPU (0x00f0)
              stk=c                 ;  on the subroutine stack
              acex    m
              gotoc

;;; Handle digit entry and backspace.
digitEntry:   a=c     x             ; A[1:0]= digit
              c=c+1   x             ; check for backspace
              gonc    112$          ; not backspace
              c=regn  14            ; backspace
              st=c
              ?s5=1                 ; message flag
              gonc    111$          ; no
              s5=0                  ; clear message flag
              c=st
              regn=c  14
              pt=     0
              c=g                   ; C[1:0] - previous flags in system buffer
              st=c
              ?st=1   Flag_DisplayOverride
              golnc   NFRKB         ; clear a shown message
              goto    112$
111$:         ?s3=1                 ; program mode?
              gonc    112$          ; no
              rcr     2
              cstex
              ?s2=1                 ; digit entry?
              goc     112$          ; yes
              cstex                 ; bring up SS0
              ldi     11            ; program mode delete
              golong  PARS56

112$:         acex    x             ; C[1:0]= digit
              pt=     0
              g=c                   ; G= digit
              gosub   sysbuf
              goto    113$          ; (P+1) should not happen
              c=data                ; (P+2) set display override
              cstex
              st=1    Flag_DisplayOverride
              cstex
              data=c

113$:         gosub LDSST0          ; set message flag as we are doing some kind
              s5=1                  ;  of digit entry, we assume a custom display
              c=st
              regn=c  14
              c=n                   ; C[6:3]= keyboard descriptor table
              pt=     0
              c=g
              c=0     xs            ; C[2:0]= key value
                                    ;   0FF = backspace
              golong  jumpC1        ; go and handle digit

;;; Key needs a secondary. The entry is basically an offset to it which
;;; means it is located somewhere after the normal key table.
;;; There are two variants:
;;; 1. A 2-byte instruction, typically another XROM, but feel free to
;;;    put 'RCL d' on your keyboard.
;;; 2. An secondary FAT instruction. In this case the first word is 0
;;;    and the second word is the offset (0-1023).
secondary:    a=a-c   x             ; A.X= offset to secondary
              rcr     3
              c=a+c   x
              rcr     -3            ; C[6:3]= adr of secondary
              cxisa
              c=c+1   m
              a=c     x
              cxisa
              ?a#0    x             ; extended FAT?
              gonc    invokeSecondary ; yes
              rcr     2             ; no, a 2-byte instruction
              acex    x
              rcr     -2            ; C[3:0]= complete 2-byte instruction
              golong  RAK70

;;; **********************************************************************
;;;
;;; invokeSecondary - call a secondary function
;;;
;;; Invoke a secondary function, that is, execute it or store in a program
;;; as appropriate. This function does not return, control is given back
;;; to operating system or program to execute next command.
;;; If the given secondary function is not currently in the given module
;;; page, appropriate action is taken (shows XXROM identity number, and
;;; give NONEXISTENT error unless NULLed).
;;;
;;; In: C[6]= page address
;;;     C.X - secondary function identity
;;;
;;; **********************************************************************

invokeSecondary:
              a=c     x             ; A.X= secondary index
              gosub   secondaryAddress
              goto    10$           ; (P+1) function not available(?)
              golong  foundXXROM
10$:          golong  noXXROM

;;; **********************************************************************
;;;
;;; clearSystemDigitEntry - reset the system digit entry flag
;;;
;;; Uses: C, enables chip 0
;;;
;;; **********************************************************************

              .public clearSystemDigitEntry
              .section code, reorder
appClearDigitEntry:
              c=c+1   m
              c=c+1   m
              cxisa
              ?c#0    x
              rtnnc                 ; does not define any digit entry
              gosub   jumpPacked    ; tell app tor clear digit entry
                                    ; must preserve: B, N and M!!!
;;; * fall into clearSystemDigitEntry
clearSystemDigitEntry:
              c=0
              dadd=c
              c=regn  14
              rcr     2
              cstex
              s2=0
              cstex
              rcr     -2
              regn=c  14
              rtn

;;; ************************************************************
;;;
;;; keyDispatch - table dispatch on key (from TIME module)
;;;
;;; Read the keycode and jump to the corresponding handler using
;;; a jump table.  This is essentially KEY-FC in the TIME module.
;;;
;;; IN: Key down, C[2:0] holds table length minus 1
;;;     Last entry in table must be 000 to mark end of table.
;;;
;;; OUT: C.X= 0 (to make it easy to increment for digit keys)
;;;
;;; USED: A, C
;;;
;;; NOTE: The key is down when entering. Any wait for key release
;;;       and debounce handing is the reposibility of the caller.
;;;
;;; ************************************************************

              .section code, reorder
              .public keyDispatch
keyDispatch:  c=0     m
              rcr     11
              a=c     m
              c=keys                ; read key
              rcr     3
              a=c     x
              c=stk                 ; get table address
10$:          cxisa                 ; read next keycode from table
              c=c+1   m             ; point to next entry
              ?c#0    x             ; end of table?
              gonc    20$           ; yes
              ?a#c    x             ; no, equal to key down?
              goc     10$           ; no
              c=0     x             ; yes, set C.X= 0
20$:          c=c+a   m             ; point to address
              gotoc
