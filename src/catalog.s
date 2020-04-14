#include "mainframe.h"

#define IN_OS4
#include "OS4.h"
#include "internals.h"

;;; catalog docstart
;;; **********************************************************************
;;;
;;; catalog - generic catalog support
;;;
;;; Assume a single register state that is held in N while running.
;;; The state is saved in the scratch area while stopped. This area is
;;; allocated up front.
;;;
;;; The calling sequence is:
;;;           gosub   catalog
;;;           goto    prepare
;;;           goto    step
;;;           .con    low12 transientShell
;;;
;;; prepare - Show first line, N=state, return to (P+2).
;;;           If catalog is empty, return to (P+1)
;;; step - Step to next entry, show line, N=updated state, return to (P+2)
;;;           If nothing more, return to (P+1)
;;;
;;; In: Nothing
;;; Out: Nothing (returns to mainframe when done)
;;;
;;; **********************************************************************
;;; catalog docend

              .section code
              .public catalog, catalogWithSize, catEmpty
              .extern noRoom, errorMessage, errorExit, allocScratch
              .extern jumpC0, jumpC1, hasActiveTransientApp
              .extern exitTransientApp, keyDispatch, activateShell
              .extern scratchArea
toNoRoom:     golong  noRoom
catEmpty:     gosub   errorMessage
              .messl  "CAT EMPTY"
              golong  errorExit

catalog:      ldi     1             ; request one scratch register
catalogWithSize:
              gosub   allocScratch  ; make room for state while stopped
              goto    toNoRoom
              c=stk
              spopnd                ; drop second return addresses
              spopnd
              stk=c
              gosub   jumpC0        ; call prepare
              goto    catEmpty
catEntry:     gosub   ENCP00
              c=regn  8
              c=0     s             ; just say it is not CAT 1
              regn=c  8
              c=n
              m=c                   ; M= state
              gosub   PRT12         ; send LCD to printer
              c=m
              n=c                   ; N= state

              gosub   hasActiveTransientApp
              goto    delay         ; (P+1) no
              goto    return        ; (P+2) yes

              .newt_timing_start
delay:        ldi     1000          ; inner delay counter (goes up)
delay10:      rstkb
              chkkb
              goc     keyDown
              c=c-1   x
              gonc    delay10
              .newt_timing_end

step:         c=stk
              stk=c
              gosub   jumpC1        ; step
              goto    endCatalog
              goto    catEntry

noRoom10:     gosub   exitTransientApp
              goto    toNoRoom

keyDown:      m=c                   ; save delay counters
              ldi     2
              gosub   keyDispatch
              .con    0x18,0x87,0
              goto    turnOff       ; ON
              goto    stopCatalog   ; R/S
              c=m                   ; undefined key, speed up
              a=c     x             ; shave some delay off
              ldi     10
              c=a-c   x
              goc     step
              goto    delay10

endCatalog:   gosub   exitTransientApp
              gosub   ENCP00
              spopnd                ; drop pointer to actual catalog
              golong  QUTCAT

turnOff:      golong  OFF

stopCatalog:  c=stk
              c=c+1   m
              c=c+1   m
              cxisa
              gosub   activateShell
              goto    noRoom10
return:       gosub   scratchArea   ; save state and return to OS
              c=n
              data=c
              gosub   STMSGF        ; set message flag
              golong  NFRKB         ; give control back to OS
