#include "OS4.h"
#include "playInternals.h"

XROMno:       .equ    7

;;; * This is a play-ground ROM used for testing features in OS4.

              .section PlayFAT
              .extern N, I, PV, PMT, FV, TVM, TVMEXIT
              .extern CNTDOWN
              .con    XROMno
              .con    (FatEnd - FatStart) / 2 ; number of entry points
FatStart:
              .fat    PlayHeader
              .fat    Prefix2
              .fat    TVM
              FAT     TVMEXIT
              FAT     N
              FAT     I
              FAT     PV
              FAT     PMT
              FAT     FV
              .fat    CNTDOWN
FatEnd:       .con    0,0

;;; ************************************************************
;;;
;;; ROM header.
;;;
;;; ************************************************************

              .section PlayCode

              .name   "-OS4 PLAY 1A" ; The name of the module
PlayHeader:   gosub   runSecondary  ; Must be first!
              .con    0             ; I am secondary prefix XROM 7,0
              ;; pops return address and never comes back

              .section PlayCode
              .name   "(PLAY2)"     ; short name for prefix function
Prefix2:      gosub   runSecondary  ; Must be first!
              .con    1             ; I am secondary prefix XROM 7,1
              ;; pops return address and never comes back

;;; **********************************************************************
;;;
;;; TVM sparse keyboard definition.
;;;
;;; **********************************************************************

              .section PlayTable, rodata
              .align  4
              .public keyTableTVM
keyTableTVM:  .con    0             ; SIGMA+
              KeyEntry N
              .con    16            ; 1/X
              KeyEntry I
              .con    32            ; SQRT
              KeyEntry PV
              .con    48            ; LOG
              KeyEntry PMT
              .con    64            ; LN
              KeyEntry FV
              .con    31            ; PI
              KeyEntry TVMEXIT
              .con    0x100         ; end of table

;;; **********************************************************************
;;;
;;; Secondary FATs
;;;
;;; **********************************************************************

              .section PlayFC2
              .con    .low12 secondary1 ; Root pointer for secondary FAT headers

;;; * First secondary FAT header, serving bank 1
              .section PlaySecondary1, reorder
              .align  4
secondary1:   .con    .low12 secondary2 ; pointer to next table
              .con    (FAT1End - FAT1Start) / 2
              .con    0             ; prefix XROM (XROM 6,0 - ROM header)
              .con    0             ; start index
              .con    .low12 FAT1Start
              rtn                   ; this one is in bank 1,
                                    ; no need to switch bank

              .section PlaySecondary1, reorder
              .extern FOO
              .align  4
FAT1Start:    .fat    FOO
FAT1End:      .con    0,0

;;; * Second secondary FAT header, serving bank 2

              .section PlaySecondary1, reorder
              .align  4
secondary2:   .con    0             ; no next table
              .con    (FAT2End - FAT2Start) / 2
              .con    1             ; prefix XROM (XROM 6,1 - (BPFX2))
              .con    256           ; start index
              .con    .low12 FAT2Start
              switchBank 2          ; this one is in bank 2
              rtn

              .section PlaySecondary2
              .extern FOO2
              .align  4
FAT2Start:    .fat    FOO2
FAT2End:      .con    0,0

;;; **********************************************************************
;;;
;;; Header for bank 2, just make it look empty in case the bank is
;;; left enabled.
;;;
;;; **********************************************************************

              .section PlayHeader2
              nop
              nop

;;; ----------------------------------------------------------------------
;;;
;;; Bank switchers allow external code to turn on specific banks.
;;;
;;; ----------------------------------------------------------------------

BankSwitchers: .macro
              rtn                   ; not using bank 3
              rtn
              rtn                   ; not using bank 4
              rtn
              enrom1
              rtn
              enrom2
              rtn
              .endm

              .section PlayBankSwitchers1
             BankSwitchers

              .section PlayBankSwitchers2
             BankSwitchers
