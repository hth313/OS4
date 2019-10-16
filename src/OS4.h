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

#define argumentEntry   0x4f1e
#define xargumentEntry  0x4f20

;;; * Find ROM words for a call to a fixed address.
#define FirstGosub(x)   ((((x) << 2) & (255 << 2)) | 1)
#define SecondGosub(x)  (((x) >> 6) & (255 << 2))

#ifndef IN_OS4
activateShell: .equlab 0x4f00
exitShell:    .equlab 0x4f02
reclaimShell: .equlab 0x4f04
chkbuf:       .equlab 0x4f06
getbuf:       .equlab 0x4f08
openSpace:    .equlab 0x4f0a
findKAR2:     .equlab 0x4f0c
stepKAR:      .equlab 0x4f0e
shellDisplay: .equlab 0x4f10
logoutXMem:   .equlab 0x4f12
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
#endif

;;; **********************************************************************
;;;
;;; Definition words
;;;
;;; **********************************************************************

#define SysShell              0
#define AppShell              1
#define GenericExtension      2


#define KeyFlagSparseTable    6        // Set if the keyboard table iso a linear
                                       // search rather than a lookup.
#define KeyFlagTransientApp   7        // Set if this is a transient application
                                       // that terminates on a 000 (pass-through)
                                       // key. Typically something like CAT can
                                       // use it to define a few keys that are
                                       // handled, but if another (undefined)
                                       // key is pressed, the shell is terminated.

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
Flag_Pause           .equ  4           ; Our own pause flag.

#endif // OS4_H
