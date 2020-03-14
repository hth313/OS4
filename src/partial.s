#include "mainframe.h"

#define IN_OS4
#include "OS4.h"


;;; **********************************************************************
;;;
;;; XABTSEQ - abort partial key sequence
;;;
;;; This function terminates partial key sequence, typically when pressing
;;; backarrow to get out of it.
;;; Compared to the ABTSEQ routine in mainframe, this will also clear alpha
;;; mode and properly reset the Flag_SEC_PROXY in the system buffer header
;;; which should be done for secondary functions that have partial key
;;; sequence handling (it does not harm to do it for all partial key
;;; handling).
;;;
;;; **********************************************************************

              .section code, reorder
              .public XABTSEQ
              .extern systemBuffer
XABTSEQ:      gosub   ENCP00
              gosub   systemBuffer
              goto    10$
              c=data
              cstex
              st=0    Flag_SEC_PROXY
              cstex
              data=c
10$:          golong  NAME33
