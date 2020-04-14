#include "mainframe.h"
#include "OS4.h"

;;; **********************************************************************
;;;
;;; Poll vectors and identification for bank 2.
;;;
;;; **********************************************************************

              .section PlayTail2
              nop                   ; Pause
              nop                   ; Running
              nop                   ; Wake w/o key
              nop                   ; Powoff
              nop                   ; I/O
              nop                   ; Deep wake-up
              nop                   ; Memory lost
              .con    1             ; A
              .con    '1'           ; 1
              .con    0x20c         ; L (tagged for having banks)
              .con    0x010         ; P (no secondaries,
                                    ;    those are in the primary bank)
              .con    0             ; checksum position

              .section PlayPoll
;;; **********************************************************************
;;;
;;; Poll vectors, module identifier and checksum for primary bank
;;;
;;; **********************************************************************

              nop                   ; Pause
              nop                   ; Running
              nop                   ; Wake w/o key
              nop                   ; Powoff
              nop                   ; I/O
              nop                   ; Deep wake-up
              nop                   ; Memory lost
              .con    1             ; A
              .con    '1'           ; 1
              .con    0x20c         ; L (tagged for having banks)
              .con    0x210         ; P (tagged as having secondaries)
              .con    0             ; checksum position
