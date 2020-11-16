#include "mainframe.h"
#include "internals.h"

#define IN_OS4
#include "OS4.h"

;;; getIndexX docstart
;;; **********************************************************************
;;;
;;; getIndexX - get index from X in form RRR.BBBEEE
;;;
;;; In: if S5=1, the index is a register block specification
;;;     if S5=0, otherwise
;;;     if S2=1, will decode X as RRR.BBBXXXXXXXXX
;;;        (if S2=1, entry must be at GTIND2)
;;; Out: if S5=0, then N[2:0]= EEE
;;;                    N[5:3]= reg addr of BBB
;;;                    N[8:6]= reg addr of RRR
;;;      if S5=1, then N[2:0]= reg addr of BBB
;;;                    N[5:3]= reg addr of RRR
;;;      if S2=1, then N[5:3]= RRR
;;;                    N[2:0]= BBB
;;; Uses: A, B, C, N, S2, S3, PT   +2 sub level
;;;
;;; **********************************************************************
;;; getIndexX docend

              .section code2
              .public getIndexX
getIndexX:    s2=     0             ; decode X as RRR.BBBEEE
GTIND2:       c=0
              dadd=c
              c=regn  3
              bcex
              c=b
              gosub   LB_325C       ; get binary of int(X)
              n=c
              s3=     0
GTIX10:       gosub   GTFRAB        ; get first 3 frac digit of X
              a=c     x
              c=n
              rcr     11
              acex    x
              n=c
              ?s3=1                 ; get second 3 digit of frac(X) yet ?
              goc     GTIX20        ; yes
              s3=     1
              goto    GTIX10
GTIX20:       ?s2=1                 ; for the function "STOFLAG" ?
              rtn c                 ;  yes
              c=regn  13            ; reg0 to A.X
              rcr     3
              a=c     x
              c=n                   ; convert register indices to
              rcr     3             ;  absolute address and
              c=a+c   x             ;  check that they exist
              rcr     3
              c=a+c   x
              ?s5=1                 ; for the function "REGMOVE"?
              gonc    GTIX30        ; yes
              gosub   CHKADR
              rcr     11
              n=c
              gosub   CHKADR
              goto    GTIX40
GTIX30:       rcr     8
              n=c
GTIX40:       golong  enableBank1   ; return

;;; **********************************************************************
;;;
;;;  GTFRA - get first 3 fraction digits of a number
;;;  GTFRAB - save as "GTFRA" except the input number is in B
;;;
;;;  In:: A = the number
;;;  Out: C.X = binary of the fraction digits
;;;       B = fraction of the number times 1000
;;;  Uses: A, B, C, S3  +1 sub level
;;;
;;; **********************************************************************

              .section code2
GTFRAB:       abex
GTFRA:        setdec
              ?a#0    xs            ;  the number < 1 ?
              goc     GTFR20        ; yes
GTFR10:       asl     m
              a=a-1   x
              gonc    GTFR10
GTFR20:       ldi     3
              ?s2=1                 ; decode  as RRR.B ?
              gonc    GTFR30        ; no
              c=c-1   x
              s3=     1             ; loop only once in GTIND2
GTFR30:       a=a+c   x             ; multiply by 1000 (or 100)
              b=a
              acex
              sethex
              golong  BCDBIN

              .section code2
LB_325C:      c=c-1   s
              c=c-1   s
              golc    ERRAD
              sethex
              a=c     x
              c=0     s
              c=0     x
              ?c#0    m
              rtn nc
              ?a#0    xs
              rtn c
              rcr     12
              a=a-1   x
              goc     10$
              rcr     13
              a=a-1   x
              goc     10$
              rcr     13
              a=a-1   x
              golnc   ERRDE
10$:          golong  GOTINT
