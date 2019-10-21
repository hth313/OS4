#include "mainframe.i"

#define IN_OS4
#include "OS4.h"

PARS60:       .equlab 0xcb4

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
;;;          .con  .low12 keyboardDesc
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
              .public keyKeyboard
              .extern sysbuf, jumpC1, jumpC2, jumpC4, jumpPacked
              .extern disableThisShell
keyKeyboard:  c=regn  14            ; load status set 1/2
              rcr     1
              st=c
              c=stk                 ; get keyboard descriptor
              cxisa
              c=c+c   x
              c=c+c   x
              a=c     m
              rcr     -3
              pt=     5
              a=c     wpt           ; A[6:3] = keyboard descriptor
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
22$:          acex    m
              n=c                   ; N[2:1]= logical key code
                                    ; N[6:3]= keyboard descriptor
              c=regn  14            ; put up SS0
              st=c
              ?s7=1                 ; alpha mode?
              goc     40$           ; yes, skip all reassigned tests
              ?a#0    s             ; user mode?
              goc     40$           ; no
              gosub   TBITMP        ; yes, test bit map
              ?c#0                  ; key reassigned?
              golc    60$           ; yes
              ?s3=1                 ; program mode?
              goc     40$           ; yes, skip auto-assign tests

              acex    m
              cxisa                 ; C.X= keyboard flags
              acex    m
              cstex
              ?s0=1                 ; skip auto-assign tests?
              gonc    40$           ; yes

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
              cxisa                 ; C= packed page pointer to keyboard
              csr     m
              csr     m
              csr     m
              c=c+c   x
              c=c+c   x
              rcr     -3            ; C[6:3]= keyboard table

42$:          cxisa                 ; search table for key
              c=c+1   m             ; step to its key definition
              ?c#0    xs
              goc     30$           ; key not defined, try another keyboard
              ?a#c    x
              gonc    43$           ; key found
              c=c+1   m             ; step to next entry
              goto    42$
43$:          cxisa                 ; read key definition
              goto    48$

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
              gonc    30$           ; no, try another keyboard
48$:          spopnd                ; we will handle the key, no going back now
              c=c-1   xs            ; XROM override?
              goc     50$           ; yes
              c=c-1   xs            ; digit entry?
              goc     110$          ; yes
              c=c-1   xs            ; built-in, ends digit entry?
              gonc    45$           ; no
              cnex                  ; save function code
              gosub   appClearDigitEntry
              c=n                   ; restore function code
45$:          golong  PARS56

50$:          c=0     xs            ; decode XROM
              a=c     x
              ldi     64
              ?a<c    x             ; local XROM function?
              golnc   150$          ; no, need to look at secondaries

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

60$:          gosub   sysbuf        ; assigned key
              goto    70$           ; (P+1) ordinary key assignment

;;; @@@ Here we should scan for secondary assignments!!!
;;; @@@ Clear digit entry should be done here also?


70$:          golong  RAK60

;;; Builtin function. We always end digit entry here. There are some builtins
;;; that do not clear digit entry, but that should be handled by having 000 and
;;; falling back to default keyboard, not by coming here.
100$:         cnex                  ; N=KC, get table pointer
              gosub   appClearDigitEntry ; clear digit entry flag
              c=n                   ; restore key code
              c=c-1   x             ; adjust function code, it is offset by
                                    ; one to allow for 000 meaning pass through
                                    ; but the real 000 is CAT, and that is
                                    ; probably more useful than Text 15 (which
                                    ; is 0FF and that is now not possible to
                                    ; have on a key)
              golong PARS56

;;; Handle digit entry and backspace.
110$:         a=c     x             ; A[1:0]= digit
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
150$:         a=a-c   x             ; A.X= offset to secondary
              rcr     3
              c=a+c   x
              rcr     -3            ; C[6:3]= adr of secondary
              cxisa
              c=c+1   m
              a=c     x
              cxisa
              ?a#0    x             ; extended FAT?
              gonc    160$          ; yes
              rcr     2             ; no, a 2-byte instruction
              acex    x
              rcr     -2            ; C[3:0]= complete 2-byte instruction
              golong  RAK70



160$:                               ; C.X= extended FAT offset
                                    ; C[6:3]= pointing somewhere in ROM page



;;; **********************************************************************
;;;
;;; clearSystemDigitEntry - reset the system digit entry flag
;;;
;;; Uses: C, enables chip 0
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
