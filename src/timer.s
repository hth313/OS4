#include "mainframe.h"
#include "time.h"

#define IN_OS4
#include "OS4.h"

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
;;;     C.X - zero means a single timeout
;;;           non-zero means a periodic timeout for animation
;;; Out: Returns to (P+1) if the timer does not exist
;;;      Returns to (P+2) if the timer exists and was initialized,
;;;          timer is now armed for a timeout.
;;;          DADD - system buffer header
;;;
;;; Uses: A, C, B, ST, DADD, PFAD, +1 sub levels
;;;
;;; **********************************************************************

              .section code, reorder
              .public setTimeout
              .extern sysbuf, RTNP2
setTimeout:   bcex                  ; B= timeout
              ldi     26            ; Time module XROM number
              a=c     x
              pt=     6
              lc      5
              c=0     wpt           ; 5000
              cxisa
              ?a#c    x             ; XROM 26 there?
              rtnc                  ; no
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
              gosub   sysbuf
              goto    clearTimeout  ; (P+1) no system buffer
              c=data                ; set Flag_IntervalTimer
              cstex
              st=1    Flag_IntervalTimer
              cstex
              data=c
              golong  RTNP2         ; success

;;; **********************************************************************
;;;
;;; clearTimeout - disable the time out
;;;
;;; Uses: C.X, DADD, PFAD, +1 sub levels
;;;
;;; **********************************************************************

              .public clearTimeout
clearTimeout: gosub   ENTMR
              stpint                ; stop interval timer
              gosub   sysbuf
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
;;; If not doing partial keys, we send out a notification.
;;;
;;; **********************************************************************

              .public checkTimeout
              .extern noTimeout, topShell, jumpC5
checkTimeout: gosub   sysbuf
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
              gosub   LDSST0
              c=c+c   xs
              c=c+c   xs
              c=c+c   xs            ; partial key in progress?
              gonc    10$           ; no
              a=0     s
              a=a+1   s             ; A.S= non-zero to indicate a timeout
              rtn                   ; return to backarrow key press entry
                                    ; which normally have A.S=0
10$:          gosub   topShell
              goto    50$
              goto    50$
              ?s9=1                 ; did we find an applicaton?
              gonc    50$           ; no
              acex    m
              c=c+1   m
              gosub   jumpC5        ; call timeout vector (if it exists)

50$:          gosub   LDSST0
              golong  noTimeout
