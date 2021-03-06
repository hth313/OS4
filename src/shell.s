;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

#include "mainframe.h"

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
;;;          .con    .low12 timeout      (only for applications)
;;;
;;; kind
;;;   SysShell - system shell, means that it is a system extension.
;;;       A Shell that defines an alternative way to display numbers, like
;;;       FIX-ALL would belong to this group. Will get activated even if not
;;;       at top level of the stack if we scan down the stack as the top level
;;;       Shell is only defining some partial behavior.
;;;   AppShell - application shell, this means that it is only active
;;;       at top level. If found looking for a handler further down in the
;;;       stack, it is just skipped over.
;;;   TransAppShell - transient application shell
;;;       Like an AppShell, but there can only be one and it will typically
;;;       be the top one. It is meant for temporary actions, such as a
;;;       catalog extension. Such can allow for certain keys and other keys
;;;       is meant to automatically terminate it and perform that action
;;;       instead.
;;;   GenericExtension - extension point
;;;       These use a different table which basically is a linear search
;;;       list:
;;;          .con    GenericExtension
;;;          .con    ExtensionXXX
;;;          .con    .low12 xxxHandler
;;;          [...]
;;;          .con    ExtensionListEnd
;;;
;;; routines - Need to be aligned 4, and 0 indicates means nothing special
;;;            is defined. An integer or complex mode would define
;;;            a standardKeys (probably set userKeys to the same), leave
;;;            alphaKeys empty.
;;;
;;; **********************************************************************


;;; activateShell docstart
;;; **********************************************************************
;;;
;;; activateShell - activate a given Shell
;;;
;;; In: C.X - packed pointer to shell structure
;;;     !! Must be called from same page as shell structure !!
;;; Out: Returns to (P+1) if not enough free memory
;;;      Returns to (P+2) on success
;;; Uses: A, B, C, M, G, ST, active PT, +3 sub levels
;;;
;;; **********************************************************************
;;; activateShell docend

              .section code, reorder
              .public activateShell, activateShell10
              .extern ensureSystemBuffer, insertShellB, insertShellC, noRoom
activateShell:
              c=stk                 ; get page
              stk=c
activateShell10:
              gosub   shellHandle
              gosub   ensureSystemBuffer
              rtn                   ; (P+1) no room

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
;;;
;;; Invariants:
;;; - A transient application shell is always at the top. Pushing some kind
;;;   of application on top of it will always deactivate it.
;;; - Application shells always appear on top of system shells and extensions.

              s0=     0             ; empty slots not seen
              s3=     0             ; looking at first entry
              s4=     0             ; no transient application released
              pt=     6

              b=a     x             ; B.X= buffer pointer
              c=data                ; read buffer header
              ?c#0    s             ; is buffer marked for removal?
              goc     5$            ; no
              c=c+1   s             ; yes, assume this call is from a power on
                                    ;   poll vector
              data=c                ; reclaim buffer
5$:           rcr     1
              c=b     x
              rcr     3
              c=0     xs
              cmex                  ; M.X= number of stack registers
                                    ; M[13:11]= buffer header address
              a=c     wpt           ; A[6:0]= shell handle to push

              c=0     pt            ; prepare for testing shell reclaims
              c=c+1   pt
              bcex    pt            ; B[6]= 1
              abex    pt            ; swap, to fit loop back
10$:          abex    pt
              c=m                   ; C.X= stack registers left
              c=c-1   x
              golc    40$           ; no more stack registers
              m=c                   ; put back updated counter
              bcex    x
              c=c+1   x
              dadd=c                ; select next stack register
              bcex    x
              c=data                ; read stack register
              ?s3=1                 ; at top entry?
              goc     11$           ; no
              ?s2=1                 ; yes, are we about to push an application
                                    ;  shell (ordinary or transient)?
              gonc    11$           ; no
              c=c+c   xs            ; is the top one a transient shell?
              c=c+c   xs
              c=c+c   xs
              gonc    9$            ; no

              c=0     pt            ; yes, auto deactivate it
              data=c                ;   (should be no harm to leave the
                                    ;    currupted xs field as we are going to
                                    ;    write it over in a moment)
              s4=     1             ; remember we dropped a transient application
              goto    15$           ; we have seen an empty slot now
9$:           c=data                ; refetch the stack register
11$:          ?c#0    pt            ; unused slot?
              goc     12$           ; no
15$:          s0=     1             ; yes, remember we have seen an empty slot
12$:          ?a#c    wpt           ; is this the one we are looking for?
              goc     14$           ; no
13$:          ?s3=1                 ; are we looking at the top entry?
              golnc   RTNP2         ; yes, we are done
              c=0     pt            ; mark as unused
              goto    22$
14$:          abex    pt            ; A[6]= 1
              ?a#c    wpt           ; the right shell, but in reclaim mode?
              goc     17$           ; no
              bcex    pt            ; yes, set the right page
              data=c                ; reclaim it
              bcex    pt            ; restore register state
              abex    pt
              goto    13$

17$:          abex    pt
              s3=     1             ; we are now looking further down the stack
              rcr     7             ; look at second stack slot in register
              ?c#0    pt            ; unused slot?
              goc     16$           ; no
              s0=     1             ; yes, remember we have seen an empty slot
16$:          ?a#c    wpt           ; is this the one we are looking for?
              gonc    20$           ; yes

              abex    pt            ; A[6]= 1
              ?a#c    wpt           ; the right shell, but in reclaim mode?
              goc     10$           ; no
              abex    pt            ; yes, restore registers
20$:          c=0     pt            ; mark as empty
              rcr     7
22$:          s0=     1             ; we have seen empty registers
              data=c                ; write back

40$:          ?s2=1                 ; are we pushing an application?
              gonc    100$          ; no
              ?s0=1                 ; yes, did we encounter any empty slots?
              goc     30$           ; yes
              c=0                   ; C[13:7]= 0
              acex    wpt           ; C[6:0]= shell value
              cmex                  ; M= shell register value to insert
              rcr     -3
              a=c     x             ; A.X= buffer header address
              ldi     1             ; C.X= offset to insert at (in buffer)
              gosub   insertShellC  ; insert a shell register on top of stack
              rtn                   ; (P+1) no room
                                    ; (P+2)
80$:          ?s4=1                 ; did we drop a transient application?
              gsubc   clearScratch  ; yes, also clear its scratch area
              c=stk
              c=c+1   m
              stk=c
              golong  shellChanged

;;; push app handle on top of stack
30$:          c=m
              rcr     11            ; C.X= buffer header

32$:          c=c+1   x             ; C.X= advance to next shell stack register
              dadd=c
              bcex    x             ; B.X= shell stack pointer
34$:          c=data
              acex    wpt           ; write pending handle to slot
              ?a#0    pt            ; unused slot?
              gonc    38$           ; yes, done
36$:          rcr     7             ; do upper half
              acex    wpt
              rcr     7
              data=c                ; write back
              ?a#0    pt            ; unused slot?
              gonc    80$           ; yes
              bcex    x             ; no, go to next register
              goto    32$

38$:          data=c                ; write back
              goto    80$           ; done

;;; It is expected that system shells and extensions are inserted by plug-in
;;; modules and not moved around so much. This is in contrast to applications
;;; that are activated and left.
;;; Thus, we locate the first shell slot after the last application shell
;;; (active or not) we insert it there (if empty), or add a new register and
;;; ensure the being inserted shell goes in as first behind the application
;;; shell. It will either be in that inserted register, or it goes with the
;;; last application shell.  The one that was there before goes to the new
;;; register.
;;; When we insert a single non-application in a register, we put it in the
;;; upper slot to make easy room for a following bening pushed (or apps being
;;; pushed down).
100$:         c=m
              rcr     11            ; C.X= buffer header
              dadd=c
              bcex    x             ; B.X= shell pointer (to be)
              c=data
              rcr     3
              c=0     m
              rcr     -2            ; C.M= number of shell registers
              bcex    x             ; C.X= shell pointer - 1
              pt=     9
              goto    110$
105$:         dadd=c                ; select next shell register
              bcex                  ; B= counters
              c=data                ; read next shell register
              c=c+c   xs            ; is lower half an app?
              c=c+c   xs
              gonc    120$          ; no
              c=c+c   pt            ; yes, is upper half an app?
              c=c+c   pt
              gonc    130$          ; no
              bcex                  ; yes, keep looking
110$:         c=c+1   x             ; point to next shell register
              c=c-1   m             ; count down remaining ones
              gonc    105$
              bcex    x             ; only apps in the shell stack (or empty)
                                    ; B.X= where we will insert the register
                                    ;       (pointing one past now)
122$:         acex                  ; C[6:0]= descriptor
              rcr     7             ; C[13:7]= descriptor
              pt=     6
              c=0     wpt           ; C[6:0]= 0
              cmex                  ; M= descriptor to write
                                    ; C[13:11]= buffer header pointer
              rcr     11
              a=c     x             ; A.X= buffer header pointer
              gosub  insertShellB
              rtn                   ; (P+1) failed
              goto    80$           ; (P+2)

120$:         s5=0                  ; low part not an app
              gosub   unusedSlot
              goto    122$          ; (P+1) no slots, need new register
              goto    34$           ; (P+2) write it here and ripple

130$:         s5=1                  ; low part taken by app
              gosub   unusedSlot
              goto    132$          ; (P+1) no slots, need new register
              c=data                ; (P+2) there are slots
              goto    36$           ; write it to upper slot and ripple

;;; In this situation we need to split the register as it is occupied
;;; by a non-app and an app.
132$:         c=data
              rcr     7             ; insert new shell here
              acex    wpt           ; A[6:0]= previous active top to push down
              rcr     7
              data=c                ; write back
              bcex    x             ; step ahead register
              c=c+1   x
              bcex    x
              goto    122$          ; insert a new shell register

;;; Support routine to check downwards for an empty shell slot.
;;; The idea is that if such exists, we can write a shell descriptor to it and
;;; ripple the shells down one position until we hit the empty slot.
;;; For that to work we need to know that such slot actually exists,
;;; which is the motivation for this routine.
unusedSlot:   pt=     6
              c=b     x             ; C.X= current shell pointer
              rcr     -3
              stk=c                 ; save that pointer on stack
              c=data
              ?s5=1                 ; skip first low part check?
              goc     15$           ; yes
              bcex                  ; no
10$:          bcex
              c=data
              ?c#0    pt            ; lower part unused?
              gonc    50$           ; yes

15$:          ?c#0    s             ; upper part unused?
              gonc    50$           ; yes

              bcex
              c=c+1   x             ; point to next register
              dadd=c                ; select it
              c=c-1   m
              gonc    10$

              c=stk                 ; nothing found
              rcr     3
              dadd=c
              bcex    x             ; restore original B.X
              rtn

50$:          c=stk
              rcr     3
              dadd=c
              bcex    x             ; restore original B.X
              golong  RTNP2


;;; exitShell docstart
;;; **********************************************************************
;;;
;;; exitShell - dectivate a given Shell
;;; reclaimShell - reclaim a Shell at power on
;;;
;;; exitShell marks a given Shell as an unused slot, essentially removing it.
;;; We do not reclaim any memory here, it is assumed that it may be a
;;; good idea to keep one or two empty slots around. Reclaiming any
;;; buffer memory is a different mechanism.
;;; Transient application will have any scratch area removed.
;;;
;;; reclaimShell marks a shell to activate it.
;;;
;;; In: C.X - packed pointer to shell structure
;;; Out:
;;; Uses: A, B.X, C, M, ST, S8, DADD, active PT,
;;;       +1 sub level if reclaimShell
;;;       +3 sub levels if exitShell (due to exit via shellChanged)
;;;
;;; **********************************************************************
;;; exitShell docend

              .section code, reorder
              .public exitShell, reclaimShell
              .extern systemBuffer

exitShell:    s8=0
              goto exitReclaim10

reclaimShell: s8=1

exitReclaim10:
              c=stk                 ; get page
              stk=c
              gosub   shellHandle
              gosub   systemBuffer
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
              ?s8=1                 ; reclaim?
              goc     14$           ; yes
              c=0     pt            ; no, deactivate it
12$:          data=c                ; write back
90$:          ?s1=1                 ; if we are deactivaing a transient app
              gsubc   clearScratch  ;  also drop scratch area
              ?s8=1                 ; reclaim mode?
              rtnc                  ; yes, done
              golong  shellChanged  ; no, send a notification too
              rtn                   ; done
14$:          ?c#0    pt            ; reclaim it, was it active before?
              rtnnc                 ; no
              acex    pt            ; yes, reclaim and activate it
              goto    12$

20$:          rcr     7             ; inspect upper part
              ?a#c    wpt           ; shell in upper part?
              goc     30$           ; no
              pt=     6
              ?s8=1                 ; yes, reclaim?
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
              goc     90$           ; done
              cmex
              bcex    x
              goto    10$

;;; exitTransientApp docstart
;;; **********************************************************************
;;;
;;; exitTransientApp - exit the top level transient application
;;;
;;; Exit any top level transient application and its transient area.
;;;
;;; In: Nothing
;;; Out: Nothing
;;; Uses: A, B.X, C, M, ST, active PT, DADD, +3 sub levels
;;;
;;; **********************************************************************
;;; exitTransientApp docend

              .section code, reorder
              .public exitTransientApp
exitTransientApp:
              gosub   hasActiveTransientApp
              rtn                   ; (P+1) no
exitTransientApp10:
              c=data                ; refetch
              c=0     pt            ; deactivate
              data=c
              gosub   clearScratch
              golong  shellChanged

;;; exitApp docstart
;;; **********************************************************************
;;;
;;; exitApp - exit the top level application
;;;
;;; Exit the top application.
;;;
;;; In: Nothing
;;; Out: Nothing
;;; Uses: A[12], A.X, C, B.X, active PT, DADD, +2 sub levels
;;;
;;; **********************************************************************
;;; exitApp docend

              .public exitApp
exitApp:      gosub   hasActiveTransientApp
              goto    10$           ; (P+1) no transient app
              goto    exitTransientApp10
10$:          gosub   topShell
              rtn                   ; (P+1) no buffer
              rtn                   ; (P+2) no shells
              ?s9=1                 ; (P+3) application shell found?
              rtnnc                 ; no
              c=m                   ; get scan state
              ?c#0    s             ; shell desriptor in upper half?
              gonc    20$           ; no, lower
              pt=     13
20$:          c=data
              c=0     pt            ; deactivate shell
              data=c
              rtn

;;; hasActiveTransientApp docstart
;;; **********************************************************************
;;;
;;; hasActiveTransientApp - is there an active top level transient application?
;;;
;;; In: Nothing
;;; Out: Returns to (P+1) if no active transient application
;;;      Returns to (P+2) if there is an active transient application
;;; Uses: A[12], A.X, C, B.X, active PT, DADD, +1 sub levels
;;;
;;; **********************************************************************
;;; hasActiveTransientApp docend

              .section code, reorder
              .public hasActiveTransientApp
hasActiveTransientApp:
              gosub   systemBuffer
              rtn                   ; (P+1) no system buffer
              c=data
              rcr     4
              c=0     xs
              ?c#0    x             ; any shells?
              rtnnc                 ; no
              a=a+1   x             ; yes, step to first
              acex    x
              dadd=c
              c=data
              pt=     6
              ?c#0    pt            ; is it active?
              rtnnc                 ; no
              c=c+c   xs            ; is it a transient application?
              c=c+c   xs
              c=c+c   xs
              rtnnc                 ; no
              golong  RTNP2         ; yes, return to (P+2)


;;; activeApp docstart
;;; **********************************************************************
;;;
;;; activeApp - return pointer to active application
;;;
;;; In: Nothing
;;; Out: Returns to (P+1) if no active application
;;;      Returns to (P+2) if there is an active application with
;;;        A[6:3]= unpacked pointer to application
;;;        PT= 6
;;; Uses: A, B.X, C, active PT, DADD, +2 sub levels
;;;
;;; **********************************************************************
;;; activeApp docend

              .section code, reorder
              .public activeApp
activeApp:    gosub   shellSetup
              rtn                   ; (P+1) no system buffer
              rtn                   ; (P+2) no shells
10$:          a=a+1   x
              acex    x
              dadd=c
              acex    x
              c=data
              ?c#0    pt            ; lower active?
              goc     15$           ; yes
              rcr     7
              ?c#0    pt            ; upper active?
              gonc    20$           ; no
15$:          c=c+c   xs            ; application?
              c=c+c   xs
              rtnnc                 ; no apps
              a=c     m
              golong  RTNP2
20$:          a=a-1   m
              gonc    10$
              rtn

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

              .section code, reorder
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
;;; Out: M[6:0] - full shell handle
;;;      M[6:3] - address of shell descriptor
;;;      M[2] - status nibble (sys/app)
;;;      M[1:0] - XROM ID of shell
;;;      S1 - set if this is a transient application shell
;;;      S2 - set if this is an application shell (of some kind)
;;; Uses: A, C, M, ST, active PT=5, +1 sub level
;;;
;;; **********************************************************************

              .section code, reorder
              .extern unpack
shellHandle:  gosub   unpack        ; C[6:3]= pointer to shell
              cxisa                 ; read definition bits
              a=c                   ; A[6:3]= shell descriptor address
              asl     x
              asl     x             ; A[2]= status nibble (of definition bits)
              pt=     5             ; point to first address of page
              c=0     wpt
              cxisa                 ; C[1:0]= XROM ID
              acex    m             ; C[6:3]= shell descriptor address
              acex    xs            ; C[2]= status nibble (of definition bits)
              m=c                   ; M[6:0]= full shell handle
              rcr     2
              st=c
              rtn

;;; topShell docstart
;;; **********************************************************************
;;;
;;; topExtension - find first extension point
;;; topShell - find first shell
;;; nextShell - find next shell (or extension point)
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
;;;          S9= application seen
;;;          PT= 6
;;;          DADD= register where shell descriptor is
;;; Uses: A, B.X, C, M, DADD, S8, S9, active PT, +2 sub levels
;;;
;;; **********************************************************************
;;; topShell docend

              .section code, reorder
              .public topExtension, topShell, nextShell
              .extern RTNP2, RTNP3
topExtension: s8=1
              goto    ts05
topShell:     s8=0
ts05:         gosub   shellSetup
              rtn                   ; (P+1) no system buffer
              goto    noActiveShell ; (P+2) no shells (though there is a buffer)
              b=a     x             ; (P+3)
              s9=0                  ; no app seen so far
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

ts20:         rcr     7
              a=a+1   s             ; second slot
ts25:         c=c+c   xs            ; system shell?
              goc     tsSys         ; yes
              c=c+c   xs            ; app shell?
              goc     tsApp         ; yes

tsExt:        ?s8=1                 ; extension, is that what we are looking for?
              goc    tsAccept       ; yes, accept

tsSkip:       ?a#0    s             ; skipping past one, are we at upper?
              goc     ts40          ; yes, continue with next register
              goto    ts14          ; no, look at upper

tsApp:        ?s8=1                 ; app, are we looking for an extension?
              goc     tsSkip        ; yes, skip
              ?s9=1                 ; have we already seen an app?
              goc     tsSkip        ; yes, skip
              s9=1                  ; now we have seen an app
              goto    tsAccept

tsSys:        ?s8=1                 ; system shell, are we looking for an extension?
              goc     tsSkip        ; yes, skip

;;; * use this one
tsAccept:     acex                  ; A[6:3]= pointer to shell
                                    ; Scan state:
                                    ; C[13]= upper/lower slot flag
                                    ; C.M= shell counter
                                    ; C.X= points to shell address
              m=c                   ; M= shell scan state
              golong  RTNP3         ; found, return to (P+3)

noActiveShell:
              b=a     x
toRTNP2:      golong  RTNP2         ; no shell found

nextShell:    c=m                   ; C= shell scan state
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
;;; shellSetup - prepare for scanning shell stack
;;;
;;; In:  Nothing
;;; Out: Returns to (P_1) if no system buffer
;;;      Returns to (P+2) if no shells with
;;;          A.X - pointer to buffer header
;;;          B.X - buffer header address
;;;      Returns to (P+3) with
;;;          A.X - pointer to buffer header
;;;          A.M - number of shell registers - 1
;;;          B.X - buffer header address
;;;          ST= system buffer flags, Header[1:0]
;;;          PT= 6
;;;          DADD= buffer header
;;; Uses: A, B.X, C, PT, +1 sub level
;;;
;;; **********************************************************************

              .section code, reorder
shellSetup:   gosub   systemBuffer
              rtn                   ; no buffer, return to (P+1)
              b=a     x             ; B.X= buffer header address
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
keyHandler:   gosub   shellKeyboard
              goto    mayCall

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

;;; shellDisplay docstart
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
;;; shellDisplay docend

              .public shellDisplay, doDisplay
shellDisplay: ?s13=1                ; running?
              rtnc                  ; yes, done
              gosub   LDSST0        ; load SS0
              ?s3=1                 ; program mode?
              rtnc                  ; yes, no display override
              ?s7=1                 ; alpha mode?
              rtnc                  ; yes, no display override
doDisplay:    gosub   topShell
              rtn                   ; (P+1) no app shell (no buffer)
              rtn                   ; (P+2) no app shell (with buffer)
              a=a+1   m             ; (P+3) point to display routine
              acex    m
              cxisa
              ?c#0    x             ; does it have a display routine?
              rtnnc                 ; no
              acex                  ; yes, A[6,2:0]= packed display routine
              c=b     x             ; C.X= address of system buffer
              dadd=c
              gosub   setDisplayFlags
              acex                  ; C[6,2:0]= display routine
              goto    gotoPacked    ; update display

;;; displayDone docstart
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
;;; In: Nothing
;;; Out: chip 0 selected
;;; Uses: A[12], A.X, C, B.X, active PT=12, DADD, +1 sub levels
;;;
;;; **********************************************************************
;;; displayDone docend

              .section code, reorder
              .public displayDone
displayDone:  gosub   systemBuffer
              rtn
setDisplayFlags:
              c=data                ; set display override flag
              cstex
              st=1    Flag_DisplayOverride
              cstex
              data=c
              c=0
              dadd=c
              c=regn  14
              cstex
              s5=1                  ; set message flag
              cstex
              regn=c  14
              rtn

;;; displayingMessage docstart
;;; **********************************************************************
;;;
;;; displayingMessage - test if showing a message
;;;
;;; This routine tests if the display is currently showing a message.
;;; Normally you would test the message flag in the flag register for this,
;;; but it may also be set by a shell to tell that the display is done
;;; and the system default of showing X should not be done.
;;; This poses a problem if you really want to know if a message is being
;;; shown, typically when implementing an alternative backarrow logic,
;;; where you want to distinguish between clearing the display or clearing
;;; the X register. In this case this routine is handy.
;;;
;;; Note: This will not report if a message is shown while running a
;;;       program! The reason is that this routine is intended for backspace
;;;       logic. In a running program you normally know if you are
;;;       displaying a message or not.
;;;       In a running program it suffices to inspect the ordinary message
;;;       flag.
;;;
;;; In: Nothing
;;; Out: Returns to (P+1) if showing message
;;;      Returns to (P+2) if normal display
;;; Uses: A[12], A.X, C, B.X, ST, active PT=12, DADD, +1 sub levels
;;;
;;; **********************************************************************
;;; displayingMessage docend

              .section code, reorder
              .public displayingMessage
displayingMessage:
              ?s13=1                ; running?
              goc     10$           ; yes, say not showing message
              gosub   LDSST0
              ?s4=1                 ; single stepping?
              goc     10$           ; yes, say not showing message
              ?s5=1                 ; message flag?
              gonc    10$           ; no
              gosub   systemBuffer  ; yes
              rtn                   ; (P+1) no system buffer, message
                                    ;       flag means we show a message
              c=data                ; C= buffer header
              c=st
              ?st=1   Flag_DisplayOverride
              rtnnc                 ; message flag not used for display override
10$:          golong  RTNP2         ; not showing message

;;; sendMessage docstart
;;; **********************************************************************
;;;
;;; sendMessage - invoke an extension
;;; shellChanged - the shell stack was changed
;;;
;;; In:  C[1:0] - generic extension code
;;; Out:   Depends on extension behavior and if there is an active one.
;;;        If there is no matching generic extension, returns to the
;;;        caller.
;;;        If there is a matching generic extension, it decides on what to
;;;        do next and is extension defined.
;;;        Typical behavior include one of the following:
;;;        1. Return to sendMessage using a normal 'rtn'. This is
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
;;;           using the N register that is not used by sendMessage.
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
;;; Note: An extension that returns to sendMessage must preserve
;;;       M, S9 and B.X and not leave PFAD active.
;;; Uses: A, B.X, C, M, ST, DADD, active PT, +3 sub levels
;;;
;;; **********************************************************************
;;; sendMessage docend

              .section code, reorder
              .public sendMessage
shellChanged: ldi     ExtensionShellChanged
sendMessage:  pt=     0
              g=c                   ; G= extension code
              gosub   topExtension
              rtn                   ; (P+1) no shells (no buffer)
              rtn                   ; (P+2) no shells (with buffer)
10$:          pt=     0
              c=g                   ; C[1:0]= extension code
              c=0     xs            ; C.X= extension code
              bcex    x             ; B.X= extension code to look for
              acex    m             ; C[6:3]= pointer to shell descriptor
              c=c+1   m             ; step past 'GenericExtension' kind word
12$:          cxisa                 ; read control word
              ?c#0    x             ; end of list?
              gonc    50$           ; yes
              c=c+1   m             ; step to handler
              a=c     x
              a=a-b   x
              ?a#0    x             ; same?
              gonc    20$           ; yes
              c=c+1   m             ; no, keep looking in same extension shell
              goto    12$

20$:          gosub   mayCall       ; invoke it
                                    ; got control back, try to pass it to
                                    ;  other modules too

50$:          s8=1                  ; say we are still looking for extensions
              gosub   nextShell     ; not handled here, skip to next
              rtn                   ; (P+1) no more shells, no buffer
              rtn                   ; (P+2) no more shells
              goto    10$           ; (P+3) try the next one

;;; shellName docstart
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
;;; shellName docend

              .section code, reorder
              .public shellName
              .extern unpack5
shellName:    gosub   unpack5
              gosub   ENLCD
10$:          cxisa
              slsabc
              c=c+1   m
              ?c#0    xs
              gonc    10$
              rtn


;;; **********************************************************************
;;;
;;; disableOrphanShells - remove orphaned shells
;;;
;;; This routine is supposed to be called after a normal power on.
;;;
;;; **********************************************************************

              .section code, reorder
              .public disableOrphanShells
              .extern shrinkBuffer, clearScratch, packHostedBuffers
disableOrphanShells:
              gosub   systemBuffer
              goto    5$            ; (P+1) no buffer
              c=data                ; load buffer header
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
              goc     40$           ; no more shell registers
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

;;; Power on cleanup. Tidy up after doing orphan shell removal.
55$:          gosub   clearScratch
              gosub   packHostedBuffers
5$:           gosub   ENCP00
              golong  0x01f0        ; pack I/O area and do the rest

;;; Prune unused shell registers. This is written in a somewhat inefficient
;;; way (we do not take advantage of that we may be able to delete multiple
;;; registers in one shrinkBuffer operation), but it is not expected to
;;; happen all that often and is done once at power on.
40$:          gosub   systemBuffer
              goto    5$            ; (P+1) should not happen
41$:          c=data                ; read buffer header
              rcr     3
              c=0     m
              rcr     -2
              c=a     x             ; C.M= number of shell registers (counter)
                                    ; C.X= buffer header
                                    ; (goes to N in the loop below)
              pt=     6
              goto    65$

60$:          n=c                   ; main loop to prune unused registers
              acex    x
              c=c+1   x
              dadd=c                ; select next shell register
              acex    x
              c=data

              ?c#0    pt
              goc     62$           ; in use
              ?c#0    s
              goc     62$           ; in use

              ldi     1             ; G= 1 (we remove one register at a time)
              pt=     0
              g=c

              c=n
              dadd=c                ; select buffer header
              bcex    x             ; B.X= buffer header address
              a=a-b   x             ; A.X= offset to register to go

              c=data                ; decrement shell counter in buffer header
              rcr     4
              c=c-1   x
              rcr     -4
              data=c

              c=b     x
              acex    x             ; A.X= buffer header
                                    ; C.X= offset to register to go

              gosub   shrinkBuffer  ; remove this single shell register
                                    ; (this handles buffer size too)
              goto    41$           ; start over

62$:          c=n
65$:          c=c-1   m             ; decrement shell counter
              gonc    60$           ; loop again
              gosub   shellChanged  ; send notification as all shells are not
                                    ;  in order
              goto    55$           ; done

;;; shellKeyboard docstart
;;; **********************************************************************
;;;
;;; shellKeyboard - get active keyboard
;;;
;;; Advance pointer to the field that holds the active keyboard handler.
;;;
;;; In: A[6:3] - pointer to shell
;;; Out: C[6:3] - pointer to active keyboard handler entry
;;; Uses: A[13:3], C, ST, DADD, +1 sub levels
;;;
;;; **********************************************************************
;;; shellKeyboard docend

              .section code, reorder
              .public shellKeyboard
shellKeyboard:
              a=0     s
              gosub   LDSST0
              ?s7=1
              goc     alphaMode
              rcr     7
              st=c
              ?s0=1
              goc     userMode
              a=a+1   s             ; no, set A.S= non-zero
              goto    normalMode
alphaMode:    a=a+1   m
userMode:     a=a+1   m
normalMode:   acex    m
              c=c+1   m
              c=c+1   m
              rtn
