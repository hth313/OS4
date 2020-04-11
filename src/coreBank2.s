;;; ----------------------------------------------------------------------
;;;
;;; Main take over entry point at address 0x4000, in case bank 2
;;; is left enabled by accident.
;;;
;;; ----------------------------------------------------------------------

              .section Header4_2
              .extern patch11_2
              rst     kb            ; these three instructions
              chk kb                ; necessary because of
              sethex                ; problems with CPU wakeup
              goto    10$           ; 2 instruction corresponding to the LDI
5$:           enrom1                ; in bank 1, then fall into it

10$:          ldi     0x2fd         ; load constant
              goto    5$

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

              .public RTNP3_B2
RTNP3_B2:     c=stk
              c=c+1   m
              goto    jumpP1_B2

;;; **********************************************************************
;;;
;;; gotoc_B1 - jump indirectly into bank 2 from bank 1
;;;
;;; In: C[6:3] = address in bank 1
;;;
;;; **********************************************************************

              .section code1
              .shadow jumpP0_B2 - 1
              .public gotoc_B1
gotoc_B1:     enrom2

;;; **********************************************************************
;;;
;;; systemBuffer - locate the system buffer, number 15
;;; findBuffer - locate buffer with ID in C.X
;;;
;;; NOTE: This is a duplicate routine in bank 2, see buffer.s
;;;
;;; If not found, return to (P+1)
;;; If found, return to (P+2) with:
;;;   A.X = address of buffer start register
;;;   DADD = first address of buffer
;;;   C[13] part of buffer header incremented
;;;   C[12:7] = part of buffer header
;;;   C[2:0] = part of buffer header
;;; Uses: A[12], A.X, C, B.X, active PT=12, DADD, +0 sub levels
;;;
;;; Note: For findBuffer, buffer number in C[0] and C[2:1] must be zero!!!
;;;       Use 'ldi' or 'c=0 x' to ensure that.
;;;
;;; This routine is called at every light sleep wake up, so it has to
;;; be fast.
;;;
;;; Typical execution time (here) is:
;;;
;;;   14 + KARs * 11 + otherBufs * 16 + 16 if found
;;;
;;; So for 8 assignments and skipping 2 buffers, it would take 106 cycles
;;; or 16ms on a standard HP-41.
;;;
;;; **********************************************************************

              .section code2, reorder
              .public systemBuffer_B2, findBuffer_B2
systemBuffer_B2:
              ldi     15
findBuffer_B2:
              dadd=c                ; select chip 0
              pt=     12
              rcr     2
              ldi     0xc0 - 1
              a=c     pt            ; A[12] = desired buffer,
              a=c     x             ; A.X = start address - 1
                                    ; (avoid clobbering whole A)
              c=regn  c
              bcex    x             ; B.X= chain head address

1$:           a=a+1   x             ; start of search loop
2$:           ?a<b    x             ; have we reached chainhead?
              rtnnc                 ; yes, return to (P+1), not found
              acex    x             ; no, select and load register
              dadd=c
              acex    x
              c=data                ; read next register
              ?c#0                  ; if it is empty, then we reached end
              rtnnc                 ; of buffer area, return to not found
                                    ; location
              c=c+1   s             ; is it a key assignment register
                                    ; (KAR)?
              goc     1$            ; yes, move to next register
              ?a#c    pt            ; no, must be a buffer, have we found
                                    ; the buffer we are searching for?
              gonc    toRTNP2_B2    ; yes, return to (P+2)
              rcr     10            ; wrong buffer, skip to next
              c=0     xs
              a=a+c   x
              goto    2$

              .public ensureSystemBuffer_B2, ensureBuffer_B2
ensureSystemBuffer_B2:
              ldi     15
ensureBuffer_B2:
              gosub   findBuffer_B2
              goto    10$           ; (P+1) need to create it
              goto    toRTNP2_B2    ; (P+2) already exists
10$:          ?a<b    x             ; have we reched chainhead?
              rtnnc                 ; yes, we are out of space
              c=0                   ; build buffer header
              c=c+1   s             ; 100000000...
              acex    pt            ; 1b0000000... (where b is buffer number)
              pt=     10
              lc      1             ; 1b0100000...
              data=c
toRTNP2_B2:   golong  RTNP2_B2

;;; Reserve some words for NoV-64
              .section NOV64_B2
              .con    0,0,0,0,0,0
