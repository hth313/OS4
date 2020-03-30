;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

#include "mainframe.h"
#include "internals.h"

#define IN_OS4
#include "OS4.h"

CHKCST:       .equlab 0x7cdd

;;; ----------------------------------------------------------------------
;;;
;;; Main take over entry point at address 0x4000.
;;;
;;; ----------------------------------------------------------------------

              .extern systemBuffer, doDisplay, doPRGM, disableOrphanShells

              .section Header4
              rst kb                ; these three instructions
              chk kb                ; necessary because of
              sethex                ; problems with CPU wakeup

              ldi     0x2fd         ; PACH11 (minus call to MEMCHK)
              dadd=c                ; enable nonexistent data chip 2FD
              pfad=c                ; enable display
              flldc                 ; non-destructive read

              c=stk                 ; inspect return address (and drop it)
              rcr     1             ; C.XS= lower nibble
              c=c+c   xs
              goc     deepWake      ; deep wake up

lightWake:    c=0     x
              pfad=c                ; disable LCD
              dadd=c                ; select chip 0

              c=regn  14            ; C= flags
              st=c                  ; put up SS0

;;; ----------------------------------------------------------------------
;;;
;;; Light sleep wake up actually comes here both at wake up and when
;;; going back to light sleep after processing is done.
;;; We are introducing a buffer scan here which gives extra overhead.
;;; Normally we are only in a hurry when a key is down. As we will come here
;;; after processing, we can cut some cycles by skipping the call to MEMCHK
;;; when a key is down (when we are in a hurry).
;;; This speeds things up by some 30-40 cycles and we still get frequent
;;; calls the MEMCHK. In reality whenever wake up due to I/O event and
;;; after key processing is done.
;;; It is not really that urgent to call MEMCHK all the time as its purpose
;;; is to make a quick memory integrity check and do a MEMORY LOST in case
;;; something is wrong. As this is an unusual case (yes really, despite all
;;; the MEMORY LOSTs you think may have seen) we can shave some cycles.
;;;
;;; ----------------------------------------------------------------------

              chk kb
              golc    bufferScan    ; key is down, find active handler

;;; No key down, inspect various flags that should prevent
;;; us from showing an alternative display.
              ?s5=1                 ; message flag?
              goc     checkPause    ; yes, leave display alone
              ?s7=1                 ; alpha mode?
              goc     checkPause    ; yes, leave display alone
              c=regn 14
              c=c+c   xs
              c=c+c   xs
              goc     LocalMEMCHK   ; data entry in progress
              c=c+c   xs
              goc     LocalMEMCHK   ; partial key in progress
              ?s3=1                 ; program mode?
              golc    doPRGM        ; yes, we may need to display certain
                                    ; instructions in a custom way
              gosub   disableOrphanShells
;;; Needed as all sub levels are consumed
              .public disableOrphanShellsDone
disableOrphanShellsDone:
              gosub   doDisplay     ; we may want to override the display

;;; Check for OS4 style pause.
checkPause:   gosub   systemBuffer
              goto    LocalMEMCHK   ; (P+1) no system buffer
              cstex
              ?st=1   Flag_Pause    ; pause flag set?
              golc    pause
              cstex                 ; restore flags
;;; This is a replacement for MEMCHK. It is called whenever we are going
;;; to light sleep.
              .public LocalMEMCHK
LocalMEMCHK:  gosub   MEMCHK

;;; Keep processing I/O and key down before going to light sleep
              .public noTimeout
              .extern checkTimeout
ioLoop:       chk kb                ; check key down while doing I/O
              golc    bufferScan0
              ?f13=1                ; peripheral wants service?
              golc    checkTimeout  ; yes
noTimeout:    ldi     8             ; I/O service
              gosub   ROMCHK        ; needs chip 0,SS0,hex,P selected
              ?s2=1                 ; I/O flag?
              goc     ioLoop        ; yes, keep going

              golong  0x18c         ; go to light sleep

;;; ----------------------------------------------------------------------
;;;
;;; deepWake - deep sleep wake up
;;;
;;; Release all Shells, application ROMs need to reclaim them using their
;;; deep wake poll vectors.
;;;
;;; ----------------------------------------------------------------------

              .extern releaseShells, releaseHostedBuffers
              .newt_timing_start    ; to synchronize NEWT Time clone at start up
deepWake:     disoff                ; get the display to a known
                                    ; state
              gosub   MEMCHK
              chk kb                ; did the ON key wake us up?
              goc     3$            ; yes
              ldi     10            ; no
              gosub   ROMCHK
              .newt_timing_end

              ?s2=1                 ; I/O flag?
              golnc   DRSY50        ; nope - go back to sleep

3$:           c=regn  14
              c=0     x             ; PACH12
              regn=c  14
              gosub   DECMPL
              rcr     6
              cstex                 ; put up SS3
              s1=     0             ; clear catalog flag
              s5=     1             ; set audio enable flag
              s6=     0             ; clear error ignore flag
              s7=     0             ; clear out-of-range flag
              cstex
              rcr     2             ; clear flags 12-23
              c=0     x
              rcr     6
              regn=c  14
              s13=    0             ; clear running flag
              gosub   RSTKB
; * Check for master clear here
              chk kb                ; another key down?
              gonc    5$            ; no
              ldi     0xc3          ; yes. see if it is BKARROW (KC FOR BKARROW)
              a=c     x
              c=keys
              rcr     3
              pt=     1
              ?a#c    wpt
              golnc   WKUP90        ; master clear

5$:           gosub   releaseShells
              goto    10$           ; no system buffer
              acex    x             ; C.X= system header address
              dadd=c
              c=data
;;; Set flags at power on:
;;; Flag_Argument        = 0     no argument handling going on
;;; Flag_ArgumentDual    = 0
;;; Flag_Pause           = 0     no pause
;;; Flag_SEC_PROXY       = 0     no secondary proxy in progress
;;; Flag_OrphanShells    = 1     set Flag_OrphanShells flag to signal that
;;;                              we need to check for orphaned shells
;;;                              when power on processing is done
;;;                              (releaseShells above has already marked
;;;                               it properly)
;;; Flag_DisplayOverride = 0
;;; Flag_SEC_Argument    = 0
;;; Flag_IntervalTimer   = 0
              pt=     1
              lc      0
              lc      4
              data=c
              gosub   releaseHostedBuffers
10$:          golong  WKUP60

;;; ----------------------------------------------------------------------
;;;
;;; fastDigitEntry  - fast additional digit entry handling
;;;
;;; Routine to handle additional digit entry when a digit entry routine finds
;;; that there is another key down. The idea here is to bypass the I/O poll
;;; vector to speed things up.
;;;
;;; ----------------------------------------------------------------------

              .extern topShell, nextShell, keyHandler
bufferScan0:  gosub   LDSST0
fastDigitEntry:
bufferScan:   c=c+c   xs
              c=c+c   xs
              c=c+c   xs
              golc    partialKeyTakeOver ; partial key in progress
              rcr     6             ; check for CATalog flag
              cstex
              ?s1=1                 ; catalog flag set?
              goc     catflag       ; yes, check what key it really is

bufferScan10: pt=     3
              c=keys
              c=c+c   pt            ; OFF key?
              golc    OFF           ; yes
              gosub   topShell
              goto    toWKUP20_SS0  ; (P+1) no buffer, ordinary keyboard logic
              goto    30$           ; (P+2) no shell, ordinary keyboard logic
              gosub   resetFlags    ; (P+3)
14$:          gosub   keyHandler    ; invoke key handler
              gosub   nextShell     ; did not want to deal with it, step to
                                    ; next shell
              goto    toWKUP20_SS0  ; (P+1) no buffer, out of shells
              goto    toWKUP20_SS0  ; (P+2) out of shells
              goto    14$           ; (P+3) inspect next shell

30$:          gosub   resetFlags
toWKUP20_SS0: gosub   LDSST0        ; bring up SS0
              golong  WKUP20        ; ordinary check key pressed

;;; Should really check for reassigned keys here as that is done by the OS!
;;; However, we settle for assuming that we just use default behavior for
;;; now.
catflag:      ldi     0x13          ; keycode for the ENTER key
              a=c     x
              c=keys
              acex    x
              ?a#c    x
              goc     42$           ; not enter
              c=regn  8             ; enter only active in CAT 2!!
              c=c-1   s             ; hack hack, but that is how it is...
              c=c-1   s
              c=c-1   s
              goc     toWKUP20_SS0  ; CAT 2, go and do it
              goto    bufferScan10
42$:          gosub   45$
              .con    0x12          ; SHIFT
              .con    0xc2          ; SST
              .con    0xc3          ; <-
              .con    0x87          ; R/S
              .con    0
45$:          c=stk
46$:          cxisa
              ?c#0    x
              gonc    bufferScan10  ; end of scan, not a catalog key
              ?a#c    x
              gonc    toWKUP20_SS0  ; should be handled by CAT
              c=c+1   m
              goto    46$

resetFlags:   c=b     x
              dadd=c
              c=data
              pt=     0
              g=c                   ; G= previous flags
              cstex
              st=0    Flag_DisplayOverride
              st=0    Flag_Argument
              st=0    Flag_ArgumentDual
              st=0    Flag_SEC_Argument
              st=0    Flag_SEC_PROXY
              cstex
              data=c
              rtn

;;; Inspect if this is an XROM that do partial key takeover
partialKeyTakeOver:
              c=regn  15            ; C[4:3]= ptemp2
              rcr     2
              c=c+c   xs
              goc     noTakeOver    ; already inspected
              c=c+c   xs
              c=c+c   xs
              gonc    noTakeOver    ; no XROM
              ldi     1             ; XROM 0,1 (lower 3 nibbles)
              a=c     x
              c=regn  10            ; read function code
              rcr     1
              ?a#c    x             ; is this XROM 0,1?
              gonc    checkSecondaryTakeOver ; yes
              gosub   GTRMAD
              goto    noTakeOver
              acex
              rcr     -3            ; C[6:3]= XADR
checkXADR:    ldi     FirstGosub(partialKeyEntry)
              a=c     x
              cxisa
              ?c#0    x             ; is it marked as non-programmable?
              goc     10$           ; no
              c=c+1   m             ; yes, step ahead
              cxisa
10$:          ?a#c    x
              goc     noTakeOver
              c=c+1   m
              ldi     SecondGosub(partialKeyEntry)
              a=c     x
              cxisa
              ?a#c    x
              goc     noTakeOver
              spopnd                ; drop NEXT address that we do not need
              c=c+1   m             ; point to takeover vector
              c=c+1   m
              stk=c                 ; push it instead
              c=0                   ; reset the XROM bit in ptemp2 to do this
              pt=     4             ;    only once
              lc      8             ; C= 0x80000 (the XXROM bit)
              a=c
              c=regn  15
              c=a+c
              regn=c  15
noTakeOver:   golong  toWKUP20_SS0

;;; * Check for partial key sequence secondary function. These are
;;; * marked as XROM 0,1 (an impossible XROM function), but ensure
;;; * that we are actually doing a prompting secondary.
checkSecondaryTakeOver:
              gosub   systemBuffer
              goto    noTakeOver    ; (P+1) no system buffer
              c=data
              st=c
              ?st=1   Flag_SEC_PROXY
              gonc    noTakeOver    ; not doing secondary
              st=0    Flag_SEC_PROXY ; clear the secondary proxy flag
              c=st
              data=c
              c=0     x
              dadd=c
              c=regn  8
              rcr     7
              goto    checkXADR

;;; * Pause timer
pause:        cstex                 ; restore flags
              b=a     x             ; B.X= system buffer header address
              gosub   PGMAON        ; turn on prgm annunciator
              ldi     80            ; 41CX pause timer counter
              a=c     x
              .newt_timing_start
10$:          chk kb
              golc    bufferScan0
              ldi     12
              gosub   RMCK05
              a=a-1   x
              gonc    10$
              .newt_timing_end
              c=b     x             ; pause times out, clear OS4 pause flag
              dadd=c
              c=data
              cstex
              st=0    Flag_Pause
              cstex
              data=c
              c=0
              dadd=c
              s13=1                 ; set running flag
              c=regn  15            ; set line # TO FFF
              c=0     x
              c=c-1   x
              regn=c  15
              c=regn  14
              st=c                  ; put up SS0
              golong  0x7cc         ; PRT4 and join forces with RUN

;;; **********************************************************************
;;;
;;; In this section we store some smaller routines that we do not expect
;;; ever need to be changed. We save a relay jump by doing this.
;;;
;;; **********************************************************************

              .section fixedEntries

;;; **********************************************************************
;;;
;;; jumpCN - jump via a packed pointer
;;;
;;; Assume that C[6:3] points somewhere in a table of code pointers, well
;;; there should at least be one. Provide different entry points to advance
;;; the pointer to allow for invoking different routines by offsetting a
;;; base pointer.
;;; The location to jump to is assumed to be in the same 4K page as the
;;; table of pointers. The actual pointer is stored packed, that is,
;;; a 10-bit pointer aligned on 4. The value 000 is used to indicate that
;;; the pointer is not defined.
;;; As usual, you typically use gosub or golong to invoke the jumpCN
;;; routine, based on whether you are calling or jumping to the active
;;; pointer. Some care is of course needed in case you use golong and
;;; the stored routine does not exist (has value 000), in that case it
;;; will still return and that will be to what is on the stack. This may
;;; of course be intentional, if it is a tail-jump to exit a subroutine.
;;;
;;; In C[6:3] - base pointer for jump/call table
;;; Uses: C[12:0] and more depending on the routine that is invoked
;;;
;;; Note: This routine is intentionally first in the fixedEntries section.
;;;       Should these be need to add more entries, it can be done easily
;;;       by just doing it and adjusting back the start address of
;;;       fixedEntries accordingly.
;;;
;;; **********************************************************************

              .public jumpC0, jumpC1, jumpC2, jumpC3, jumpC4, jumpC5
              .public jumpPacked
jumpC5:       c=c+1   m
jumpC4:       c=c+1   m
jumpC3:       c=c+1   m
jumpC2:       c=c+1   m
jumpC1:       c=c+1   m
jumpC0:       cxisa
              ?c#0    x
              rtnnc
jumpPacked:   c=c+c   x
              c=c+c   x
              csr     m
              csr     m
              csr     m
              rcr     -3
              gotoc

;;; **********************************************************************
;;;
;;; gosubAlign4 - call a 4 aligned subroutine in a plug-in ROM
;;; golAlign4   - golong a 4 aligned subroutine in a plug-in ROM
;;;
;;; These routines are similar to the various GOSUB0-GOSUB3, and GOL0-GOL3
;;; except that they run faster and require that the called routine is
;;; aligned on an even 4 address (the lowest two address bits of the
;;; destination must be 0).
;;;
;;; The main benefit of these routines is that they do not use an additional
;;; subroutine level while allowing calls to go anywhere within a 4K page.
;;; In other words, they allow arbitrary calls within a 4K page utilizing
;;; the full 4 level return stack.
;;;
;;; Also consider using GOLONG/GOSUB in mainframe that is basically as
;;; fast but limits the range to be within same 1K page inside the 4K
;;; page.
;;; Another alternative is using GSB000/GSB256/GSB512/GSB768 in mainframe
;;; which aligns on 256 and all calls must take place from within the
;;; following 256 words. While being far less flexible, it is even faster.
;;; Though it only provides gosub, not golong.
;;;
;;; Uses: C
;;; Assumes: hex enabled
;;;
;;; **********************************************************************

golAlign4:    c=stk
              cxisa
              goto    jumpPacked
gosubAlign4:  c=stk
              cxisa
              c=c+1   m
              stk=c
              goto    jumpPacked

;;; **********************************************************************
;;;
;;; RTNP2 - return to P+2
;;; dropRTNP2 - drop stack and return to P+2
;;;
;;; These routines are useful for returning skipping past the instruction
;;; just after the gosub.
;;;
;;; dropRTNP2 is meant to be used with generic extensions that wants to
;;;  return back to the original caller (instead of exiting back to
;;;  mainframe). It simply drops the return address (which points back to
;;;  extensionHandler) and returns to (P+2) of the original generic
;;;  extension caller.
;;;
;;; Uses: C[6:3]
;;;
;;; **********************************************************************

              .public dropRTNP2, RTNP2, jumpP0, jumpP1
dropRTNP2:    spopnd
RTNP2:        c=stk
jumpP1:       c=c+1   m
jumpP0:       gotoc

;;; **********************************************************************
;;;
;;; RTNP3 - return to P+3
;;; dropRTNP2 - drop stack and return to P+3
;;;
;;; These routines are useful for returning skipping past the instruction
;;; just after the gosub.
;;;
;;; dropRTNP3 is meant to be used with generic extensions that wants to
;;;  return back to the original caller (instead of exiting back to
;;;  mainframe). It simply drops the return address (which points back to
;;;  extensionHandler) and returns to (P+3) of the original generic
;;;  extension caller.
;;;
;;; Uses: C[6:3]
;;;
;;; **********************************************************************

              .public dropRTNP3, RTNP3, jumpP2
dropRTNP3:    spopnd
RTNP3:        c=stk
jumpP2:       c=c+1   m
              goto    jumpP1

;;; **********************************************************************
;;;
;;; unpackN - unpack a packed pointer relative to C[6:3]
;;;
;;; Change a base pointer to what a packed field pointer points to.
;;; Basically base.member in C.
;;;
;;; In: C[6:3] - pointer to a structure
;;; Out: C[6:3] - the member at given offset, unpacked
;;;
;;; **********************************************************************

              .public unpack, unpack0, unpack1, unpack2, unpack3, unpack4, unpack5
unpack5:      c=c+1   m
unpack4:      c=c+1   m
unpack3:      c=c+1   m
unpack2:      c=c+1   m
unpack1:      c=c+1   m
unpack0:      cxisa
unpack:       csr     m
              csr     m
              csr     m
              c=c+c   x
              c=c+c   x
              rcr     -3
              rtn

;;; **********************************************************************
;;;
;;; noRoom - show NO ROOM error
;;; displayError, errMessl, errExit - error support routines
;;;
;;; **********************************************************************

              .section code, reorder
              .public noRoom, noSysBuf, ensureHPIL, ensure41CX
noRoom:       gosub   errorMessage
              .messl  "NO ROOM"
              goto    errorExit

noSysBuf:     gosub   errorMessage
              .messl  "NO SYSBUF"
              goto    errorExit

              .public displayError, errorMessage, errorExit
displayError: gosub   MESSL
              .messl  " ERR"
errorMessage: gosub   ERRSUB
setMessl:     gosub   CLLCDE
              golong  MESSL

;;; **********************************************************************
;;;
;;; ensureDrive - ensure that an HP-IL moduld and mass storage exists
;;; ensureHPIL - ensure that an HP-IL module is inserted
;;;
;;; This routine only returns if the HP-IL module is present, and there
;;; is a mass storage drive (ensureDrive).
;;;
;;; Uses: C, A.X
;;;
;;; **********************************************************************

ensureDrive:  c=0
              gosub   CHKCST
              ?c#0
              goc     ensureHPIL
              gosub   errorMessage
              .messl  "NO DRIVE"
errorExitPop: spopnd                ; defensive measure
                                    ; not strictly needed, but probably a good
errorExit:    gosub   LEFTJ
              gosub   MSG105
              golong  ERR110

ensureHPIL:   ldi     28            ; HP-IL XROM Id
              a=c     x
              c=0     m
              lc      7             ; address 7000
              cxisa                 ; fetch XROM Id from 7000
              ?a#c    x
              rtnnc
              gosub errorMessage
              .messl "NO HP-IL"
              goto    errorExitPop

;;; **********************************************************************
;;;
;;; ensure41CX - ensure we are running on a 41CX style OS
;;;
;;; This routine only returns if we are running on a HP-41CX (or similar style)
;;; operating system.
;;;
;;; Uses: C, A.X
;;;
;;; **********************************************************************

ensure41CX:   ldi     25
              a=c     x
              c=0     m
              pt=     6
              lc      3             ; build address 3000
              cxisa                 ; fetch XROM Id from 3000
              ?a#c    x
              rtnnc
              gosub   errorMessage
              .messl  "NO 41CX OS"
              goto    errorExitPop


;;; **********************************************************************
;;;
;;; versionCheck - check the version expected by OS4
;;;
;;; In: C.X = Version number, where the first nibble is the main version
;;;           number that must match. The lower 8 bits are the minor
;;;           number that be at least the same

;;; Out: Only returns if the current version is at least the expected
;;;      one. Exits showing error "OLD OS4" if expected version is
;;;      higher than the current one.
;;; Uses: A.X, C[6:3]
;;;
;;; **********************************************************************

versionCheck: a=c     x
              ldi     OS4Version + 1
              ?a#c    xs            ; main version good?
              goc     10$           ; no
              a=a-c   x             ; check minor version
              rtnc                  ; OK
10$:          gosub   errorMessage
              .messl  "OLD OS4"
              goto    errorExitPop


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

              .section OS4BankSwitchers1
             BankSwitchers

              .section OS4BankSwitchers2
             BankSwitchers

;;; **********************************************************************
;;;
;;; Entry points intended for application modules.
;;;
;;; Here we use a jump table to allow the internal code to be reorganized
;;; without altering the entry points. Traditionally, the HP-41 mainframe
;;; relied on jumping into the code and not altering it too much.
;;; However, as is evident by the HP-41CX, it can start to get a bit messy
;;; when there is need for changes.
;;; The changes in HP-41CX were actually quite few, the expectations here
;;; is that there will be quite a lot more changes as this code is not
;;; written for a particular release deadline, but rather something that
;;; will evolve over time.
;;; To make it easier to make changes, an entry point table is used.
;;;
;;; **********************************************************************

              .section entry
              .extern activateShell, exitShell, reclaimShell
              .extern findBuffer, ensureBuffer, growBuffer
              .extern findKAR2
              .extern topExtension, shellDisplay, getXAdr, shellName
              .extern keyKeyboard, argument, NXBYTP, NXBYT
              .extern clearSystemDigitEntry, reclaimSystemBuffer
              .extern displayDone, sendMessage, keyDispatch
              .extern shrinkBuffer, allocScratch, clearScratch, scratchArea
              .extern exitTransientApp, hasActiveTransientApp
              .extern parseNumber, parseNumberInput
              .extern shellKeyboard, XASRCH, secondaryAddress
              .extern clearAssignment, assignSecondary, secondaryAssignment
              .extern resetBank, invokeSecondary, XABTSEQ
              .extern clearSecondaryAssignments, runSecondary
              .extern setTimeout, clearTimeout, activeApp
              .extern findBufferHosted, reclaimHostedBuffer, newHostedBuffer
              .extern growHostedBuffer, shrinkHostedBuffer, packHostedBuffers
              .extern dualArgument
              .public secondaryAddress_B1

              golong  activateShell ; 0x4f00
              golong  exitShell     ; 0x4f02
              golong  reclaimShell  ; 0x4f04
              golong  findBuffer    ; 0x4f06
              golong  ensureBuffer  ; 0x4f08
              golong  growBuffer    ; 0x4f0a
              golong  findKAR2      ; 0x4f0c
              golong  setMessl      ; 0x4f0e
              golong  shellDisplay  ; 0x4f10
              golong  getXAdr       ; 0x4f12
              golong  topShell      ; 0x4f14
              golong  topExtension  ; 0x4f16
              golong  nextShell     ; 0x4f18
              golong  shellName     ; 0x4f1a
              golong  keyKeyboard   ; 0x4f1c
              golong  argument      ; 0x4f1e
              golong  RTNP2         ; 0x4f20 xargument  / acceptAllValues
              golong  fastDigitEntry ; 0x4f22
              golong  NXBYTP        ; 0x4f24
              golong  NXBYT         ; 0x4f26
              golong  noRoom        ; 0x4f28
              golong  errorMessage  ; 0x4f2a
              golong  errorExit     ; 0x4f2c
              golong  clearSystemDigitEntry ; 0x4f2e
              golong  reclaimSystemBuffer ; 0x4f30
              golong  displayDone   ; 0x4f32
              golong  sendMessage   ; 0x4f34
              golong  activeApp     ; 0x4f36
              golong  shrinkBuffer  ; 0x4f38
              golong  allocScratch  ; 0x4f3a
              golong  clearScratch  ; 0x4f3c
              golong  scratchArea   ; 0x4f3e
              golong  exitTransientApp ; 0x4f40
              golong  hasActiveTransientApp ; 0x4f42
              golong  ensureHPIL    ; 0x4f44
              golong  ensure41CX    ; 0x4f46
              rtn                   ; 0x4f48 partialKey (from program execution)
              nop                   ;        partialKey filler
              golong  noSysBuf      ; 0x4f4a
              golong  shellKeyboard ; 0x4f4c
              enrom2                ; XASRCH 0x4f4e
XASRCHB2Location:
              nop                   ; filler for XASRCH
secondaryAddress_B1:
              enrom2                ; secondaryAddress 0x4f50
secondaryAddressB2Location:
              nop                   ; filler for secondaryAddress
              golong  clearAssignment ; 0x4f52
              golong  assignSecondary ; 0x4f54
              golong  secondaryAssignment ; 0x4f56
              golong  resetBank     ; 0x4f58
              golong  invokeSecondary ; 0x4f5a
              golong  XABTSEQ       ; 0x4f5c
              golong  clearSecondaryAssignments ; 0x4f5e
              enrom2                ; runSecondary 0x4f60
runSecondaryB2Location:
              nop                   ; filler for runSecondary
              golong  setTimeout    ; 0x4f62
              golong  clearTimeout  ; 0x4f64
              golong  keyDispatch   ; 0x4f66
              golong  ensureDrive   ; 0x4f68
              golong  findBufferHosted ; 0x4f6a
              golong  reclaimHostedBuffer ; 0x4f6c
              golong  newHostedBuffer ; 0x4f6e
              golong  growHostedBuffer ; 0x4f70
              golong  shrinkHostedBuffer ; 0x4f72
              golong  packHostedBuffers ; 0x4f74
              golong  dualArgument  ; 0x4f76

;;; Plain backing wit a jump, the routine handles it.
backing       .macro  lab
              .section code2
              .shadow \labB2Location
\lab_B2:
              golong  \lab
              .endm

;;; Backing with a call
backingCall   .macro lab
              .section code2
              .shadow \labB2Location
\lab_B2:
              gosub   \lab
              golong  enableBank1
              .endm

;;; Table backing in page 2
              .section code2
              backing XASRCH
              backing runSecondary
              backingCall secondaryAddress

;;; Reserved tail identification. We only use a checksum at the moment.
              .section TailOS4
              .con    0             ; to be replaced by checksum
