;;; -*- mode: gas;-*-
#ifndef __OS4_H__
#define __OS4_H__

;;; **********************************************************************
;;;
;;; The current version of OS4. This can be used as input to versionCheck
;;; to make sure that the installed OS4 is at least the expected version.
;;;
;;; The version number is 3 nibbled (12 bits), the first nibble is the
;;; major version, which tells whether the overall structure is the same.
;;; Changing it means that nothing may be the same, all entry points may
;;; be gone, moved or whatever.
;;; The lower 2 nibbles is the minor version which is incremented anytime
;;; new features are added, but otherwise it shall be backward compatible.
;;;
;;; **********************************************************************

#define OS4Version  0


;;; **********************************************************************
;;;
;;; OS4 exports
;;;
;;; **********************************************************************

#define argumentEntry      0x4f1e
#define dualArgumentEntry  0x4f76
#define xargumentEntry     0x4f20
#define partialKeyEntry    0x4f48
#define runSecondaryEntry  0x4f60

;;; * Find ROM words for a call to a fixed address.
#define FirstGosub(x)   ((((x) << 2) & (255 << 2)) | 1)
#define SecondGosub(x)  (((x) >> 6) & (255 << 2))

#ifndef IN_OS4
activateShell: .equlab 0x4f00
exitShell:    .equlab 0x4f02
reclaimShell: .equlab 0x4f04
findBuffer:   .equlab 0x4f06
ensureBuffer: .equlab 0x4f08
openSpace:    .equlab 0x4f0a
findKAR2:     .equlab 0x4f0c
setMessl:     .equlab 0x4f0e
shellDisplay: .equlab 0x4f10
getXAdr:      .equlab 0x4f12
topShell:     .equlab 0x4f14
topExtension: .equlab 0x4f16
nextShell:    .equlab 0x4f18
shellName:    .equlab 0x4f1a
keyKeyboard:  .equlab 0x4f1c
argument:     .equlab argumentEntry
xargument:    .equlab xargumentEntry
fastDigitEntry: .equlab 0x4f22
NXBYTP:       .equlab 0x4f24
NXBYT:        .equlab 0x4f26
noRoom:       .equlab 0x4f28
errorMessage: .equlab 0x4f2a
errorExit:    .equlab 0x4f2c
clearSystemDigitEntry: .equlab 0x4f2e
reclaimSystemBuffer .equlab 0x4f30
displayDone:  .equlab 0x4f32
sendMessage   .equlab 0x4f34
activeApp:    .equlab 0x4f36
shrinkBuffer: .equlab 0x4f38
allocScratch: .equlab 0x4f3a
clearScratch: .equlab 0x4f3c
scratchArea   .equlab 0x4f3e
exitTransientApp:  .equlab 0x4f40
hasActiveTransientApp:  .equlab 0x4f42
ensureHPIL    .equlab 0x4f44
ensure41CX    .equlab 0x4f46
partialKey:   .equlab partialKeyEntry
noSysBuf:     .equlab 0x4f4a
shellKeyboard: .equlab 0x4f4c
XASRCH:       .equlab 0x4f4e
secondaryAddress: .equlab 0x4f50
clearAssignment: .equlab 0x4f52
assignSecondary: .equlab 0x4f54
secondaryAssignment: .equlab 0x4f56
resetBank:    .equlab 0x4f58
invokeSecondary: .equlab 0x4f5a
XABTSEQ:      .equlab 0x4f5c
clearSecondaryAssignments: .equlab 0x4f5e
runSecondary: .equlab runSecondaryEntry
setTimeout:   .equlab 0x4f62
clearTimeout: .equlab 0x4f64
keyDispatch:  .equlab 0x4f66
ensureDrive:  .equlab 0x4f68
findBufferHosted: .equlab 0x4f6a
reclaimHostedBuffer: .equlab 0x4f6c
newHostedBuffer: .equlab 0x4f6e
growHostedBuffer: .equlab 0x4f70
shrinkHostedBuffer: .equlab 0x4f72
packHostedBuffers: .equlab 0x4f74
dualArgument: .equlab dualArgumentEntry
exitApp:      .equlab 0x4f78
catEmpty      .equlab 0x4f7a
catalog:      .equlab 0x4f7c
catalogWithSize: .equlab 0x4f7e
jumpC5:       .equlab 0x4d00
jumpC4:       .equlab 0x4d01
jumpC3:       .equlab 0x4d02
jumpC2:       .equlab 0x4d03
jumpC1:       .equlab 0x4d04
jumpC0:       .equlab 0x4d05
jumpPacked:   .equlab 0x4d08
golAlign4:    .equlab 0x4d0f
gosubAlign4:  .equlab 0x4d12
dropRTNP2     .equlab 0x4d17
RTNP2:        .equlab 0x4d18
jumpP1:       .equlab 0x4d19
jumpP0:       .equlab 0x4d1a
dropRTNP3:    .equlab 0x4d1b
RTNP3:        .equlab 0x4d1c
jumpP2:       .equlab 0x4d1d
unpack5:      .equlab 0x4d1f
unpack4:      .equlab 0x4d20
unpack3:      .equlab 0x4d21
unpack2:      .equlab 0x4d22
unpack1:      .equlab 0x4d23
unpack0:      .equlab 0x4d24
unpack:       .equlab 0x4d25
#endif

;;; **********************************************************************
;;;
;;; Definition words
;;;
;;; **********************************************************************

#define SysShell              8
#define AppShell              4
#define TransAppShell         (AppShell | 2)
#define GenericExtension      0


#define KeyAutoAssign         0        // Make use of the top-row auto label assignment
                                       // feature (RPN label A-J and a-e)
#define KeyFlagSparseTable    6        // Set if the keyboard table iso a linear
                                       // search rather than a lookup.
#define KeyFlagTransientApp   7        // Set if this is a transient application
                                       // that terminates on a 000 (pass-through)
                                       // key. Typically something like CAT can
                                       // use it to define a few keys that are
                                       // handled, but if another (undefined)
                                       // key is pressed, the shell is terminated.

// Sparse table XKD handler
#define KeyXKD   0

;;; **********************************************************************
;;;
;;; Extension messages.
;;;
;;; **********************************************************************

#define ExtensionListEnd  0

// Invoke a CAT, N.X is the catalog number.
// If a catalog is implemented, exit by jumping to QUTCAT in mainframe.
#define ExtensionCAT      1

// Shell stack was altered in some way.
#define ExtensionShellChanged 2


;;; **********************************************************************
;;;
;;; Hosted buffers.
;;;
;;; **********************************************************************

#define SeedBuffer       0             ; Random number seed, used by Boost


;;; **********************************************************************
;;;
;;; System buffer status flags. These flags are held in the buffer
;;; header.
;;;
;;; **********************************************************************

Flag_ArgumentDual:   .equ  0           ; Dual semi-merged argument in
                                       ; progress.
                                       ; have priority and are active.
Flag_DisplayOverride .equ  1           ; Set when message flag really means that
                                       ; we override the display.
Flag_OrphanShells:   .equ  2           ; Set when we should release orphan shells.
Flag_Argument:       .equ  3           ; Semi-merged argument entry in progress.
Flag_Pause:          .equ  4           ; Our own pause flag.
Flag_SEC_PROXY:      .equ  5           ; Set when doing partial key for secondary
                                       ; functions.
Flag_SEC_Argument:   .equ  6           ; Set when doing a semi-merged postfix on
                                       ; a secondary function.
Flag_IntervalTimer:  .equ  7           ; Set when we are using the interval timer

;;; **********************************************************************
;;;
;;; Key sequence parsing.
;;;
;;; **********************************************************************

acceptAllValues: .equlab xargumentEntry

// Flag number to permit EEX key, use ParseNumber_AllowEEX below in your code.
#define Flag_ParseNumber_AllowEEX  0

// Helper macros
#define OffsetParseNumberFlag 4
#define _ParseNumberMask(flag) (1 << (flag + OffsetParseNumberFlag))

// Mask bit for permitting EEX key
#define ParseNumber_AllowEEX  _ParseNumberMask(Flag_ParseNumber_AllowEEX)

;;; **********************************************************************
;;;
;;; Key table support.
;;;
;;; **********************************************************************

#define LFE(x)  `FAT entry: \x`
#define FATOFF(x) (LFE(x) - FatStart) / 2

;;; Make it easy to populate the key table with an XROM
KeyEntry:     .macro  fun
              .con   FATOFF(fun)
              .endm

;;; Builtin function in a key table.
;;;
;;; BuiltinKey - builtin function that ends digit entry.
;;; This is the normal case and it is offsetted by 1 to allow for using CAT
;;; which is 000, which means Text-15 is not possible.
;;; 000 in the table means pass through to next system shell key table.
;;;
;;; BuiltinKeyKeepDigitEntry - builtin function (not ending digit entry)
;;; Mainly used for SHIFT and USER.
#define BuiltinKey(n)                 ((n) + 0x201)
#define BuiltinKeyKeepDigitEntry(n)   ((n) + 0x300)

#endif // __OS4_H__
