#include "OS4.h"
#include "mainframe.h"

              .public CNTDOWN
              .section PlayCode
toNoRoom:     golong  noRoom
              .name   "CNTDOWN"
CNTDOWN:      ldi     .low12 countShell
              gosub   activateShell
              goto    toNoRoom
              gosub   ensureTimer
              c=0
              ldi     0x100         ; repeat once per second
              gosub   setTimeout
              nop                   ; (P+1) checked above that timer is present
              c=0     x
              dadd=c
              ldi     10
              regn=c  Q             ; Q= counter

              .align  4
timeout:      c=regn  Q
              pt=     13
              lc      2             ; 2 digits
              a=c
              c=c-1   x
              goc    done
              regn=c  Q
              gosub   STMSGF
              gosub   CLLCDE
              gosub   GENNUM
              gosub   ENCP00
              golong  NFRC

done:         gosub   CLLCDE
              gosub   MESSL
              .messl  "LIFTOFF"
              gosub   clearTimeout
              gosub   exitTransientApp
              golong  XNFRC

              .section CountShell, rodata
              .align  4
countShell:   .con    TransAppShell
              .con    0                    ; no display handler defined
              .con    .low12 countKeypress ; standard keys
              .con    .low12 countKeypress ; user keys
              .con    .low12 countKeypress ; alpha keys, use default
              .con    .low12 countName
              .con    .low12 timeout       ; timeout handler

              .section PlayCode
              .align  4
countName:    .messl  "COUNTER"

              .section PlayCode
              .align  4
countKeypress:
              gosub   clearTimeout
              gosub   exitTransientApp
              golong  NFRKB
