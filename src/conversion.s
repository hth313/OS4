#include "mainframe.h"
#include "internals.h"

#define IN_OS4
#include "OS4.h"

;;; CXtoX docstart
;;; **********************************************************************
;;;
;;; CXtoX - convert small binary number to floating point in X
;;;
;;; The final value is recalled to X, hiwch
;;;
;;; In: C[2:0] - binary number
;;; Out: X - floating point number
;;;
;;; **********************************************************************
;;; CXtoX docend

;;; CtoXRcl docstart
;;; **********************************************************************
;;;
;;; CtoXRcl - binary integer to floating point number, use RCL
;;; CtoXDrop - binary integer to floating point number, use DROPST
;;; CtoXFill - binary integer to floating point number, use FILLXL
;;;
;;; The converted binary number is saved in X. The 3 different main
;;; entry points correspond to push value (CtoX), update X after unary
;;; operation (CtoXFill) and update X after binary operation (CtoXDrop).
;;; The two latter also update L.
;;;
;;; In: C - binary integer (all bits)
;;; Out: X - floating point number
;;; Assume: chip 0 selected
;;;
;;; **********************************************************************
;;; CtoXRcl docend

              .public CXtoX, CtoXRcl, CtoXDrop, CtoXFill
              .section code2, reorder

CtoXDrop:     s1=1                  ; Use DROPST
              goto    CtoX10
CtoXFill:     s0=1                  ; Use FILLXL
              goto    CtoX05
CXtoX:        c=0     m
              c=0     s
CtoXRcl:      s0=0                  ; RCL to X
CtoX05:       s1=0
CtoX10:       pt=     13            ; digit counter
              setdec
              m=c                   ; M= number to convert
              clrabc
              n=c                   ; N= 0

10$:          c=m                   ; loop start, get input
              a=0
              a=c     s             ; get next nibble from left side
              rcr     13
              m=c                   ; save input back for next iteration
              acex
              rcr     13            ; C[0]= current nibble
              acex                  ; A[0]= current nibble
              a=a+b                 ; add with zero to convert it to BCD
              c=n
              c=c+c                 ; multiply it with 16 (decimal mode)
              c=c+c
              c=c+c
              c=c+c
              c=c+a
              n=c                   ; N= accumulated mantissa so far
              ?pt=    0             ; have we visited all digits?
              goc     20$           ; yes
              decpt                 ; no
              goto     10$

; BCD mantissa is now in C and N
20$:          a=0     x             ; A.X= 0 (exponent)
              rcr     -3            ; C.M= right justified mantissa
              c=0     x
              c=0     s
              ?c#0    m             ; check for zero mantissa
              gonc    40$           ; zero mantissa
25$:          rcr     -1            ; left shift mantissa to left align it
              ?c#0    s             ; did we get a digit?
              goc     30$           ; yes
              a=a+1   x             ; no, increment exponent and loop over
              goto    25$
30$:          rcr     1             ; shift right one digit to get the
                                    ; final left justified mantissa in C
              acex    x             ; get exponent
              c=-c-1  pt            ; fix exponent
40$:          bcex                  ; move result to B for RCL/DROPST
              sethex                ; needed if we have a printer connected
              switchBank 1
              ?s1=1
              golc    DROPST
              ?s0=1
              golc    FILLXL
              golong  RCL
