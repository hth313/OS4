;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;; Secondaty assignment support.
;;;
;;; **********************************************************************

#include "mainframe.h"
#include "internals.h"

;;; clearAssignment docstart
;;; **********************************************************************
;;;
;;; clearAssignment - delete an assignment
;;;
;;; Note: This routine enters and leaves in bank 1, but actually has most
;;;       of its code in bank 2. This is due to that it is externally
;;;       called and uses +3 sub levels.
;;;
;;; In: A[1:0] - keycode to be cleared, in 1-80 form
;;; Out: Nothing
;;; Uses: A, C, B.X, N, M, DADD, +3 sub levels
;;;
;;; **********************************************************************
;;; clearAssignment docend

              .section code1, reorder
              .public clearAssignment
              .extern shrinkBuffer
clearAssignment:
              acex
clearAssignment10:
              switchBank 2
              a=c
              n=c                   ; N[1:0]= keycode
              s1=0                  ; assume not system assigned
              gosub   testAssignBit
              goto    991$          ; (P+1) not assigned
              s1=1                  ; (P+2) system assigned
                                    ; (P+3) secondary assigned
;;; * Reset the bitmap bit in the 'active' one. If the key is assigned
;;; * as both system and secondary, the secondary is shadowed and we
;;; * only reset the system one in that case. We will take care of
;;; * this 'double' case further down.
              c=m                   ; reset bitmap bit
              c=a-c
              data=c

              goto    1$            ; skip over
991$:         golong  enableBank1   ; return as not assigned, needed as
                                    ; branch range is too far and there are
                                    ; no suitable alternative to put it

1$:           gosub   assignArea
              goto    500$          ; (P+1) no secondary assignemnts
              c=c+1   x
              c=c+1   x             ; step past bitmap registers
              bcex    x             ; B.X= point to first secondary assignment register
              acex    x             ; C.X= address of buffer header
              rcr     -3            ; C[5:3]= address of buffer header
              bcex    m             ; B[5:3]= address of buffer header
              c=n
              pt=     1
              a=c     wpt           ; A[1:0]= keycode
              c=data                ; read buffer header
              rcr     7             ; C.S= number of secondary assignment registers
              a=c     s
              a=a-1   s             ; A.S= counter
10$:          bcex    x
              dadd=c                ; select next assignment register
              c=c+1   x             ; step forward for next iteration
              bcex    x
              c=data                ; C= secondary assignment register
              ?a#c    wpt           ; this is the one we should clear?
              goc     12$           ; no
              c=0     wpt           ; yes, clear it
              goto    14$
12$:          rcr     7             ; inspect upper part
              ?a#c    wpt           ; this is the one we should clear?
              goc     20$           ; no
              c=0     wpt           ; yes, clear it
              rcr     -7
14$:          data=c                ; write back
              ?c#0    wpt           ; any part still in use?
              goc     30$           ; yes, no need to prune
              rcr     7
              ?c#0    wpt
              goc     30$           ; yes, no need to prune
;;; * We do not actually this assignment register anymore, remove it
              c=b
              rcr     3             ; C.X= buffer header address
              dadd=c                ; select buffer header
              a=c     x             ; A.X= buffer header
              abex    x             ; A.X= pointer to register to remove + 1
                                    ; B.X= buffer header
              a=a-c   x
              a=a-1   x             ; A.X= offset to register to remove
              c=data                ; read buffer header
              pt=     6
              c=c-1   pt            ; decrement assignment registers
              data=c                ; write back
              s0=0
              ldi     1
              ?c#0    pt            ; will we remove last assignment register?
              goc     15$           ; no
              s0=1                  ; we have removed bitmap registers
              c=c+1   x             ; yes, also remove bitmap registers
              c=c+1   x
              a=a-1   x             ; step back offset
              a=a-1   x
15$:          pt=     0
              g=c                   ; G= number of registers to remove
              c=b     x             ; C.X= buffer header
              acex    x             ; A.X= buffer header
                                    ; C.X= offset to first register to remove
              gosub   shrinkBuffer_B2
              ?s0=1                 ; did we remove bitmap registers?
              gonc    30$           ; no, we may need to reset bits there still
500$:         goto    50$           ; yes, do not reset bits there (as it does
                                    ;  not even exist anymore)

20$:          a=a-1   s             ; decrement loop
              gonc    10$
              goto    50$           ; secondary assigment did not exist

;;; * We did have a secondary assignment on this key. If there is a
;;; * system assignment on this key, we still need to reset the bitmap
;;; * bit in the secondary area.
30$:          ?s1=1                 ; system assigned
              gonc    99$           ; no, we are actually done now as we already
                                    ;   have reset the bitmap bit in this case
                                    ;   (above)
;;; * Now reset the bitmap bit. We make use of testAssignBit again and we
;;; * know it will come out on still having a secondary assignment as we
;;; * already have reset the system bit!
              c=n
              a=c
              gosub   testAssignBit
              nop                   ; (P+1) will not happen
              nop                   ; (P+2) will not happen
              c=m                   ; reset bitmap bit
              c=a-c
              data=c

50$:          c=0     x             ; select chip 0
              dadd=c
              c=n
              a=c                   ; A[1:0]= keycode
              regn=c  9             ; preserve N in REGN9 (GCPKC clobbers N)
              s1=1
              gosub   GCPKC         ; clear the key assignment in system
              c=regn  9
              n=c
99$:          golong  enableBank1

;;; **********************************************************************
;;;
;;; testAssignBit - test if we have a secondary assignment
;;;
;;; Test if a given keycode is assigned with a secondary instruction.
;;; This takes in account that the ordinary system bitmap takes precedence
;;; so that if there is already an ordinary assigned key, we do not regard
;;; the secondary assignment as valid.
;;;
;;; Note: This routine is in bank 2
;;;
;;; In: A[1:0] - keycode to be tested (1:80 form)
;;; Out: Returns to (P+1) if not assigned at all
;;;      Returns to (P+2) if assigned by ordinary system mechanism
;;;      Returns to (P+3) if secondary assigned, with
;;;          M= bitmap bit
;;;          A= contents of bitmap register
;;;          DADD= bitmap register selected
;;;          B.X= address of buffer header
;;;      C.S set to 0, to allow for using 'c=c+1 s' in case gotos are
;;;           not a good idea (due to bank handling)
;;; Uses: A[13:12], A.X, C, B.X, S0, S1, PT, DADD, +2 sub levels
;;;
;;; **********************************************************************

              .section code2, reorder
              .public testAssignBit
              .extern assignArea, RTNP2_B2, RTNP3_B2, noRoom_B2
              .extern growBuffer_B2
testAssignBit:
              s0=0                  ; usual behavior
testAssignBit10:
              a=a-1   x             ; decrement keycode
              asl                   ; A[2]= column
              pt=     2
              lc      4             ; C[2]= 4
              s1=0                  ; assume unshifted
              lc      8
              pt=     1
              c=a-c   pt
              goc     1$
              a=c     pt            ; normalize keycode with no shift
              s1=1                  ; shifted
1$:           pt=     5             ; position ptr at column
              goto    2$
3$:           incpt
              incpt
2$:           a=a-1   xs
              gonc    3$
              asl     x             ; A[2]_row
              ?a<c    xs            ; row<4?
              goc     4$            ; yes
              incpt                 ; set ptr
              a=a-c   xs
4$:           c=0                   ; position row,col bit
              ?pt=    0             ; top row keys?
              rtnc                  ; yes, not reassigned, return to (P+1)
              c=c+1   pt
              goto    5$
6$:           c=c+c   pt
5$:           a=a-1   xs
              gonc    6$
              a=c                   ; A= mask
              c=0     x
              dadd=c
              c=regn  15            ; load shifted bits
              ?s1=1                 ; shiftset?
              goc     7$            ; yes
              c=regn  10            ; load unshifted bits
7$:           acex                  ; A= bitmap register value
              m=c                   ; M= mask (bit we are testing)
              c=c&a                 ; row,col bit set?
              ?c#0                  ; normally assigned?
              gonc    8$
              c=0
              golong  RTNP2_B2      ; yes, return to (P+2)
8$:           gosub   assignArea
              goto    30$           ; (P+1) no secondary assignments, return to (P+1)
                                    ;   as not assigned
              b=a     x             ; B.X= address of buffer header
              a=0     x
              ?s1=1                 ; shifted?
              gonc    9$            ; no
              a=a+1   x             ; yes, step to register with shifted bits
9$:           c=a+c   x
              dadd=c
              c=data
              a=c
              c=m
              c=c&a
              ?c#0
              goc     20$           ; secondary assigned, return to (P+3)
              ?s0=1                 ; do we still want bitmap result?
              rtnnc                 ; no, return to (P+1)
20$:          c=0
              golong  RTNP3_B2
30$:          c=0
              rtn

;;; * Create assignment area.
              .section code2, reorder
              .extern gotoc_B2, ensureSystemBuffer_B2
createAssignArea:
              gosub   ensureSystemBuffer_B2
              goto    toNoRoom_B2   ; (P+1) no room
              b=a     x             ; B.X= buffer header address
              c=data                ; read buffer header
              rcr     4
              a=c     x
              rcr     4
              a=a+c   x
              a=a+1   x             ; A.X= offset where to add
              a=0     xs
              ldi     3             ; need 3 registers
              pt=     0
              g=c
              abex    x             ; A.X= buffer header address
              c=b     x             ; C.X= offset where to add registers
              gosub   growBuffer_B2
              goto    toNoRoom_B2   ; (P+1) no space
;;; Set bitmap registers to "1". This means empty bitmaps (as lower nibbles
;;; are unused), but also ensures that they are non-zero. Due to the 67/97
;;; card reader bug an I/O buffer cannot have empty registers.
;;; Reference: Time module source code.
              pt=     2
              c=0
              c=c+1
82$:          bcex    x
              dadd=c
              c=c+1   x
              bcex    x
              data=c
              decpt
              ?pt=    0
              gonc    82$
              acex    x
              dadd=c
              c=data
              pt=     6
              c=c+1   pt            ; we have one register now
              data=c
              goto    assignSecondary10 ; now we can find assign area again

toNoRoom_B2:  golong  noRoom_B2

;;; assignSecondary docstart
;;; **********************************************************************
;;;
;;; assignSecondary - assign a secondary function
;;;
;;; Note: This routine is in bank 2, but returns to bank 1.
;;;
;;; In: A[1:0] - keycode, in 1-80 form
;;;     B[4:3] - XROM identity
;;;     B[2:0] - secondary function number
;;;
;;; Uses: A, C, B.X, N, M, DADD, +3 sub levels
;;;
;;; **********************************************************************
;;; assignSecondary docend

              .public assignSecondary
assignSecondary:
              c=stk                 ; get return address
              rcr     -2
              pt=     4
              c=b     wpt
              rcr     -2
              pt=     1
              acex    wpt           ; C[6:0]= assignment
                                    ; C[10:7]= return address
              switchBank 1
              gosub   clearAssignment10 ; remove any existing assignment
              switchBank 2

;;; 1. Ensure there is an assignment area (with one register).
assignSecondary10:
              gosub   assignArea    ; find assign area
              goto    createAssignArea ; does not exist
;;; 2. Find an empty spot and insert the assignment there
              b=a     x             ; B.X= buffer header address
              a=c     x             ; A.X= pointer to assignment area
              a=a+1   x             ; step past first bitmap register
              c=data                ; read buffer header
              rcr     7
              a=c     s             ; A.S= number of KARs
              pt=     1
              goto    25$
20$:          acex    x
              dadd=c
              acex    x
              c=data                ; read KAR
              ?c#0    wpt           ; empty slot in lower part?
              gonc    40$           ; yes
              rcr     7
              ?c#0    wpt           ; empty slot in upper part?
              gonc    50$           ; yes
25$:          a=a+1   x             ; step ahead
              a=a-1   s
              gonc    20$
;;; 3. If no empty spot, add a register to the area, insert the assignment
;;;    in that register
              ldi     0x10          ; need one register (PT=1)
              g=c
              c=b     x             ; check that we can add one more register
              dadd=c
              c=data
              pt=     6
              c=c+1   pt
              goc     toNoRoom_B2   ; no, we have maximum of KARs
              a=a-b   x             ; A.X= offset where to add register
              abex    x
              c=b     x
              gosub   growBuffer_B2
              goto    toNoRoom_B2   ; (P+1) no space
              c=data                ; read buffer header
              pt=     6
              c=c+1   pt            ; increment KAR register counter
              data=c                ; write back
              c=b     x
              dadd=c                ; select new register
              a=0                   ; A= 0000...
              c=n
              a=c     wpt           ; A=0000..assignment
              acex
              data=c                ; write it out
              goto    60$

40$:          a=c                   ; insert assignment in low part
              c=n
              pt=     6
              a=c     wpt
              acex
              goto    55$

50$:          a=c                   ; insert assignment in upper part
              c=n
              pt=     6
              a=c     wpt
              acex
              rcr     -7
55$:          data=c                ; write back

;;; 4. Set the assignment bit
60$:          c=n
              a=c     x             ; A[1:0]= keycode
              s0=1                  ; I want secondary bitmap info
              gosub   testAssignBit10
              goto    99$           ; (P+1) no top row/no assign area
                                    ;        (should not happen)
              nop                   ; (P+2) system assigned
                                    ;        (should not happen as we cleared it)
              c=m
              c=c|a
              data=c                ; write it back
              c=n                   ; get return address back from N
              rcr     4
              golong  gotoc_B2
99$:          golong  enableBank1

;;; **********************************************************************
;;;
;;; secondaryAssignment - look up a secondary assignment
;;;
;;; Note: secondaryAssignment_B2 is an entry bank 2 that returns
;;;       in bank 1.
;;;
;;; In: N[1:0] - keycode
;;;     B.X= address of buffer header (as after testAssignBit)
;;; Out: Returns with A.M=0 if not found, if S0=1 with:
;;;        A.X= XROM Id
;;;        A.M= 0
;;;        N.X= secondary function identity
;;;      Returns with A.M=non-zero, with
;;;        A[10:7]= FAT bank switcher routine for secondary function
;;;        A[6:3]= address of secondary function
;;;        A.X= secondary function identity
;;;        active bank set for secondary
;;; Uses: A, C, B[12:10], N, PT, DADD, +2 sub levels
;;;
;;; **********************************************************************

              .public secondaryAssignment, secondaryAssignment_B2
              .extern assignArea10, secondaryAddress

              .section code1, reorder
              .shadow secondaryAssignment_B2 - 1
secondaryAssignment:
              enrom2

              .section code2, reorder
secondaryAssignment_B2:
              s0=0
              c=b     x
              a=c     x
              dadd=c
              gosub   assignArea10
              goto    99$           ; (P+1) no assignments
              c=c+1   x             ; step past bitmap registers
              bcex    x             ; B.X= pointer to assignment registers
              c=data                ; read buffer header
              rcr     7
              a=c     s             ; A.S= assignment register counter
              pt=     1
              c=n                   ; C[1:0]= keycode
              a=c     x
              goto    20$
10$:          c=data                ; read assignment register
              ?a#c    wpt           ; keycode match?
              gonc    50$           ; yes
              rcr     7             ; look at upper part
              ?a#c    wpt           ; keycode match?
              gonc    50$           ; yes
20$:          bcex    x             ; step to and select next register
              c=c+1   x
              dadd=c
              bcex    x
              a=a-1   s
              gonc    10$
99$:          a=0     m             ; A.M= 0 to indicate not found
              goto    991$          ; return via bank switch
;;; * Scan plugged in ROMs, checking Id and that it has the flag set for having
;;; * secondaries. If matching, we check if function number is in range.
50$:          s0=1                  ; There is an assignment
              rcr     5             ; C[1:0]= XROM Id
              c=0     xs            ; C.X= XROM Id
              a=c     x
              rcr     -3            ; C.X= function Id
              n=c                   ; N.X= function Id
              c=0
              pt=     6
              lc      6             ; start looking from page 6 (assuming page 3 and 5 are
                                    ;  of no interest)
              pt=     6
55$:          cxisa
              ?a#c    x             ; XROM Id match?
              gonc    60$           ; yes
57$:          c=c+1   pt
              gonc    55$
              goto    99$           ; not found
60$:          a=c     m
              pt=     5
              lc      0xf
              lc      0xf
              lc      0xe
              cxisa
              ?c#0    xs            ; are there secondaries in this ROM?
              goc     62$           ; yes
              acex    m
              goto    57$           ; no
62$:          c=n
              acex
              gosub   secondaryAddress
991$:         golong  enableBank1

;;; clearSecondaryAssignments docstart
;;; **********************************************************************
;;;
;;; clearSecondaryAssignments - clear all secondary assignments
;;;
;;; Note: This routine is in bank 2, but returns in bank 1
;;; In: Nothing
;;; Out: Nothing
;;; Uses: A, C, B, G, PT, DADD, +2 sub levels
;;;
;;; **********************************************************************
;;; clearSecondaryAssignments docend

              .section code2, reorder
              .public clearSecondaryAssignments
              .extern shrinkBuffer_B2
clearSecondaryAssignments:
              gosub   assignArea
              goto    10$           ; (P+1) no secondary assignemnts
              bcex    x             ; B.X= pointer to assignment area
              c=data                ; read buffer header
              rcr     6
              pt=     1
              lc      0             ; C[1:0]= register count - 2
              c=c+1   x             ; add 2 for bitmap registers
              c=c+1   x
              g=c                   ; G= number of registers to remove
              c=data                ; read buffer header
              pt=     6
              lc      0             ; no secondary assignments
              data=c                ; update buffer header
              bcex    x             ; C.X= offset to first register to remove
              gosub   shrinkBuffer_B2 ; remove the secondary assignment area
10$:          golong  enableBank1


;;; assignKeycode docstart
;;; **********************************************************************
;;;
;;; assignKeycode - convert key code to the way it is shown by assign
;;;
;;; Note: This routine is in bank 2, but returns in bank 1.
;;;       Code taken from Extended Functions module.
;;; In: C.X - key code as returned by C=KEYS
;;; Out: C - key code as floating point number
;;; Uses: A, C, PT, +0 sub levels
;;;
;;; **********************************************************************
;;; assignKeycode docend

              .section code2, reorder
              .public assignKeycode
assignKeycode:
              a=c     x
              pt=     0
              c=c+c   pt            ; check for OFF key
              gonc    30$           ; not OFF key
              c=0                   ; OFF key = keycode 01
              goto    40$
30$:          ldi     0xc4          ; USER, PRGM, ALPHA
              ?a<c    x             ; is it a top row key?
              goc     50$           ; no
              a=a-c   x             ; now top row keys = 00, 02, 01, 00
              c=0
              lc      3
              acex    x
              c=a-c   x             ; now top row keys = 00, 01, 02, 03
40$:          c=c+1   x             ; now top row keys = 01, 02, 03, 04
              rcr     2             ; C= 0X000000000000
              goto    80$
50$:          asl     x
              a=a+1   xs            ; 3's from the actual column
              pt=     2
              c=0
              lc      2
              c=c-1   wpt           ; C= 0x2FF (300 - 1)
60$:          a=a-c   x             ; loop to subtract 3 from old column
              gonc    60$
              ldi     0x31
              ?a#c    pt            ; row 3?
              goc     70$           ; no, skip column adjustment
              ?a#c    wpt           ; ENTER key?
              gonc    70$           ; yes, skip column adjustment
              a=a-1   x             ; correct row 3 column numbers
70$:          a=a+1   pt            ; row 0 - 7 => row 1 - 8
              acex    wpt           ; C= keycode
              rcr     3             ; make normalized form
              c=c+1   x
80$:          golong  enableBank1   ; return and restore bank 1

;;; mapAssignments docstart
;;; **********************************************************************
;;;
;;; mapAssignments - rebuild the key reassignment bit maps
;;;
;;; This is useful is key assignments are load from some external media
;;; and as a way to rebuild the key assignment maps if they have been
;;; disabled for the local auto assign labels.
;;;
;;; The procedure is as following:
;;;  1. Clear the bitmap
;;;  2. Restore the key reassignments of mainframe functions & XROM functions
;;;  3. Restore key reassignments in alpha labels; if the key has already
;;;     been assigned to another function:
;;;    A. If it is after reading in a status track, clear the key code
;;;       in the alpha label.
;;;    B. If it is after reading in a program, find the key code somewhere
;;;       else and clear it there.
;;;  4. Clear secondary bitmaps.
;;;  5. Restore secondary key assignments.
;;;
;;; In: S2=1 means we do 3A, status has been read in and we obey it.
;;;     S2=0 means 3B, user program assignments takes precedence
;;; Out: Nothing
;;; Uses: A, C, B, N, M, PT, S7, DADD, +3 sub levels
;;;
;;; **********************************************************************
;;; mapAssignments docend

              .public mapAssignments
              .section code2, reorder
mapAssignments:
              gosub   ENCP00
              c=regn  15
              c=0     m             ; clear bit map
              c=0     s
              regn=c  15
              ldi     191
;;; Get the key code from key reassignment record and set its bit
;;; in bit map.
RTKC10:       c=c+1   x
              s7=     0
              regn=c  10
              a=c
              c=regn  13
              acex
              ?a#c    x             ; reach chain head ?
              gonc    RTKC30        ; yes, done with all those registers
RTKC15:       dadd=c
              c=data
              a=c                   ; save C in A temp
              c=0     x
              dadd=c
              acex                  ; restore C
              c=c+1   s             ; still a key reassigment reg ?
              gonc    RTKC30        ; no, done with all those registers
              pt=     1
              ?s7=1                 ; first key code ?
              gonc    .+2           ; yes
              rcr     6
              ?c#0    wpt           ; is there a key code ?
              gonc    RTKC20        ; no
              a=c
              gosub   TBITMA
              gosub   SRBMAP        ; set the bit in the map
RTKC20:       c=regn  10
              ?s7=1                 ; done with second key code ?
              goc     RTKC10        ; yes
              s7=     1
              goto    RTKC15
RTKC30:       c=regn  9             ; get starting load addr
              pt=     3
              a=c     wpt
              gosub   DECADA        ; point to previous END addr
              gosub   DECADA
              c=regn  10
              acex    wpt
              regn=c  10            ; save the addr in Reg.10
RTKC40:       gosub   GTFEND
RTKC45:       pt=     3
              gosub   GTLINK
              ?c#0    x             ; chain end ?
              gonc    remapSecondary ; yes, do secondary key assignments
RTKC50:       gosub   UPLINK
              c=c+1   s             ; is it an END ?
RTKC55:       gonc    RTKC45        ; yes
              c=0     x
              dadd=c
              acex    wpt
              regn=c  9             ; save link & addr in Reg.9
              a=c     wpt
              gosub   INCAD2        ; point to key code of alpha LBL
              gosub   NXBYTA        ; get key code
              acex    wpt
              n=c
              c=0     x
              dadd=c
              c=regn  13
              m=c
              a=0     xs
              ?a#0    x             ; is there a key code ?
              gonc    RUSR40        ; no
              ?s2=1                 ; program assignment takes precedence?
              gonc    RUSR20
              c=n                   ; no, clear the global label assignment
              a=c                   ; A[3:0]= address
              c=0     x
              gosub   PTBYTA        ; clear it
              c=0     x             ; enable chip 0
              dadd=c
              goto    RUSR40
RUSR20:       b=a     x
              gosub   TBITMA        ; test the bit map
              ?c#0                  ; is this bit set ?
              gonc    RUSR30        ; no, just set it
              abex    x             ; clear key code somewhere else
              c=regn  10
              rcr     10
              bcex
              s1=     1
              gosub   GCPKC0
              goto    RUSR40
RUSR30:       gosub   SRBMAP        ; set bit map
RUSR40:       c=regn  9
              a=c
              goto    RTKC55

remapSecondary:
              gosub   assignArea
              goto    100$          ; no secondary assignments
              a=c     x             ; A.X= address of first assignment register
              c=data                ; read buffer header
              rcr     7             ; C.S= number of assign registers
              acex    x             ; C.X= address of first assignment register
              dadd=c                ; select first assignment bitmap register
              a=c                   ; A.S= number of assign registers
                                    ; A.X= address of first assignment register
              rcr     -3            ; C[5:3]= address of first assignment register
              a=c     m             ; A[5:3]= address of first assignment register
              c=0
              c=c+1                 ; make non-zero
              data=c                ; clear first bitmap register
              a=a+1   x             ; A.X= address of second assignment register
              acex
              dadd=c
              acex
              data=c                ; clear second bitmap register
              goto    40$           ; A.X= points to first assignment register
                                    ; A[5:3]= address of first
                                    ;         assignment bitmap register
                                    ; A.S= number of assignment registers - 1

10$:          c=data
              ?s7=1                 ; first key code?
              gonc    12$           ; yes
              rcr     7
12$:          pt=     1
              ?c#0    wpt           ; is there a key code ?
              gonc    20$           ; no
              acex                  ; A.X= key code 1-80 form
              n=c                   ; N= counters
              gosub   testAssignBit
              goto    15$           ; (P+1) not assigned (yet)
              goto    30$           ; (P+2) primary assigned
15$:          c=m
              c=c|a
              data=c
              c=n
              dadd=c                ; select current assignment register
              a=c                   ; A= counters
20$:          ?s7=1                 ; done with second key code?
              goc     40$           ; yes
              s7=1                  ; no
              goto    10$

30$:          c=n                   ; primary assignment exist
              dadd=c                ;   disable the secondary assignment
              a=c                   ; A= counters
              c=data
              pt=     1
              ?s7=1                 ; in upper half?
              gonc    31$           ; no, lower half
              pt=     8
31$:          lc      0
              lc      0
              data=c
              goto    20$

40$:          a=a+1   x
              acex    x
              dadd=c                ; select next register
              acex    x
              s7=0
              a=a-1   s
              gonc    10$
100$:         golong  enableBank1
