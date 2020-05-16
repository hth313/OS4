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
;;; The state is saved in the Q register while stopped.
;;;
;;; Alternative entry point:
;;; catalogWithSize - same as catalog, but useful when the state needs
;;;   more than one register. Put the needed size in C.X which will
;;;   allocate the scratch area of this size. The N register is still
;;;   a single state register while running and it is saved in the
;;;   Q register. The scratch area is allocated up front and will
;;;   result in NO ROOM if not enough registers are available.
;;;
;;; The calling sequence is:
;;;           ldi     .low12 catalogDescriptor
;;;           gosub   catalog
;;;           ...
;;;           .align  4
;;;   catalogDescriptor:
;;;           goto    .low12 prepare
;;;           goto    .low12 step
;;;           goto    .low12 back
;;;           .con    .low12 transientShell
;;;           bankSwitcher code
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
              .extern unpack, unpack0, unpack1, unpack2, unpack4
              .extern jumpP2
              .extern hasActiveTransientApp
              .extern exitTransientApp, keyDispatch, activateShell10
              .extern systemBuffer, resetBank
toNoRoom:     golong  noRoom
catEmpty:     c=stk
              gosub   resetBank
              gosub   errorMessage
              .messl  "CAT EMPTY"
              golong  errorExit

catalogWithSize:
              n=c
              gosub   allocScratch  ; make room for state while stopped
              goto    toNoRoom
              c=n
catalog:      c=stk                 ; keep catalog descriptor on stack
              gosub   unpack
              stk=c
              a=c     m
              gosub   unpack0
              gosub   switchBankAndCallC ; prepare
              goto    catEmpty
catEntry:     c=stk
              stk=c
              gosub   resetBank
              gosub   ENCP00
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
              golong  catalogReturn ; (P+2) yes

noRoom10:     gosub   exitTransientApp
              goto    toNoRoom

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
              a=c     m
              gosub   unpack1
              gosub   switchBankAndCallC ; step
              goto    catalogEnd
              goto    catEntry

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

;;; catalogEnd docstart
;;; **********************************************************************
;;;
;;; catalogEnd - terminate the catalog
;;;
;;; This routine terminates the catalog by removing the transient
;;; application and doing usual catalog termination in mainframe.
;;; Does not return.
;;;
;;; The calling sequence is:
;;;           gosub catalogEnd
;;;
;;; **********************************************************************
;;; catalogEnd docend

              .public catalogEnd
catalogEnd:   c=stk
              gosub   resetBank
              gosub   exitTransientApp
              gosub   ENCP00
              golong  QUTCAT

turnOff:      c=stk
              gosub   resetBank
              golong  OFF

stopCatalog:  c=0     x
              dadd=c
              c=stk
              regn=c  Q             ; Q= catalog descriptor
                                    ; activateShell10 takes +3 levels !!
              c=c+1   m
              c=c+1   m
              c=c+1   m
              cxisa
              gosub   activateShell10
              goto    noRoom10
              c=0     x
              dadd=c
              c=regn  Q
              stk=c
;;; fall into catalogReturn

;;; catalogReturn docstart
;;; **********************************************************************
;;;
;;; catalogReturn - enter catalog with an entry to display
;;;
;;; This routine should be called stopped and some catalog specific
;;; action has been done, which resulted in setting a display and we
;;; want to dispatch on the next key.
;;;
;;; The calling sequence is:
;;;           gosub catalogDisplay
;;;
;;; **********************************************************************
;;; catalogReturn docend

              .public catalogReturn
catalogReturn: c=stk
              gosub   resetBank
              gosub   ENCP00
              c=n
              regn=c  Q             ; save state in Q
              gosub   STMSGF        ; set message flag
              golong  NFRKB         ; give control back to OS

;;; catalogStep docstart
;;; **********************************************************************
;;;
;;; catalogStep - handle catalog step
;;;
;;; This routine should be called from the transient application handling
;;; key input for the catalog. It steps to the next entry or ends the
;;; catalog if stepping outside it.
;;;
;;; The calling sequence is:
;;;           ldi   .low12 catalogDescriptor
;;;           gosub catalogStep
;;;
;;; **********************************************************************
;;; catalogStep docend

              .public catalogStep
catalogStep:  a=c     x
              c=regn  Q             ; bring state back
              n=c
              acex    x             ; C.X= packed pointer
              c=stk                 ; C[6]= page
              gosub   unpack
              stk=c
              a=c     m
              gosub   unpack1
              gosub   switchBankAndCallC ; step
              goto    catalogEnd    ; nothing more
              goto    catalogReturn

;;; catalogBack docstart
;;; **********************************************************************
;;;
;;; catalogBack - handle catalog step back
;;;
;;; This routine should be called from the transient application handling
;;; key input for the catalog. It steps to the next entry or ends the
;;; catalog if stepping outside it.
;;;
;;; The calling sequence is:
;;;           ldi   .low12 catalogDescriptor
;;;           gosub catalogBack
;;;
;;; **********************************************************************
;;; catalogBack docend

              .public catalogBack
catalogBack:  a=c     x
              c=regn  Q             ; bring state back
              n=c
              acex    x             ; C.X= packed pointer
              c=stk                 ; C[6]= page
              gosub   unpack
              stk=c
              a=c     m
              gosub   unpack2
              gosub   switchBankAndCallC ; back step
              goto    10$           ; at first entry
              goto    catalogReturn
10$:          gosub   BLINK
              goto    catalogReturn

;;; catalogRun docstart
;;; **********************************************************************
;;;
;;; catalogRun - start running the catalog again
;;;
;;; This routine should be called when the R/S key is pressed while
;;; catalog is stopped. It startd running the catalog from the current
;;; position.
;;;
;;; The calling sequence is:
;;;           ldi   .low12 catalogDescriptor
;;;           gosub catalogRun
;;;
;;; **********************************************************************
;;; catalogRun docend

              .public catalogRun
              .extern unpack
catalogRun:   a=c     x
              acex    x             ; C.X= packed pointer
              c=stk                 ; C[6]= page
              gosub   unpack
              n=c
              gosub   exitTransientApp
              gosub   RSTKB
              c=0     x
              dadd=c
              c=regn  Q             ; bring state back
              cnex
              stk=c
              golong  step

;;; **********************************************************************
;;;
;;; switchBankAndCallC - switch bank and call routine
;;;
;;; Used to make calls to bank switch entries in the catalog descriptor.
;;;
;;; In: A[6:3] - catalog descriptor
;;;     C[6:3] - the routine to call
;;;
;;; Out: depends on the called routine
;;;      returns with the bank still selected
;;;
;;; **********************************************************************

switchBankAndCallC:
              acex    m
              c=c+1   m
              c=c+1   m
              gosub   jumpP2        ; bank switch
              acex    m
              gotoc                 ; call the routine
