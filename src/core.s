;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

              #include "mainframe.i"

;;; ----------------------------------------------------------------------
;;;
;;; Main take over entry point at address 0x4000.
;;;
;;; ----------------------------------------------------------------------

              .extern sysbuf, doDisplay

              .section Header4
              c=stk                 ; inspect return address (and drop it)
              rcr     1             ; C.XS= lower nibble
              c=c+c   xs
              goc     deepWake      ; deep wake up

lightWake:    ldi     0x2fd         ; PACH11
              dadd=c                ; enable nonexistent data chip 2FD
              pfad=c                ; enable display
              flldc                 ; non-destructive read

              c=0     x
              pfad=c                ; disable LCD
              dadd=c                ; select chip 0

              c=regn  14            ; C= flags

;;; ----------------------------------------------------------------------
;;;
;;; Light sleep wake up actually comes here both at wake up and when
;;; going back to light sleep after processing is done.
;;; We are introducing a buffer scan here which gives extra overhead.
;;; Normally we are only in a hurry when a key is down. As we will come here
;;; after processing, we can cut some cycles by skipping the call to MEMCHK
;;; when a key is down (when we are in a hurry).
;;; This speeds things up by some 30-40 cycles and we still get frequent
;;; calls the MEMCHK. In reality whenever wake up due to I/O event and
;;; after key processing is done.
;;; It is not really that urgent to call MEMCHK all the time as its purpose
;;; is to make a quick memory integrity check and do a MEMORY LOST in case
;;; something is wrong. As this is an unusual case (yes really, despite all
;;; the MEMORY LOSTs you have seen) we can shave some cycles without causing
;;; any problems.
;;;
;;; ----------------------------------------------------------------------

              chkkb
              goc     10$           ; key is down, find active handler

              st=c                  ; put up SS0

3$:           ldi     8             ; I/O service
              gosub   ROMCHK        ; needs chip 0,SS0,hex,P selected
              ?s2=1                 ; I/O flag?
              goc     3$            ; yes, keep going

;;; No key or I/O to process, inspect various flags that should prevent
;;; us from showing an alternative display.
              ?s5=1                 ; message flag?
              goc     4$            ; yes, leave display alone
              c=regn 14
              c=c+c   xs
              c=c+c   xs
              goc     4$            ; data entry in progress
              c=c+c   xs
              goc     4$            ; partial key in progress

              gosub   doDisplay     ; we may want to override the display

4$:           gosub   MEMCHK        ; check memory integrity
              golong  0x18c         ; go to light sleep

5$:           golong  0x1a6         ; WKUP20, ordinary check key pressed

;;; Here we scan for our own buffer to see if there is an alternative
;;; keyboard handler to use.
              .extern topShell, nextShell, keyHandler
10$:          c=c+c   xs
              c=c+c   xs
              goc     5$            ; data entry in progress
              c=c+c   xs
              goc     5$            ; partial key in progress

              gosub   topShell
              goto    5$            ; (P+1) no shell, ordinary keyboard logic

14$:          gosub   keyHandler    ; invoke key handler
              gosub   nextShell     ; did not want to deal with it, step to
                                    ; next shell
              goto    5$            ; (P+1) out of shells
              goto    14$           ; (P+2) inspect next shell


;;; ----------------------------------------------------------------------
;;;
;;; deepWake - deep sleep wake up
;;;
;;; Release all Shells, application ROMs need to reclaim them using their
;;; deep wake poll vectors.
;;;
;;; ----------------------------------------------------------------------

              .extern releaseShells
deepWake:     gosub   releaseShells
              golong  DSWKUP+2



;;; **********************************************************************
;;;
;;; In this section we store some smaller routines that we do not expect
;;; ever need to be changed. We save a relay jump by doing this.
;;;
;;; **********************************************************************

              .section fixedEntries

;;; **********************************************************************
;;;
;;; RTNP2 - return to P+2
;;; dropRTNP2 - drop stack and return to P+2
;;;
;;; These routines are useful for returning skipping past the instruction
;;; just after the gosub.
;;;
;;; dropRTNP2 is meant to be used with generic extensions that wants to
;;;  return back to the original caller (instead of exiting back to
;;;  mainframe). It simply drops the return address (which points back to
;;;  extensionHandler) and returns to (P+2) of the original generic
;;;  extension caller.
;;;
;;; Uses: C[6:3]
;;;
;;; **********************************************************************

              .public dropRTNP2, RTNP2
dropRTNP2:    spopnd
RTNP2:        c=stk
              c=c+1   m
              gotoc

;;; **********************************************************************
;;;
;;; noRoom - show NO ROOM error
;;; displayError, errMessl, errExit - error support routines
;;;
;;; **********************************************************************

              .public noRoom
noRoom:       gosub   errMessl
              .messl  "NO ROOM"
              goto    errExit

              .public displayError, errMessl, errExit
displayError: gosub   MESSL
              .messl  " ERR"
errMessl:     gosub   LEFTJ
              s8=     1
              gosub   MSG105
              golong  ERR110
errExit:      gosub   ERRSUB
              gosub   CLLCDE
              golong  MESSL




;;; **********************************************************************
;;;
;;; Entry points intended for application modules.
;;;
;;; Here we use a jump table to allow the internal code to be reorganized
;;; without altering the entry points. Traditionally, the HP-41 mainframe
;;; relied on jumping into the code and not altering it too much.
;;; However, as is evident by the HP-41CX, it can start to get messy when
;;; there is a need for changes.
;;; The changes in HP-41CX were actually quite few, the expectations here
;;; is that there will be quite a lot more changes as this code is not
;;; written for a particular release deadline, but rather something that
;;; will evolve a bit over time.
;;; To make it easier to make changes, and entry point table is used.
;;;
;;; **********************************************************************

              .section entry
              .extern activateShell, exitShell, reclaimShell
              .extern chkbuf, getbuf, openSpace
              .extern findKAR2, stepKAR

              golong  activateShell
              golong  exitShell
              golong  reclaimShell
              golong  chkbuf
              golong  getbuf
              golong  openSpace
              golong  findKAR2
              golong  stepKAR
