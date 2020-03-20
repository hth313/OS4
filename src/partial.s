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
;;; mode and resets flags in the system buffer header related to key
;;; sequence parsing and secondary functions that may have partial key
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
              c=0     s             ; reset highest bit (used for dual
              c=c+1   s             ; semi-merged)
              cstex
              st=0    Flag_SEC_PROXY
              st=0    Flag_Argument
              st=0    Flag_ArgumentDual
              st=0    Flag_SEC_Argument
              cstex
              data=c
10$:          golong  NAME33
