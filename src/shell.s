;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

              #include "mainframe.i"


;;; **********************************************************************
;;;
;;; A Shell is a way to provide an alternative keyboard handler and/or
;;; display routine.
;;;
;;; A Shell is defined by a structure:
;;;     ldi  .low12 myShell
;;;     gosub someRoutine
;;;
;;;          .align 4
;;; myShell: .con    definitionBits
;;;          .con    .low12 displayRoutine
;;;          .con    .low12 standardKeys
;;;          .con    .low12 userKeys
;;;          .con    .low12 alphaKeys
;;;
;;; definitionBits
;;;   0 - Set if this is an application, this means that it is only active
;;;       at top level. If found looking for a handler further down in the
;;;       stack, it is just skipped over.
;;;       Cleared means that it is a system extension. A Shell that defines
;;;       an alternative way to display numbers, like FIX-ALL would belong
;;;       to this group. Will get activated even if not at top level of the
;;;       stack if we scan down the stack as the top level Shell is only
;;;       defining some partial behavior.
;;;  routines - Need to be aligned 4, and 0 indicates means nothing special
;;;             is defined. An integer or complex mode would define
;;;             a standardKeys (probably set userKeys to the same), leave
;;;             alphaKeys empty.
;;;
;;; **********************************************************************


;;; **********************************************************************
;;;
;;; activateShell - activate a given Shell
;;;
;;; In: C.X - packed pointer to shell structure
;;; Out: return to (P+2) if not enough free memory
;;; Uses: A, B, C, M, G, S0, S1, active PT, +2 sub levels
;;;
;;; **********************************************************************

              .section code
              .public activateShell
              .extern getbuf, insertShell, noRoom
activateShell:
              gosub   shellHandle
              m=c                   ; M[6:0]= shell handle
              gosub   getbuf
              goto    90$           ; no room

;;; Search shell stack for shell handle in M[6:0]
;;; General idea:
;;; 1. If this shell is already at the top position, we are done.
;;; 2. Scan downwards in stack looking for it.
;;; 3. If found, mark it as removed, goto 5.
;;; 4. If not in stack and do not have any empty slot, push a new register
;;;    (2 empty slots) on top of stack.
;;; 5. Push the new element on top of stack letting previous elements ripple
;;;    down until we find an unused slot. We know there will be such slot as
;;;    we ensured it in the previous steps.

              s0=     0             ; empty slots not seen
              s1=     0             ; looking at first entry
              pt=     6

              b=a     x             ; B.X= buffer pointer
              data=c                ; read buffer header
              rcr     3
              c=b     x
              rcr     1
              c=0     xs
              cmex                  ; M.X= number of stack registers
                                    ; M[13:11]= buffer header address
              a=c                   ; A[6:0]= shell handle to push

10$:          c=m                   ; C.X= stack registers left
              c=c-1   x
              goc     40$           ; no more stack registers
              m=c                   ; put back updated counter
              bcex    x
              c=c+1   x
              dadd=c                ; select next stack register
              bcex    x
              c=data                ; read stack register
              ?c#0    pt            ; unused slot?
              goc     12$           ; no
              s0=     1             ; yes, remember we have seen an empty slot
12$:          ?a#c    wpt           ; is this the one we are looking for?
              goc     14$           ; no
              ?s1=1                 ; are we looking at the top entry?
              rtn nc                ; yes, we are done
              c=0     pt            ; mark as unused
              data=c                ; write back
              goto    30$
14$:          s1=     1             ; we are now looking further down the stack
              rcr     7             ; look at second stack slot in register
              ?c#0    pt            ; unused slot?
              goc     16$           ; no
              s0=     1             ; yes, remember we have seen an empty slot
16$:          ?a#c    wpt           ; is this the one we are looking for?
              goc     10$           ; no, continue with next register
              c=0     pt            ; yes, mark as empty
              rcr     7
              data=c

              ;;  push handle on top of stack
30$:          c=m
              rcr     11            ; C.X= buffer header

32$:          c=c+1   x             ; C.X= advance to next shell stack register
              dadd=c
              bcex    x             ; B.X= shell stack pointer
              c=data
              acex    wpt           ; write pending handle to slot
              ?a#0    pt            ; unused slot?
              gonc    38$           ; yes, done
              rcr     7             ; do upper half
              acex    wpt
              rcr     7
              data=c                ; write back
              ?a#0    pt            ; unused slot?
              rtn nc                ; yes, done
              bcex    x             ; no, go to next register
              goto    32$

38$:          data=c                ; write back
              rtn                   ; done

90$:          golong  noRoom        ; "NO ROOM" error exit

40$:          ?s0=1                 ; did we encounter any empty slots?
              goc     30$           ; yes
              acex
              c=0     s             ; C= register value to insert
              cmex
              rcr     -3
              a=c     x             ; A.X= buffer header address
              gosub   insertShell   ; insert a shell register on top of stack
              goto    90$           ; (P+1) no room
              rtn                   ; (P+2) done


;;; **********************************************************************
;;;
;;; exitShell - dectivate a given Shell
;;; reclaimShell - reclaim a Shell at power on
;;;
;;; exitShell marks a given Shell as an unused slot, essentially removing it.
;;; We do not reclaim any memory here, it is assumed that it may be a
;;; good idea to keep one or two empty slots around. Reclaiming any
;;; buffer memory is a different mechanism.
;;;
;;; reclaimShell marks a shell to activate it.
;;;
;;; In: C.X - packed pointer to shell structure
;;; Out:
;;; Uses: A, B.X, C, M, S0, active PT, +1 sub level
;;;
;;; **********************************************************************

              .section code
              .public exitShell, reclaimShell
              .extern sysbuf

exitShell:    s0=0
              goto exitReclaim10

reclaimShell: s0=1

exitReclaim10:
              gosub   shellHandle
              m=c
              gosub   sysbuf
              rtn                   ; no shell buffer, quick exit
              data=c                ; read buffer header
              rcr     4
              c=0     xs            ; C.X= number of stack registers
              c=c-1   x             ; get 0 oriented counter
              rtn c                 ; no shell registers
              cmex                  ; M.X= number of stack registers
              pt=     5             ; we will compare lower 6 nibbles
              acex                  ; A[5:0]= shell handle to deactivate
                                    ; C.X= buffer header address

10$:          c=c+1   x             ; point to next shell register
              dadd=c
              bcex    x
              c=data
              ?a#c    wpt           ; shell in lower part?
              goc     20$           ; no
              ?s0=1                 ; reclaim?
              goc     14$           ; yes
              c=0     pt            ; no, deactivate it
12$:          data=c                ; write back
              rtn                   ; done
14$:          pt=     6
              acex    pt            ; reclaim it
              goto    12$

20$:          rcr     7             ; inspect upper part
              ?a#c    wpt           ; shell in upper part?
              goc     30$           ; no
              pt=     6
              ?s0=1                 ; yes. reclaim?
              goc     24$           ; yes
              c=0     pt            ; no, deactivate it
              goto    26$
24$:          acex    pt            ; reclaim it
26$:          rcr     7             ; realign
              goto    12$

30$:          cmex
              c=c-1   x             ; decrement register counter
              rtn c                 ; done
              cmex
              bcex    x
              goto    10$


;;; **********************************************************************
;;;
;;; releaseShells - release all Shells
;;;
;;; This is done a wake up with the idea that modules that still want their
;;; Shells should reclaim them (using reclaimShell).
;;;
;;; **********************************************************************

              .section code
              .public releaseShells
releaseShells:
              gosub   shellSetup
              rtn
10$:          a=a+1   x             ; step to next register
              acex    x
              dadd=c
              acex    x
              c=data
              c=0     s             ; release both Shell slots
              c=0     pt
              data=c
              a=a-1   m
              gonc    10$
              rtn


;;; **********************************************************************
;;;
;;; shellHandle - look up a packed shell address and turn it into a handle
;;;
;;; In:  C[6:3] - packed pointer to shell
;;; Out: C[6:0] - full shell handle
;;;      C[6:3] - address of shell
;;;      C[2] - status nibble (sys/app)
;;;      C[1:0] - XROM ID of shell
;;; Uses: A, C, G, active PT=4
;;;
;;; **********************************************************************

              .section code
shellHandle:  cxisa
              c=c+c   x             ; shell low offset * 4
              c=c+c   x
              a=c                   ; A[6:3]= (P+2)
                                    ; A[2:0]= low 12 bits of shell address

              pt=     5             ; point to first address of page
              c=0     wpt
              cxisa                 ; read XROM ID
              rcr     -4            ; C[5:4]= XROM ID
              pt=     4
              g=c                   ; G= XROM ID

              rcr     3             ; C[3]= page for (P+2)/shell
              acex    x             ; C[3:0]= shell address
              rcr     -3            ; C[6:3]= shell address
              cxisa                 ; C[2]= packed kind nibble
              c=c+1   xs            ; C[2]= unpacked kind nibble
              pt=     0
              c=g                   ; C[1:0]= XROM ID
                                    ; C[6:0]= shell handle
              rtn


;;; **********************************************************************
;;;
;;; topShell - find the topmost shell
;;; nextShell - find next shell
;;;
;;; topShell can be used to locate first active shell.
;;; The following active shells can be found by successive calls to
;;; nextShell.
;;;
;;; In:  Nothing
;;; Out: Returns to (P+1) if no shells
;;;      Returns to (P+2) with
;;;          C[6:3] - pointer to shell
;;;          M - shell scan state
;;; Uses: A, B.X, C, DADD, active PT, +2 sub levels
;;;
;;; **********************************************************************

              .section code
              .public topShell, nextShell
              .extern RTNP2
topShell:     gosub   shellSetup
              rtn
              a=0     s             ; first slot
ts10:         a=a+1   x
              acex    x
              dadd=c
              acex    x
              c=data
              ?c#0    pt
              goc     ts25
ts14:         ?c#0    s
              goc     ts20
ts16:         a=a-1   m
              gonc    ts10
              rtn

ts20:         rcr     7
              a=a+1   s             ; second slot
ts25:         rcr     -3
              acex
              m=c
              acex
              golong  RTNP2

nextShell:    c=m                   ; C= shell scan state
              pt=     6
              ?c#0    s             ; next is in upper part?
              goc     10$           ; no, need a new register
              dadd=c                ; select same register
              a=c
              c=data
              goto    ts14

10$:          c=0     s
              a=c
              goto    ts16


;;; **********************************************************************
;;;
;;; shellSetup - prepare for scanning shell stack
;;;
;;; In:  Nothing
;;; Out: Returns to (P+1) if no shells
;;;      Returns to (P+2) with
;;;          A.X - pointer to buffer header
;;;          A.M - number of shell registers - 1
;;;          PT= 6
;;;          DADD= buffer header
;;; Uses: A, B.X, C, +1 sub level
;;;
;;; **********************************************************************

              .section code
shellSetup:   gosub   sysbuf
              rtn
              data=c                ; read buffer header
              rcr     4
              c=0     xs
              c=c-1   x
              rtn c                 ; no shell registers
              c=0     m
              rcr     -3
              a=c     m
              pt=     6
              golong  RTNP2


;;; **********************************************************************
;;;
;;; doDisplay - let the active display routine alter the display
;;;
;;; **********************************************************************

              .section code
              .public doDisplay
doDisplay:    gosub   topShell
              rtn
mayCall:      c=c+1   m      ; step to display routine
              cxisa
              ?c#0    x             ; exists?
              rtn nc                ; no display routine

callPacked:   c=c+c   x
              c=c+c   x
              a=c     x
              rcr     3
              acex    x
              rcr     -3
              gotoc


;;; **********************************************************************
;;;
;;; keyHandler - invoke a key handler
;;;
;;; !!!! Does not return if the key is handled.
;;;
;;; In: C[6:3] - pointer to shell
;;;     S8 - set if we have already seen an application shell,
;;;          cleared otherwise. Should be cleared before making
;;;          the first of possibly successive calls to keyHandler.
;;; Out: S8 - updated to be set if we skipped an application shell
;;;
;;; **********************************************************************

              .public keyHandler
keyHandler:   cxisa                 ; read control word
              a=c     m             ; A[6:3]= shell pointer
              rcr     2
              st=c
              ?s0=1                 ; app shell?
              gonc    10$           ; no
              ?s8=1                 ; have we already seen an app shell?
              rtn c                 ; yes, skip this one
              s8=1                  ; no, but now we have
10$:          c=0     x
              dadd=c
              c=regn  14            ; get flags
              st=c
              rcr     7
              a=0     x
              a=a+1   x
              c=c&a
              ?c#0    x             ; user mode?
              goc     14$
              ?s7=1                 ; alpha mode?
              gonc    16$

              a=a+1   m             ; alpha mode
14$:          a=a+1   m             ; user mode
16$:          a=a+1   m             ; normal mode
              acex    m
              goto    mayCall
