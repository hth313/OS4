;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

#include "mainframe.i"

#define IN_OS4
#include "OS4.h"


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
;;; myShell: .con    kind
;;;          .con    .low12 displayRoutine
;;;          .con    .low12 standardKeys
;;;          .con    .low12 userKeys
;;;          .con    .low12 alphaKeys
;;;          .con    .low12 appendName
;;;
;;; kind
;;;   0 - system shell, means that it is a system extension. A Shell that
;;;       defines an alternative way to display numbers, like FIX-ALL would
;;;        belong to this group. Will get activated even if not at top level
;;;       of the stack if we scan down the stack as the top level Shell is
;;;       only defining some partial behavior.
;;;   1 - application shell, this means that it is only active
;;;       at top level. If found looking for a handler further down in the
;;;       stack, it is just skipped over.
;;;   2 - extension point
;;; routines - Need to be aligned 4, and 0 indicates means nothing special
;;;            is defined. An integer or complex mode would define
;;;            a standardKeys (probably set userKeys to the same), leave
;;;            alphaKeys empty.
;;;
;;;  Note: Leave other definitionBits to 0, they are for future expansion.
;;;
;;; **********************************************************************


;;; **********************************************************************
;;;
;;; activateShell - activate a given Shell
;;;
;;; In: C.X - packed pointer to shell structure
;;; Out: Returns to (P+1) if not enough free memory
;;;      Returns to (P+2) on success
;;; Uses: A, B, C, M, G, S0, S1, active PT, +2 sub levels
;;;
;;; **********************************************************************

              .section code
              .public activateShell
              .extern getbuf, insertShell, noRoom
activateShell:
              c=stk                 ; get page
              stk=c
              gosub   shellHandle
              m=c                   ; M[6:0]= shell handle
              gosub   getbuf
              rtn                   ; no room

;;; Search shell stack for shell handle in M[6:0]
;;; General idea:
;;; 1. If this shell is already at the top position, we are done.
;;; 2. Scan downwards in stack looking for it.
;;; 3. If found, mark it as removed, goto 5.
;;; 4. If not in stack and there is no empty slot, push a new register
;;;    (2 empty slots) on top of stack.
;;; 5. Push the new element on top of stack letting previous elements ripple
;;;    down until we find an unused slot. We know there will be such slot as
;;;    we ensured it in the previous steps.

              s0=     0             ; empty slots not seen
              s1=     0             ; looking at first entry
              pt=     6

              b=a     x             ; B.X= buffer pointer
              c=data                ; read buffer header
              rcr     1
              c=b     x
              rcr     3
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
              gonc    90$           ; yes, we are done
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
              gonc    90$           ; yes, done
              bcex    x             ; no, go to next register
              goto    32$

38$:          data=c                ; write back
              goto    90$           ; done

40$:          ?s0=1                 ; did we encounter any empty slots?
              goc     30$           ; yes
              acex                  ; C[6:0]= shell value
              c=0     s             ; mark upper half as unused
              cmex                  ; M= shell register value to insert
              rcr     -3
              a=c     x             ; A.X= buffer header address
              gosub   insertShell   ; insert a shell register on top of stack
              rtn                   ; (P+1) no room
90$:          golong  RTNP2         ; (P+2) done


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
;;; Uses: A, B.X, C, M, S0, DADD, active PT, +1 sub level
;;;
;;; **********************************************************************

              .section code
              .public exitShell, reclaimShell
              .extern sysbuf

exitShell:    s0=0
              goto exitReclaim10

reclaimShell: s0=1

exitReclaim10:
              c=stk                 ; get page
              stk=c
              gosub   shellHandle
              m=c
              gosub   sysbuf
              rtn                   ; no shell buffer, quick exit
              c=data                ; read buffer header
              pt=     13            ; reclaim system buffer
              lc      1             ; (do not increment, it may make it wrap)
              data=c
              rcr     4
              c=0     xs            ; C.X= number of stack registers
              c=c-1   x             ; get 0 oriented counter
              rtnc                  ; no shell registers
              cmex                  ; M.X= number of stack registers
                                    ; C[6]= page address of ROM
              pt=     5             ; we will compare lower 6 nibbles
                                    ; to match when reclaiming
              acex                  ; A[5:0]= shell handle to (de)activate
                                    ; A[6]= current page of the owning ROM
                                    ; C.X= buffer header address

10$:          c=c+1   x             ; point to next shell register
              dadd=c
              bcex    x
              c=data
              ?a#c    wpt           ; shell in lower part?
              goc     20$           ; no
              pt=     6
              ?s0=1                 ; reclaim?
              goc     14$           ; yes
              c=0     pt            ; no, deactivate it
12$:          data=c                ; write back
              rtn                   ; done
14$:          ?c#0    pt            ; reclaim it, was it active before?
              rtnnc                 ; no
              acex    pt            ; yes, reclaim and activate it
              goto    12$

20$:          rcr     7             ; inspect upper part
              ?a#c    wpt           ; shell in upper part?
              goc     30$           ; no
              pt=     6
              ?s0=1                 ; yes, reclaim?
              goc     24$           ; yes
              c=0     pt            ; no, deactivate it
              goto    26$
24$:          ?c#0    pt            ; reclaim it, was it active before?
              rtnnc                 ; no
              acex    pt
26$:          rcr     7             ; realign
              goto    12$

30$:          cmex
              c=c-1   x             ; decrement register counter
              rtnc                  ; done
              cmex
              bcex    x
              goto    10$


;;; **********************************************************************
;;;
;;; releaseShells - release all Shells
;;;
;;; This is done a wake up with the idea that modules that still want their
;;; Shells should reclaim them (using reclaimShell).
;;; We set the high nibble to 1 of non-zero, thereby marking it as a
;;; released previously active shell. Any shell that was 0 (disabled)
;;; are left as-is, they can be re-used freely.
;;;
;;; Out: Returns to (P+1) if no system buffer
;;;      Returns to (P+2) if there is a system buffer with
;;;          A.X= address of buffer header
;;;
;;; **********************************************************************

              .section code
              .public releaseShells
releaseShells:
              gosub   shellSetup
              rtn                   ; (P+1) no system buffer
              goto    20$           ; (P+2) system buffer, but no shells
              b=a     x             ; B.X= system buffer address
10$:          a=a+1   x             ; step to next register
              acex    x
              dadd=c
              acex    x
              c=data
              ?c#0    s             ; high active?
              gonc    12$           ; no
              c=0     s             ; mark as released
              c=c+1   s
12$:          ?c#0    pt            ; low active?
              gonc    14$           ; no
              c=0     pt
              c=c+1   pt
14$:          data=c
              a=a-1   m
              gonc    10$
              abex    x             ; A.X= system buffer address
20$:          golong  RTNP2         ; return to (P+2)


;;; **********************************************************************
;;;
;;; shellHandle - look up a packed shell address and turn it into a handle
;;;
;;; In:  C[6] - page of shell descriptor
;;;      C[2:] - packed page address of shell descriptor
;;; Out: C[6:0] - full shell handle
;;;      C[6:3] - address of shell descriptor
;;;      C[2] - status nibble (sys/app)
;;;      C[1:0] - XROM ID of shell
;;; Uses: A, C, active PT=5
;;;
;;; **********************************************************************

              .section code
shellHandle:
              csr     m
              csr     m
              csr     m             ; C[3]= page address
              c=c+c   x             ; unpack pointer
              c=c+c   x
              rcr     -3            ; C[6:3]= pointer to shell
              cxisa                 ; read definition bits
              a=c                   ; A[6:3]= shell descriptor address
              asl     x
              asl     x             ; A[2]= status nibble (of definition bits)
              pt=     5             ; point to first address of page
              c=0     wpt
              cxisa                 ; C[1:0]= XROM ID
              acex    m             ; C[6:3]= shell descriptor address
              acex    xs            ; C[2]= status nibble (of definition bits)
              rtn


;;; **********************************************************************
;;;
;;; topAppShell - find the topmost app shell
;;; topShell - find the topmost shell
;;; nextShell - find next shell
;;;
;;; topShell can be used to locate first active shell.
;;; The following active shells can be found by successive calls to
;;; nextShell.
;;;
;;; In:  Nothing
;;; Out: Returns to (P+1) if no buffer
;;;      Returns to (P+2) if no shells (active)
;;;          B.X - buffer address
;;;      Returns to (P+3) with
;;;          A[6:3] - pointer to shell
;;;          M - shell scan state
;;;          ST= system buffer flags, Header[1:0]
;;;          B.X= address of system buffer
;;; Uses: A, B.X, C, DADD, S8, active PT, +2 sub levels
;;;
;;; **********************************************************************

              .section code
              .public topAppShell, topShell, nextShell
              .extern RTNP2, RTNP3
topAppShell:  s8=1
              goto    ts05
topShell:     s8=0
ts05:         gosub   shellSetup
              rtn                   ; (P+1) no system buffer
              goto    noActiveShell ; (P+2) no shells (though there was a buffer)
              b=a     x             ; (P+3)
              s9=0                  ; no app seen so far
              ?st=1   Flag_NoApps   ; running without apps?
              gonc    ts08          ; no
              ?s8=1                 ; are we looking for an app?
              goc     toRTNP2       ; yes, so we cannot find anything

ts08:         a=0     s             ; at first slot
              a=a+1   x
              acex    x
              dadd=c
              acex    x
              c=data
              ?c#0    pt            ; first slot in use?
              goc     ts25          ; yes
ts14:         ?c#0    s             ; second slot in use?
              goc     ts20          ; yes
ts16:         a=a-1   m
              gonc    ts08
              goto    toRTNP2
noActiveShell:
              b=a     x
toRTNP2:      golong  RTNP2         ; no shell found

ts18:         ?a#0    s             ; skipping past one, are we at upper?
              goc     ts40          ; yes, continue with next register
              goto    ts14          ; no, look at upper

ts20:         rcr     7
              a=a+1   s             ; second slot
ts25:         cxisa                 ; fetch descriptor
              c=c-1   x             ; is it an app shell?
              c=c-1   x
              gonc    ts27          ; no
              ?s9=1                 ; have we already visited an app?
              goc     ts18          ; yes, skip this one
              s9=1                  ; now we are visiting the first app
              goto    ts30
ts27:         ?s8=1                 ; not an app, are we looking only
                                    ;   for an  app shell?
              goc     ts18          ; yes, pass this one

;;; * use this one
ts30:         acex                  ; A[6:3]= pointer to shell
              m=c                   ; M= shell scan state
              golong  RTNP3         ; found, return to (P+3)

nextShell:    s8=0                  ; looking for any shell
              c=m                   ; C= shell scan state
              pt=     6
              ?c#0    s             ; next is in upper part?
              goc     10$           ; no, need a new register
              dadd=c                ; yes, select same register
              a=c                   ; A= shell scan state
              c=data
              goto    ts14          ; go looking at second slot

10$:          a=c
ts40:         a=0     s             ; first slot
              goto    ts16          ; loop again


;;; **********************************************************************
;;;
;;; disableThisShell - end current shell
;;;
;;; Assuming that we are scanning the shell stack, disable the current
;;; shell. Intended to be used when a transient App encounters a default
;;; key that also means that it should end.
;;;
;;; In: M - shell scan state
;;; Uses: A, C, DADD, PT=6
;;;
;;; **********************************************************************

              .section code
              .public disableThisShell
disableThisShell:
              c=m
              a=c
              dadd=c
              c=data
              ?a#0    s
              goc     10$
              pt=     6
              c=0     pt
              goto    20$
10$:          c=0     s
20$:          data=c
              rtn


;;; **********************************************************************
;;;
;;; shellSetup - prepare for scanning shell stack
;;;
;;; In:  Nothing
;;; Out: Returns to (P_1) if no system buffer
;;;      Returns to (P+2) if no shells with
;;;          A.X - pointer to buffer header
;;;      Returns to (P+3) with
;;;          A.X - pointer to buffer header
;;;          A.M - number of shell registers - 1
;;;          ST= system buffer flags, Header[1:0]
;;;          PT= 6
;;;          DADD= buffer header
;;; Uses: A, B.X, C, +1 sub level
;;;
;;; **********************************************************************

              .section code
shellSetup:   gosub   sysbuf
              rtn                   ; no buffer, return to (P+1)
              c=data                ; read buffer header
              st=c
              rcr     4
              c=0     xs
              c=c-1   x
              golc    RTNP2         ; no shell registers, return to (P+2)
              c=0     m
              rcr     -3
              a=c     m
              pt=     6
              golong  RTNP3         ; there are shells, return to (P+3)


;;; **********************************************************************
;;;
;;; keyHandler - invoke a key handler
;;;
;;; !!!! Does not return if the key is handled.
;;;
;;; In: A[6:3] - pointer to shell
;;;     S8 - set if we have already seen an application shell,
;;;          cleared otherwise. Should be cleared before making
;;;          the first of possibly successive calls to keyHandler.
;;; Out: S8 - updated to be set if we skipped an application shell
;;;
;;; **********************************************************************

              .section code
              .public keyHandler
keyHandler:   acex    m
              cxisa                 ; read control word
              a=c     m             ; A[6:3]= shell pointer
              c=c-1   x
              goc     10$           ; sys shell
              c=c-1   x
              rtnnc                 ; extension point, skip this one
              ?st=1   Flag_NoApps   ; app shell, are we looking for one?
              rtnc                  ; no, skip past it
              st=1    Flag_NoApps   ; yes, do not look for any further apps
10$:          c=0     x
              dadd=c
              a=0     s             ; assume not user mode
              c=regn  14            ; get flags
              cstex
              ?s7=1                 ; alpha mode?
              goc     20$           ; yes
              rcr     7
              cstex
              ?s0=1                 ; user mode?
              goc     14$           ; yes
              a=a+1   s             ; no, set A.S= non-zero
              goto    16$           ; normal mode

20$:          a=a+1   m             ; alpha mode
14$:          a=a+1   m             ; user mode
16$:          a=a+1   m             ; normal mode
              acex    m
              goto    mayCall1


;;; **********************************************************************
;;;
;;; mayCall1 - step ahead and call if pointer exists
;;; mayCall  - call if pointer exists
;;; gotoPacked - call a packed pointer
;;;
;;; mayCall:
;;; In: C[6:3] - pointer to some packed page pointer of some kind
;;;
;;; gotoPacked:
;;; In: C[6] - page
;;;     C[2:0] - packed page pointer
;;;
;;; mayCall fetch a routine pointer from memory and calls it if defined.
;;; gotoPacked is for calling a packed pointer.
;;;
;;; **********************************************************************

              .section code
mayCall1:     c=c+1   m             ; step to display routine
mayCall:      cxisa
              ?c#0    x             ; exists?
              rtnnc                 ; no display routine

gotoPacked:   c=c+c   x
              c=c+c   x
              csr     m
              csr     m
              csr     m
              rcr     -3
              gotoc


;;; **********************************************************************
;;;
;;; shellDisplay - show active shell display and set message flags
;;;
;;; This routine is meant to be called when a shell aware module wants
;;; to show the X register before returning to mainframe. We will look
;;; at the active application shell, do its display routine if mode is
;;; appropriate and set message flag to avoid having the normal show X
;;; routine update display, only to have it overwritten soon after.
;;; After calling this routine, jump back to a suitable NFR* routine
;;; which probably is NFRC.
;;;
;;; In: Nothing, do not care about DADD or PFAD
;;; Out: Nothing
;;; Uses: Worst case everything, +3 sub levels
;;;
;;; **********************************************************************

              .public shellDisplay, doDisplay
shellDisplay: ?s13=1                ; running?
              rtnc                  ; yes, done
              gosub   LDSST0        ; load SS0
              ?s3=1                 ; program mode?
              rtnc                  ; yes, no display override
              ?s7=1                 ; alpha mode?
              rtnc                  ; yes, no display override
doDisplay:    gosub   topAppShell
              rtn                   ; (P+1) no app shell (no buffer)
              rtn                   ; (P+2) no app shell (with buffer)
              a=a+1   m             ; (P+3) point to display routine
              acex    m
              cxisa
              ?c#0    x             ; does it have a display routine?
              rtnnc                 ; no
              acex                  ; yes, A[6,2:0]= packed display routine
              c=b     x             ; C.X= address of system shell
              dadd=c
              gosub   setDisplayFlags
              acex                  ; C[6,2:0]= display routine
              goto    gotoPacked    ; update display


;;; **********************************************************************
;;;
;;; displayDone - set flags indicating display is done
;;;
;;; You normally do not need to call this routine. It is meant to be used
;;; in certain cases when you have done the display early and do not
;;; want to have default display update the normal way.
;;; One situation where this is useful is for a command which purpose is
;;; to show an alternative display, like showing the 'X' value in an
;;; alternative way to default.
;;;
;;; Out: chip 0 selected
;;;      C= flag register of SS0
;;; Uses: C, DADD
;;;
;;; **********************************************************************

              .section code
              .public displayDone
displayDone:  gosub   sysbuf
              rtn
setDisplayFlags:
              c=data                ; set display override flag
              cstex
              st=1    Flag_DisplayOverride
              cstex
              data=c
              gosub   LDSST0        ; load SS0
              s5=1                  ; set message flag
              c=st
              regn=c  14
              rtn


;;; **********************************************************************
;;;
;;; extensionHandler - invoke an extension
;;;
;;; In:  C[1:0] - generic extension code
;;; Out:   Depends on extension behavior and if there is an active one.
;;;        If there are no matching generic extension, returns to the
;;;        caller.
;;;        If there is a matching generic extension, it decides on what to
;;;        do next and is extension defined.
;;;        Typical behavior include one of the following:
;;;        1. Return to extensionHandler using a normal 'rtn'. This is
;;;           typical if it is some kind of notification or broadcast.
;;;           In this case the shell stack is further searched for more
;;;           matching generic extensions that will also get the chance
;;;           to be called.
;;;        2. As a single handler that bypasses further matches by returning
;;;           to the orignal caller. This can be done using:
;;;             spopnd
;;;             rtn
;;;           Which takes us back to the original caller. It is not possible
;;;           for it to tell whether the call was handled by a generic
;;;           extension, unless some told by the return value, for example
;;;           using the N register that is not used by extensionHandler.
;;;           Another alternative is to return to (P+2) if the call was
;;;           handled (unhandled calls always return to (P+1)), this can
;;;           be done using:
;;;             golong dropRTNP2
;;;        Argument/accumulator:
;;;        You can pass information in for example N register to the
;;;        handler(s). Handler may update that information or whatever
;;;        is appropriate/useful. This is basically a protocol between
;;;        the original caller and the handlers, and is completely up to
;;;        the extension to define the protocol.
;;; Note: An extension that returns to extensionHandler must preserve
;;;       M and B.X and not leave PFAD active.
;;; Uses: A, B.X, C, M, ST, DADD, active PT, +3 sub levels
;;;
;;; **********************************************************************

              .section code
              .public extensionHandler
extensionHandler:
              st=c                  ; ST= extension code
              gosub   topShell
              rtn                   ; (P+1) no shells (no buffer)
              rtn                   ; (P+2) no shells (with buffer)
              ldi     0x200         ; (P+3) go ahead and look
              c=st
              bcex    x             ; B.X= extension code to look for
10$:          acex    m             ; C[6:3]= pointer to shell descriptor
              cxisa                 ; read control word
              a=c     x
              a=a-b   x
              ?a#0    x             ; same?
              gsubnc  mayCall1      ; yes, try to invoke it
              gosub   nextShell     ; not handled here, skip to next
              rtn                   ; (P+1) no more shells, no buffer
              rtn                   ; (P+2) no more shells
              goto    10$           ; (P+3) try the next one


;;; **********************************************************************
;;;
;;; shellName - append the name of the current shell to LCD
;;;
;;; Using the shell scan state, shift in the name of the active shell
;;; from the right into the LCD.
;;; This works the same way as MESSL, but the string comes from the shell.
;;;
;;; In: C[6:3] - pointer to shell
;;; Out: LCD selected
;;; Uses: A.M, C, +1 sub level
;;;
;;; **********************************************************************

              .section code
              .public shellName
              .extern unpack5
shellName:    gosub   unpack5
              nop                   ; (P+1) igonored, we assume there is a
                                    ;       defined name
              gosub   ENLCD
              golong  MESSL+1


;;; **********************************************************************
;;;
;;; disableOrphanShells - remove orphaned shells
;;;
;;; This routine is supposed to be called after a normal power on.
;;; At the moment this is done before going to light sleep and a flag
;;; Flag_OrphanShells is used to signal whether it is needed or not.
;;; Any shell that was active before the most recent power down and
;;; that has not been reclaimed are marked as unused.
;;;
;;; **********************************************************************

              .section code
              .public disableOrphanShells
disableOrphanShells:
              gosub   sysbuf
              rtn                   ; (P+1) no buffer
              st=c
              ?st=1   Flag_OrphanShells
              goc     10$           ; yes
5$:           golong  ENCP00        ; no, enable chip 0 and return

10$:          c=data                ; load buffer header
              st=0    Flag_OrphanShells
              c=st
              data=c                ; reset Flag_OrphanShells
              rcr     4
              c=0     xs
              bcex    x             ; B.X= shell counter

              pt=     6             ; set up for '1' testing of shell headers
              a=0     s
              a=a+1   s
              a=0     pt
              a=a+1   pt

20$:          bcex    x
              c=c-1   x
              goc     5$            ; no more shell registers
              bcex    x
              a=a+1   x             ; step to next shell register
              acex    x
              dadd=c
              acex    x
              c=data
              ?a#c    pt            ; disabled or active?
              goc     25$           ; yes
              c=0     pt            ; orphan, disable it
25$:          ?a#c    s             ; disabled or active?
              goc     30$           ; yes
              c=0     s             ; orphan, disable it
30$:          data=c                ; write back
              goto    20$
