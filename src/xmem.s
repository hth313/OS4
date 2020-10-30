#define IN_OS4
#include "OS4.h"
#include "mainframe.h"
#include "mainframe_cx.h"


;;; getXAdr docstart
;;; **********************************************************************
;;;
;;; getXAdr - get the X memory address of given logical register
;;;
;;; Convert a register number to a physical address based on the active
;;; data file. If running, we try to speed it up using the cache in
;;; register 13. The first call during execution will set up the
;;; cache. If not running, we simply ignore the status of the cache
;;; and do the real lookup. This adds safety in case the some operation
;;; have invalidated the cache. When running we assume the program knows
;;; what it is doing and invalidates the cache explicitly whenever
;;; needed (after an operation that may shuffle around registers in the
;;; file system).
;;;
;;; In: C.X= logical register
;;; Out: A.X = physical register
;;; Uses: A, B, C, M, N, Q, PT, S0-7, DADD, +3 sub levels
;;;
;;; **********************************************************************
;;; getXAdr docend

              .public getXAdr
              .section code, reorder
              .extern ensure41CX
getXAdr:      m=c                   ; M.X= register number
              gosub   ensure41CX
              s0=0
              gosub   FLSHAP        ; locate current file
              ?s0=1                 ; file found?
              golnc   FLNOFN        ; no -> "FL NOT FOUND"
              c=m                   ; C.X= register number
              a=c     x             ; A.X= register
              c=n                   ; C= file header information
              c=c-1   s             ; inspect file type
              c=c-1   s
              ?c#0    s             ; data file?
              golc    FLTPER        ; no, "FL TYPE ERR"
              ?a<c    x             ; in range?
              gonc    ERRNE_J1      ; no
              a=a+1   x             ; step register forward
                                    ;  (to compensate for file header)
              b=a     x             ; B.X= advance (by register + 1)
              rcr     10            ; C.X= address of file header
              a=c     x             ; A.X= address
              a=0     m
              gosub   ADVADR        ; move to desired register
              ?a#0    x             ; check for memory overflow (probably not
              gonc    ERRNE_J1      ;  needed)
              ?s2=1                 ; memory discontinuity?
              rtnnc                 ; no
ERRNE_J1:     golong  ERRNE         ; yes, discontinuity error
