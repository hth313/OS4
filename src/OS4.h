;;; -*- mode: gas;-*-
#ifndef OS4_H
#define OS4_H

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
chkbuf:       .equlab 0x4f06
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
extensionHandler .equlab 0x4f34
keyDispatch:  .equlab 0x4f36
shrinkBuffer: .equlab 0x4f38
allocScratch: .equlab 0x4f3a
clearScratch: .equlab 0x4f3c
scratchArea   .equlab 0x4f3e
exitTransientApp:  .equlab 0x4f40
hasActiveTransientApp:  .equlab 0x4f42
ensureHPIL    .equlab 0x4f44
ensure41CX    .equlab 0x4f46
partialKey:   .equlab partialKeyEntry
parseNumber:  .equlab 0x4f4a
parseNumberInput: .equlab 0x4f4c
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
// Temporary until addresses are finally fixed
//              .extern RTNP2
RTNP2:        .equlab 0x4d18
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
;;; Defined extensions.
;;;
;;; **********************************************************************

#define ExtensionListEnd  0

// Invoke a CAT, N.X is the catalog number.
#define ExtensionCAT      1


;;; **********************************************************************
;;;
;;; System buffer status flags. These flags are held in the buffer
;;; header.
;;;
;;; **********************************************************************

Flag_NoApps:         .equ  0           ; Set if all application shells are
                                       ; disabled, essentially meaning that
                                       ; we have default behavior (no active
                                       ; application). System shells still
                                       ; have priority and are active.
Flag_DisplayOverride .equ  1           ; Set when message flag really means that
                                       ; we override the display.
Flag_OrphanShells:   .equ  2           ; Set when we should release orphan shells.
Flag_Argument:       .equ  3           ; Semi-merged argument entry in progress.
Flag_Pause:          .equ  4           ; Our own pause flag.
Flag_SEC_PROXY:      .equ  5           ; Set when doing partial key for secondary
                                       ; functions.

;;; **********************************************************************
;;;
;;; Key sequence parsing.
;;;
;;; **********************************************************************

acceptAllValues: .equlab xargumentEntry


ParseNumber_AllowEEX: .equ    1    // flag used for permitted EEX key

#endif // OS4_H
