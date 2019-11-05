#define IN_OS4
#include "OS4.h"
#include "mainframe.i"
#include "mainframe_cx.i"

;;; **********************************************************************
;;;
;;; logoutXMem - log out from the x memory storage system
;;;
;;; This should be called by any module making use of the X-memory for
;;; random access from its power off poll vector.
;;;
;;; Uses: B
;;; Assume: chip 0 selected
;;;
;;; **********************************************************************

              .public logoutXMem, restore169
logoutXMem:
restore169:   bcex                  ; preserve C
              c=regn  13
              rcr     6
              ldi     0x169
              rcr     -6
              regn=c  13
              bcex
              rtn


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
;;; Out: Returns to (P+2) with
;;;        A.X = physical register
;;;      Returns to (P+1) if anything is wrong, and there can be numerous
;;;      reasons: no active file, active file is not a data file, register
;;;               is out of range, etc
;;; Uses: A, B, C, M, N, Q, PT, S0-7, DADD, +3 sub levels
;;;
;;; **********************************************************************

              .public getXAdr
getXAdr:      ?s13=1                ; running?
              gonc    2$            ; no, always search for file
              n=c                   ; N.X= logical register
              c=0     x
              dadd=c
              c=regn  13
              rcr     6
              c=c-1   xs
              goc     9$            ; cache= 0XX (valid)
              c=c-1   xs
              gonc    8$            ; cache valid (>1FF)
2$:           regn=c  Q             ; save logical register in Q
              s0=0                  ; cache invalid
              gosub   FLSHAP        ; locate current file
              ?s0=1
              golnc   FLNOFN        ; "FL NOT FOUND"
              c=n                   ; C=file header
              c=c-1   s             ; inspect file type
              c=c-1   s
              ?c#0    s             ; data file?
              golc    FLTPER        ; no, "FL TYPE ERR"

              rcr     10            ; C.X= address of file header
              bcex    x             ; B.X= address of file header
              c=0     x             ; select chip 0
              dadd=c
              c=regn  13
              rcr     6
              c=b     x             ; set cache
              rcr     -6
              regn=c  13
              c=regn  Q             ; C.X= logical register
              n=c
              goto    10$

8$:           c=c+1   xs            ; restore cache
9$:           c=c+1   xs
              bcex    x
10$:                                ; B.X= address of second header
              c=b     x             ; C.X= address of second header
              dadd=c
              c=data                ; read second header register
              a=c     x             ; A.X= file size
              c=n                   ; C.X= logical register
              c=c+1   x             ; C.X= steps to advance
              goc     ERRNE_J1      ; address overflow
              ?a<c    x             ; requested register in range?
              goc     ERRNE_J1      ; no
              bcex    x             ; B.X= advance
              a=c     x             ; A.X= address
              a=0     m
              gosub   ADVADR        ; move to desired register
              ?a#0    x
              gonc    ERRNE_J1      ; memory overflow
              ?s2=1
              rtnnc
ERRNE_J1:     golong  ERRNE         ; discontinuity error
