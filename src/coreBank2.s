;;; **********************************************************************
;;;
;;; Core routines for bank 2.
;;;
;;; These duplicates some routines in bank 1 that are at fixed addresses.
;;; IN bank2 we allow them to be placed anywhere as they are only for
;;; internal use.
;;;
;;; **********************************************************************

              .section code2
              .public RTNP2_B2, jumpP1_B2, jumpP0_B2
RTNP2_B2:     c=stk
jumpP1_B2:    c=c+1   m
jumpP0_B2:    gotoc

              .public unpack_B2, unpack0_B2, unpack1_B2, unpack2_B2, unpack3_B2, unpack4_B2
unpack4_B2:   c=c+1   m
unpack3_B2:   c=c+1   m
unpack2_B2:   c=c+1   m
unpack1_B2:   c=c+1   m
unpack0_B2:   cxisa
unpack_B2:    csr     m
              csr     m
              csr     m
              c=c+c   x
              c=c+c   x
              rcr     -3
              rtn
