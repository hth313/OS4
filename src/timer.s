#include "mainframe.h"
#include "mainframe_cx.h"
#include "time.h"

#define IN_OS4
#include "OS4.h"

;;; setTimeout docstart
;;; **********************************************************************
;;;
;;; setTimeout - set a time out
;;;
;;; This borrows the interval timer in the Time module which is normally
;;; used for the clock display. Here we allow it to be used as a timeout
;;; intended for transient shells.
;;; The idea is that it can be used for some query for input and timeout
;;; if nothing was keyed in a given time or for animation, i.e. a blinking
;;; cursor or field.
;;;
;;; In: C[4:0] - timeout in hundreds of seconds, BCD coded
;;; Out: Returns to (P+1) if the timer does not exist
;;;      Returns to (P+2) if the timer exists and was initialized,
;;;          timer is now armed for a timeout.
;;;          DADD - system buffer header
;;;
;;; Uses: A, C, B, ST, DADD, PFAD, +1 sub levels
;;;
;;; **********************************************************************
;;; setTimeout docend

              .section code, reorder
              .public setTimeout
              .extern hasTimer, systemBuffer, RTNP2
setTimeout:   bcex                  ; B= timeout
              gosub   hasTimer      ; do we have a timer chip?
              rtn                   ; no
              gosub   ENTMR         ; yes, enable timer chip
              a=0
              setdec
              a=a-1   m             ; A= 09999999999000
              sethex
              pt=b                  ; read alarm B
              rdalm                 ; this is the warm start constant
              ?a#c                  ; warm start constant correct?
              rtnc                  ; no, assume no timer chip there

              rdscr
              st=c
              ?s4=1                 ; doing clock display?
              rtnc                  ; yes (should not happen)

              c=b
              wsint                 ; write & start interval timer
              gosub   systemBuffer
              goto    clearTimeout  ; (P+1) no system buffer
              c=data                ; set Flag_IntervalTimer, to indicate
                                    ;  we are borrowing it
              cstex
              st=1    Flag_IntervalTimer
              cstex
              data=c
              golong  RTNP2         ; success

;;; clearTimeout docstart
;;; **********************************************************************
;;;
;;; clearTimeout - disable the time out
;;;
;;; Uses: C.X, DADD, PFAD, +1 sub levels
;;;
;;; **********************************************************************
;;; clearTimeout docend

              .public clearTimeout
clearTimeout: gosub   ENTMR
              stpint                ; stop interval timer
              gosub   systemBuffer
              rtn
              c=data                ; read buffer header
              cstex                 ; clear Flag_IntervalTimer
              st=0    Flag_IntervalTimer
              cstex
              data=c
              rtn

;;; **********************************************************************
;;;
;;; checkTimeout - check for a potential timeout
;;;
;;; The light sleep logic comes here when some peripheral wants service.
;;; We check for an interval timer timeout and if have it in use.
;;; If doing partial key sequence, return to the backarrow entry point
;;; with A.S non-zero to indicate a timeout.
;;; If not doing partial keys, find active application and invoke its
;;; timeout vector.
;;;
;;; **********************************************************************

              .public checkTimeout
              .extern noTimeout, topShell, jumpC6
checkTimeout: gosub   systemBuffer
              goto    50$           ; (P+1) no system buffer
              c=data                ; read buffer header
              cstex
              ?st=1   Flag_IntervalTimer
              gonc    50$           ; not using interval timer
              gosub   ENTMR         ; enable timer chip
              alarm?                ; some alarm condition?
              gonc    50$           ; no
              rdsts                 ; C= hardware status
              cstex
              ?s4=1                 ; interval timer timeout?
              gonc    50$           ; no
              s4=0                  ; yes, reset it to make it repeat
              cstex
              wrsts
              gosub   LDSST0
              c=c+c   xs
              c=c+c   xs
              c=c+c   xs            ; partial key in progress?
              gonc    10$           ; no
              a=0     s             ; yes, notify partial key about timeout
              a=a+1   s             ; A.S= non-zero to indicate a timeout
              rtn                   ; return to backarrow key press entry
                                    ; which normally have A.S=0
10$:          gosub   topShell
              goto    50$
              goto    50$
              ?s9=1                 ; did we find an applicaton?
              gonc    50$           ; no
              gosub   LDSST0
              acex    m
              gosub   jumpC6        ; call timeout vector (if it exists)

50$:          gosub   LDSST0
              golong  noTimeout

;;; **********************************************************************
;;;
;;; clearClock - clear clock display mode
;;;
;;; This routines checks for presence of a time module and clear any
;;; clock mode.
;;; We need to help the time module as it inspects some flags to sense
;;; if a key was pressed and this does not work properly in some shell
;;; modes as the message flag is set during normal display.
;;; Thus, the time module may not understand a key was pressed and will
;;; not leave the clock mode.
;;; To work around this problem, call this routine on key down that is
;;; processed by a shell.
;;;
;;; In: Nothing
;;; Out: Chip 0 selected, SS0 up
;;; Uses: C, B.M, A.X, +1 sub levels
;;;
;;; **********************************************************************

              .section code, reorder
              .public clearClock
clearClock:   ldi     26            ; Time module XROM number
              a=c     x
              pt=     6
              lc      5
              c=0     wpt           ; 5000
              cxisa
              ?a#c    x             ; XROM 26 there?
              goc     10$           ; no
              gosub   ENTMR         ; enable timer
              pt=b
              rdscr
              cstex                 ; put up software status
              gosub   CLRALS
10$:          golong  LDSST0        ; enable chip 0, put up SS0
