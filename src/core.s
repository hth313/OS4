;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;;
;;; **********************************************************************

#include "mainframe.i"

#define IN_RATATOSK
#include "ratatosk.h"


;;; ----------------------------------------------------------------------
;;;
;;; Main take over entry point at address 0x4000.
;;;
;;; ----------------------------------------------------------------------

              .extern sysbuf, doDisplay, doPRGM

              .section Header4
              rst kb                ; these three instructions
              chk kb                ; necessary because of
              sethex                ; problems with CPU wakeup

              c=stk                 ; inspect return address (and drop it)
              rcr     1             ; C.XS= lower nibble
              c=c+c   xs
              goc     deepWake      ; deep wake up

lightWake:    ldi     0x2fd         ; PACH11
              dadd=c                ; enable nonexistent data chip 2FD
              pfad=c                ; enable display
              flldc                 ; non-destructive read

              c=0     x
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
              goc     bufferScan    ; key is down, find active handler

;;; No key down, inspect various flags that should prevent
;;; us from showing an alternative display.
              ?s5=1                 ; message flag?
              goc     LocalMEMCHK   ; yes, leave display alone
              ?s7=1                 ; alpha mode?
              goc     LocalMEMCHK   ; yes, leave display alone
              c=regn 14
              c=c+c   xs
              c=c+c   xs
              goc     LocalMEMCHK   ; data entry in progress
              c=c+c   xs
              goc     LocalMEMCHK   ; partial key in progress
              ?s3=1                 ; program mode?
              golc    doPRGM        ; yes, we may need to display certain
                                    ; instructions in a custom way
              gosub   doDisplay     ; we may want to override the display

;;; This is a replacement for MEMCHK. It is called whenever we are going
;;; to light sleep. As we are not running a program and the HP-41 may
;;; time out and go to sleep, we put back the warm start constant.
;;; We do use MEMCHK when doing a wake up from deep sleep, as this is
;;; the most likely time some power disruption may have happen.
;;; This means that in reality we get a similar cover for memory corruption
;;; as before.
              .public LocalMEMCHK
LocalMEMCHK:  c=0     x
              pfad=c                ; turn off peripheral chips
              dadd=c                ; turn on chip 0
              c=regn  13
              rcr     6
              ldi     169           ; put back warm start constant
              gosub   0x0212        ; join forces with MEMCHK

;;; Keep processing I/O and key down before going to light sleep
3$:           chk kb                ; check key down while doing I/O
              goc     bufferScan
              ldi     8             ; I/O service
              gosub   ROMCHK        ; needs chip 0,SS0,hex,P selected
              ?s2=1                 ; I/O flag?
              goc     3$            ; yes, keep going

              golong  0x18c         ; go to light sleep

toWKUP20:     golong  0x1a6         ; WKUP20, ordinary check key pressed

;;; ----------------------------------------------------------------------
;;;
;;; deepWake - deep sleep wake up
;;;
;;; Release all Shells, application ROMs need to reclaim them using their
;;; deep wake poll vectors.
;;;
;;; ----------------------------------------------------------------------

              .extern releaseShells
deepWake:     gosub   releaseShells
              goto    10$           ; no system buffer
              acex    x             ; C.X= system header address
              dadd=c
              c=data
              cstex
              st=0    Flag_Argument ; no argument handling going on
              st=0    Flag_Pause    ; no pause
              cstex
              data=c
10$:          golong  DSWKUP+2


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
fastDigitEntry:
bufferScan:   c=c+c   xs
              c=c+c   xs
              c=c+c   xs
              goc     toWKUP20      ; partial key in progress

              pt=     3
              c=keys
              c=c+c   pt            ; OFF key?
              golc    OFF           ; yes
              gosub   topShell
              goto    20$           ; (P+1) no shell, ordinary keyboard logic

14$:          gosub   keyHandler    ; invoke key handler
              gosub   nextShell     ; did not want to deal with it, step to
                                    ; next shell
              goto    20$           ; (P+1) out of shells
              goto    14$           ; (P+2) inspect next shell

20$:          gosub   LDSST0        ; bring up SS0
              goto    toWKUP20


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
jumpC5:       c=c+1   m
jumpC4:       c=c+1   m
jumpC3:       c=c+1   m
jumpC2:       c=c+1   m
jumpC1:       c=c+1   m
jumpC0:       cxisa
              ?c#0    x
              rtnnc
jump10:       c=c+c   x
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
              goto    jump10
gosubAlign4:  c=stk
              cxisa
              c=c+1   m
              stk=c
              goto    jump10

;;; **********************************************************************
;;;
;;; noRoom - show NO ROOM error
;;; displayError, errMessl, errExit - error support routines
;;;
;;; **********************************************************************

              .public noRoom, noSysBuf
noRoom:       gosub   errorMessl
              .messl  "NO ROOM"
              goto    errorExit

noSysBuf:     gosub   errorMessl
              .messl  "NO SYSBUF"
              goto    errorExit
              .public displayError, errorMessl, errorExit
displayError: gosub   MESSL
              .messl  " ERR"
errorMessl:   gosub   LEFTJ
              s8=     1
              gosub   MSG105
              golong  ERR110
errorExit:    gosub   ERRSUB
              gosub   CLLCDE
              golong  MESSL

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

              .public dropRTNP2, RTNP2, jumpP2
dropRTNP2:    spopnd
RTNP2:        c=stk
jumpP2:
RTNP20:       c=c+1   m
              gotoc

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

              .public dropRTNP3, RTNP3
dropRTNP3:    spopnd
RTNP3:        c=stk
              c=c+1   m
              goto    RTNP20

;;; **********************************************************************
;;;
;;; unpackN - unpack a packed pointer relative to C[6:3]
;;;
;;; Change a base pointer to what a packed field pointer points to.
;;; Basically base.member in C.
;;;
;;; In: C[6:3] - pointer to a structure
;;; Out: Returns to (P+1) if pointer is 000
;;;      Returns to (P+2) with
;;;         A[6:3] - the member at given offset, unpacked
;;;
;;; **********************************************************************

              .public unpack0, unpack1, unpack2, unpack3, unpack4, unpack5
unpack5:      c=c+1   m
unpack4:      c=c+1   m
unpack3:      c=c+1   m
unpack2:      c=c+1   m
unpack1:      c=c+1   m
unpack0:      cxisa
              ?c#0    x
              rtnnc
              c=c+c   x
              c=c+c   x
              acex    m
              c=0     m
              rcr     -3
              a=a+c   m
              goto    RTNP2


;;; **********************************************************************
;;;
;;; versionCheck - check the version expected by Ratatosk
;;;
;;; In: C.X = Version number, where the first nibble is the main version
;;;           number that must match. The lower 8 bits are the minor
;;;           number that be at least the same

;;; Out: Return to (P+2) if the current version is at least the expected
;;;      one. Exits showing error "OLD RTOSK" if expected version is
;;;      higher than the current one.
;;; Uses: A.X, C[6:3]
;;;
;;; **********************************************************************

versionCheck: a=c     x
              ldi     RatatoskVersion + 1
              ?a#c    xs            ; main version good?
              goc     10$           ; no
              a=a-c   x             ; check minor version
              goc     RTNP2         ; OK
10$:          gosub   errorMessl
              .messl  "OLD RTSK"
              goto    errorExit


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
              .extern chkbuf, getbuf, openSpace
              .extern findKAR2, stepKAR
              .extern topAppShell, shellDisplay, logoutXMem, shellName
              .extern keyKeyboard, argument, NXBYTP, NXBYT
              .extern clearSystemDigitEntry

              golong  activateShell ; 0x4f00
              golong  exitShell     ; 0x4f02
              golong  reclaimShell  ; 0x4f04
              golong  chkbuf        ; 0x4f06
              golong  getbuf        ; 0x4f08
              golong  openSpace     ; 0x4f0a
              golong  findKAR2      ; 0x4f0c
              golong  stepKAR       ; 0x4f0e
              golong  shellDisplay  ; 0x4f10
              golong  logoutXMem    ; 0x4f12
              golong  topShell      ; 0x4f14
              golong  topAppShell   ; 0x4f16
              golong  nextShell     ; 0x4f18
              golong  shellName     ; 0x4f1a
              golong  keyKeyboard   ; 0x4f1c
              golong  argument      ; 0x4f1e
              golong  RTNP2         ; 0x4f20 xargument
              golong  fastDigitEntry
              golong  NXBYTP
              golong  NXBYT
              golong  noRoom
              golong  errorMessl
              golong  errorExit
              golong  clearSystemDigitEntry
