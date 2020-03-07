;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;; System buffer.
;;;
;;; **********************************************************************

#include "mainframe.h"

;;; **********************************************************************
;;;
;;; The system buffer keeps track of the following:
;;;
;;; 1. Shell stack, which describes alternative key handler and display
;;;    routines, in a stacked fashion. A Shell can only appear once
;;;    in the stack. See below for details.
;;;
;;; 2. Hosted I/O buffers. These are buffers held inside the system buffer.
;;;    They form an alternative numeric series, and allows for up to 128
;;;    additional buffers. Typically useful for applications that need
;;;    a private storage area. The buffer header is very similar to the
;;;    ordinary I/O buffer, but has a slightly more strict buffer number
;;;    encoding.
;;;
;;; 3. Secondary key assignments. These keeps track of key assignment of
;;;    functions that belong to secondary FATs, allowing such extension
;;;    instructions to be assigned to keys.
;;;
;;; Buffer layout:
;;;        [ application temporary scratch  ] 0-15   high address
;;;        [ secondary key assignments      ] 0-17
;;;        [ hosted buffer area             ] 0-254
;;;        [ shell stack                    ] 0-254
;;;        [ buffer header                  ] 1      low address
;;;
;;; Buffer header:
;;;   ID SZ BF 'SC:KA' SH DF ST
;;; where
;;;   ID - buffer ID
;;;   SZ - buffer size
;;;   BF - size of hosted buffer area
;;;   SC - number of transient application scratch registers,
;;;        single nibble, 0-15 registers allocated at top
;;;   KA - number of secondary assignment registers, 0-30 such
;;;        assignments possible
;;;   SH - number of shell registers
;;;   DF - Default postfix byte during semi-merged argument entry.
;;;   ST - system buffer status flags, see OS4.h
;;;
;;;
;;; Shell stack register:
;;;   Two entries in each register, defined as follows
;;;     ADDR F XR
;;; where
;;;   F - a status nibble (sys/app)
;;;   XR - XROM# of the module owning the entry
;;;   ADDR - The address within the module page that defines the Shell
;;;          structure. If the top nibble here is 0, it means that it
;;;          is an unused entry, all other bits are no-care.
;;;  Note: Once allocated, we allow at least one empty Shell stack register to
;;;        stay behind unused. This is because it is anticipated that we may
;;;        push something onto the stack again. In other words, we are not
;;;        eager to reclaim memory as soon as a single register becomes free.
;;;
;;;  Hosted buffers:
;;;    Highest two nibbles are the buffer number, 0-127. If the highest bit is
;;;    set, it is a buffer that is marked for deletion. Hence, to check the
;;;    validity of the header:
;;;         c=data
;;;         c=c+c s
;;;         goc   unused entry
;;;    Or when scanning for a buffer, compare C[13:12] (as an invalid buffer
;;;    will have the highest bit set and shall not match any valid buffer ID.
;;;
;;; Secondary assignments:
;;;   The first two registers are the secondary bitmaps, much like register 10
;;;   and 15 in the system area. The idea is that system assignments takes
;;;   precedence and shadows these bits.
;;;   The size is therefore 0, 3, 4, .. 17 registers as we always allocate
;;;   the two bitmap registers for the first secondary assignment.
;;;   These defines key assignments of secondary FAT entries. They are defined
;;;   as follows:
;;;     XR-FFF-KK XR-FFF-KK
;;;   where
;;;     XR - The XROM Id
;;;     FFF - The secondary function
;;;     KK - the key used
;;;
;;; **********************************************************************



;;; **********************************************************************
;;;
;;; sysbuf - locate the system buffer, number 15
;;; chkbuf - locate buffer with ID in C.X
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
;;; Note: For chkbuf, buffer number in C[0] and C[2:1] must be zero!!!
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

              .section code, reorder
              .public sysbuf, chkbuf
sysbuf:       ldi     15
chkbuf:       dadd=c                ; select chip 0
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
              gonc    relayRTNP2    ; yes, return to (P+2)
              rcr     10            ; wrong buffer, skip to next
              c=0     xs
              a=a+c   x
              goto    2$

;;; **********************************************************************
;;;
;;; ensureBuffer - find or create an empty buffer
;;; ensureSysBuf - same for system buffer
;;;
;;; Like chkbuf, but will create the buffer with only a header if it
;;; does not previously exist.
;;;
;;; In: C.X - buffer ID
;;; If not existing and cannot be created (not free space), return to (P+1)
;;; If found, return to (P+2) with:
;;;   A.X = address of buffer start register
;;;   DADD = first address of buffer
;;;   C[13] part of buffer header incremented
;;;   C[12:7] = part of buffer header
;;;   C[2:0] = part of buffer header
;;; Uses: A, C, B.X, PT, DADD, +1 sub levels
;;;
;;; **********************************************************************

              .public ensureBuffer, ensureSysBuf
ensureSysBuf: ldi     15
ensureBuffer: gosub   chkbuf
              goto    10$           ; (P+1) need to create it
              goto    relayRTNP2    ; (P+2) already exists
10$:          ?a<b    x             ; have we reched chainhead?
              rtnnc                 ; yes, we are out of space
              c=0                   ; build buffer header
              c=c+1   s             ; 100000000...
              acex    pt            ; 1b0000000... (where b is buffer number)
              pt=     10
              lc      1             ; 1b0100000...
              data=c
              goto    relayRTNP2

;;; **********************************************************************
;;;
;;; findKAR2 - locate the first secondary KAR
;;;
;;; findKAR2 can typically be used by routines that want to access all
;;;   key assignment registers. After doing the normaly ones, this
;;;   routine can be used to find the start of secondary ones.
;;;
;;; In: Nothing
;;; Out: Returns to P+1 if no secondary KARs
;;;      Returns to P+2 if secondary KARs exists with:
;;;      A.X - address of first secondary KAR
;;;      A.S - number of secondary KARs - 1
;;; Uses: A, C, B.X, active PT=12, DADD, +1 sub levels
;;;
;;; **********************************************************************

              .public findKAR2
              .extern RTNP2
findKAR2:     gosub   sysbuf
              rtn                   ; no system buffer, return to P+1
              c=data
              rcr     7
              ?c#0    s             ; any key assignments?
              rtnnc                 ; no, return to P+1
              a=c     s             ; A.S= number of secondary KARs
              a=a-1   s             ; start at 0 counter
              rcr     7 + 4
              c=0     xs
              a=a+c   x             ; step past shell area
              rcr     4
              c=0     xs
              a=a+c   x             ; step past hosted buffers
              a=a+1   x             ; and buffer header
relayRTNP2:   golong  RTNP2         ; return to (P+2)

;;; **********************************************************************
;;;
;;; reclaimSystemBuffer - ensure the system buffers stays at power on
;;;
;;; This entry is intended for modules that uses the functionality
;;; provided by the system buffer, but does not use any shell.
;;; In that case, call this routine from the deep wake-up polling
;;; point to reclaim the system buffer.
;;;
;;; Uses: C, +1 sub level, DADD
;;; **********************************************************************

              .public reclaimSystemBuffer
reclaimSystemBuffer:
              gosub   sysbuf
              rtn
              c=data
              c=0     s
              c=c+1   s
              data=c
              rtn

;;; **********************************************************************
;;;
;;; insertShell - insert a shell register on top of stack
;;;
;;; In: A.X= buffer header address
;;;     C.X= offset to insert at (insertShellC)
;;;     B.X= address to insert at (insertShellB)
;;;     M= contents to write to the new register
;;; If no room for inserting a register, return to (P+1)
;;; If register was inserted, return to (P+2) with:
;;; Out: A.X= buffer header address
;;;      B.X= the location of the newly added space
;;; Uses: A, B, C, G, DADD, active PT set to 10, +1 sub level
;;;
;;; **********************************************************************

              .section code, reorder
              .public insertShellC, insertShellB
insertShellB: abex    x
              a=a-b   x             ; A.X= offset to insert at
              abex    x             ; B.X= offset to insert at
              goto    insertShell10
insertShellC: bcex    x             ; B.X= offset to insert at

insertShell10:
              ldi     1
              pt=     0
              g=c
              bcex    x
              gosub   growBuffer
              rtn                   ; (P+1) no room
              c=b     x             ; (P+2) C.X= newly created space
              dadd=c
              c=m                   ; get register contents to write
              data=c                ; write it out
              acex    x
              dadd=c                ; select header register
              acex    x
              c=data                ; C= buffer header
              rcr     4
              c=c+1   x             ; increase number of shell registers
                                    ;  (cannot overflow due to max buffer size)
              rcr     -4
              data=c                ; write back updated header
              golong  RTNP2

;;; **********************************************************************
;;;
;;; scratchOffset - get offset to scratch area
;;;
;;; In: A.X= buffer header address (selected)
;;; Out: C.X= offset to scratch area
;;;      A.X= buffer header address
;;; Uses: C, A.S, A.X, B.X
;;;
;;; **********************************************************************

              .section code, reorder
scratchOffset:
              b=a     x             ; B.X= buffer header address
              c=data                ; read buffer header
              rcr     5
              c=0     xs
              csr     x             ; C.X= key assignment size
              a=c     x             ; A.X= key assignment size
              rcr     2             ; C[1:0]= hosted buffer size
              ?a#c    x             ; do we have any key assignments?
              gonc    5$            ; no
              c=c+1   x             ; yes, add two for bitmap registers
              c=c+1   x
5$:           a=a+c   x             ; A[1:0]= key assignment + buffer sizes
              rcr     11            ; C[1:0]= shell registers
              c=c+1   x             ; add one for buffer header
              c=a+c   x             ; C[1:0]= offset to scratch area
              c=0     xs            ; C.X= offset to scratch area
              abex    x             ; A.X= buffer header address
              rtn

;;; **********************************************************************
;;;
;;; allocScratch - allocate (ensure) a given scratch size
;;;
;;; Allocate the scratch register area meant for transient applications.
;;; If the area is currently allocated it is assumed to be a left-over
;;; from a previous scratch register allocation and we will free that
;;; one first if not of the requested size.
;;;
;;; In: C[0] = size of scratch area (1-15)
;;; Out: Returns to P+1 if it is not possible to grow the buffer
;;;      Returns to P+2 if successful
;;;      B.X= the location of the newly added space
;;;      A.X= buffer header address
;;;      DADD= buffer header address
;;; Uses: A, B, C, G, S7, DADD, active PT set to 10, +2 sub levels
;;;
;;; **********************************************************************

              .public allocScratch
              .section code, reorder
allocScratch: rcr     -7
              a=c
              rcr     8
              bcex    s             ; B.S= # of registers to allocate
              gosub   ensureSysBuf
              rtn                   ; (P+1) no room
              c=data                ; read buffer header
              pt=     7
              ?c#0    pt
              gonc    10$           ; no previous allocation
              ?a#c    pt            ; same allocation?
              gonc    10$           ; yes
              gosub   clearScratch1 ; no, clear old one
10$:          c=b                   ; C[13] = size to allocate
              c=0     x
              rcr     -1
              pt=     0
              g=c                   ; G= size to allocate
              gosub   scratchOffset
              s7=1                  ; tell growBuffer we are adding to scratch
              goto    growBuffer10

;;; **********************************************************************
;;;
;;; growBuffer - add space to buffer
;;;
;;; Open up some register space inside a buffer. Newly allocated registers
;;; are filled with F000000000000 for two reasons. First to ensure that
;;; if we add space at the top of a buffer, it has to be non-zero, which
;;; relieves the "burden" from the caller. Second, it helps with debugging
;;; as new registers have a known static value rather than garbage that may
;;; look like active data in the buffer.
;;;
;;; In: A.X= buffer header address
;;;     C.X= offset where to add registers
;;;     G= number of registers to add
;;; Out: Returns to P+1 if it is not possible to grow the buffer
;;;      Returns to P+2 if successful
;;;      B.X= the location of the newly added space
;;;      A.X= buffer header address
;;;      DADD= buffer header address
;;; Uses: A, B, C, G, DADD, S7, active PT, +1 sub levels
;;;
;;; **********************************************************************

              .public growBuffer
growBuffer:   s7=0
growBuffer10: gosub   buffer1

;;; Ensure there is available space and step down the read pointer.
4$:           a=a-1   x             ; step to next register
              a=a-1   m             ; are we done?
              goc     10$           ; yes
              acex    x             ; no, inspect register
              dadd=c
              acex    x
              c=data
              ?c#0
              gonc    4$
              rtn                   ; return to (P+1), not enough space

10$:          gosub buffer2
              c=a+c   m             ; increase size of buffer
              rtnc                  ; return to (P+1) if buffer size overflows
                                    ; We know that buffer is F, so an overflow
                                    ; carry will ripple to outside of M field.

              ?s7=1                 ; are we growing scratch area?
              gonc    12$           ; no
              a=c     m             ; yes
              pt=     7
              c=g                   ; insert scratch size
              a=c     pt
              acex    m
12$:          data=c                ; write back updated header

              c=0     x             ; select chip 0
              dadd=c
              c=regn  13            ; C.X= chain head .END.
              rcr     -3
              a=c     m             ; A[5:3]= write pointer + 1

15$:          acex    x             ; C.X= read pointer
              dadd=c
              acex    x
              a=a-1   x
              c=data                ; C= register data to move
              acex
              rcr     3
              c=c-1   x             ; C.X= destination pointer
              dadd=c
              rcr     -3
              acex
              data=c                ; write moved value to destination
              ?a<b    x             ; are we done?
              gonc    15$           ; no

              pt=     0             ; fill the opened area with F0000...
              c=g
              c=0     xs

              a=c     x             ; A.X= number of registers opened

              a=a+b   x             ; A.X= top address of area + 1
              abex    x             ; B.X= top address of area + 1
                                    ; A.X= bottom address of area

20$:          bcex    x             ; write top down to bottom
              c=c-1   x
              dadd=c
              bcex    x
              c=0
              c=c-1   s             ; C= F0000....
              data=c
              ?a<b    x
              goc    20$
              c=b     m
              rcr     3
              dadd=c
              a=c     x             ; A.X= buffer header address
              golong  RTNP2         ; done, return to (P+2)

;;; **********************************************************************
;;;
;;; clearScratch - remove transient application scratch area
;;; requestTransientAppScratch - allocate a transient scratch area
;;;
;;; A transient application can set up a transient scratch area typically
;;; to store its state. This works because there can only be one active
;;; transient application and making one active means
;;;
;;; In: Nothing
;;; Out: A.X= buffer header address
;;;      DADD= buffer header address
;;; Uses: A, B[12:0], C, M, G, DADD, active PT set to 0, +1 sub levels
;;;
;;; **********************************************************************

              .public clearScratch
              .section code, reorder
clearScratch:
              gosub   sysbuf
              rtn                   ; (P+1) no system buffer
              c=data                ; (P+2) read buffer header
              pt=     7
              ?c#0    pt            ; is something allocated?
              rtnnc                 ; no, we are done

clearScratch1:
              a=c     pt
              c=0     pt            ; clear SC in buffer header
              data=c                ; write back
              acex    pt
              pt=     8
              lc      0             ; C[8:7]= size of scratch area
              g=c                   ; G= size of scratch area
              gosub   scratchOffset

;;; !!! Fall into shrinkBuffer !!!

;;; **********************************************************************
;;;
;;; shrinkBuffer - remove registers from a buffer
;;;
;;; Remove a given number of registers from a buffer (at a given offset).
;;; There are no error checking here, you better know that you have a
;;; buffer that can drop this number of registers. Garbage or incorrect
;;; input will forsure corrupt the memory!
;;;
;;; In: A.X= buffer header address
;;;     C.X= offset of first register to remove
;;;     G= number of registers to remove
;;; Out: A.X= buffer header address
;;;      DADD= buffer header address
;;; Uses: A, B[12:0], C, M, G, DADD, active PT set to 0, +1 sub levels
;;;
;;; **********************************************************************

              .public shrinkBuffer
shrinkBuffer: gosub   buffer1
              gosub   buffer2
              acex    m
              c=a-c   m             ; adjust buffer size
              data=c                ; write back updated buffer header

              abex    x             ; A.X= first register to remove
                                    ; B.X= chain head
              pt=     0
              c=g
              c=0     xs            ; C.X= number of registers to remove
              c=a+c   x             ; C.X= read copy pointer
              acex    x             ; A.X= read copy pointer
              m=c                   ; M.X= write copy pointer

10$:          acex    x
              dadd=c
              acex    x
              a=a+1   x
              c=data                ; read register to copy
              cmex
              dadd=c
              c=c+1   x
              cmex
              data=c                ; write it
              ?a<b    x             ; reached chain head?
              goc     10$           ; not yet
              c=b     m
              rcr     3
              dadd=c
              a=c     x             ; A.X= buffer header address
              rtn

;;; Support routine for growBuffer/shrinkBuffer
              .section code, reorder
buffer1:      b=a     x             ; B.X= buffer header address
              a=a+c   x             ; A.X= where we want to open/close space
              c=0
              dadd=c
              pt=     3
              c=g
              a=c     m             ; A.M= counter

              c=regn  13
              acex    x             ; A.X= chain head (pointer to .END.)
              bcex    x             ; B.X= where to open space
              rcr     -3
              bcex    m             ; B[5:3]= buffer header address
              rtn

;;; Support routine for growBuffer/shrinkBuffer
              .section code, reorder
buffer2:      c=0     m
              pt=     10
              c=g
              a=c     m             ; A[11:10]= number of registers to adjust
                                    ; rest of A.M is zero
              c=b     m
              rcr     3             ; C.X= buffer header address
              dadd=c
              c=data                ; load buffer header
              rtn

;;; **********************************************************************
;;;
;;; scratchArea - get pointer to transient application scratch area
;;;
;;; This routine assumes that the scratch area exists!!!
;;;
;;; In: Nothing
;;; Out: C.X - pointer to scratch area
;;;      A.X - address of buffer header
;;;      C[3] - size of scratch area (0-15 registers)
;;;      DADD - first scratch register selected
;;; Uses: A[12], A.X, C, B.X, active PT=12, DADD, +1 sub level
;;;
;;; **********************************************************************

              .section code, reorder
              .public scratchArea
scratchArea:  gosub   sysbuf
              rtn                   ; (P+1) no system buffer
              gosub   scratchOffset
              c=a+c   x
              dadd=c
              rtn

;;; **********************************************************************
;;;
;;; assignArea - get pointer to secondary assignment area
;;;
;;; In: Nothing
;;; Out: Returns to (P+1) if there is no assignment area
;;;      Returns to (P+2) if there are secondary assignments, with
;;;          C.X - pointer to assignment area
;;;          A.X - address of buffer header
;;;          DADD - buffer header
;;; Uses: A[12], A.X, C, B.X, active PT=12, DADD, +1 sub level
;;;
;;; **********************************************************************

              .section code, reorder
              .public assignArea, assignArea10
assignArea:   gosub   sysbuf
              rtn                   ; (P+1) no system buffer
              b=a     x             ; B.X= buffer header address
assignArea10: c=data                ; read buffer header
              pt=     6
              ?c#0    pt            ; are there any assignments?
              rtnnc                 ; no
              rcr     4
              c=0     xs            ; C.X= shell area size
              a=a+c   x
              rcr     4
              c=0     xs            ; C.X= buffer area size
              c=a+c   x             ;
              c=c+1   x
              abex    x             ; A.X= buffer header address
              golong  RTNP2

;;; **********************************************************************
;;;
;;; hostedBufferSetup - get pointer to hosted buffer area
;;;
;;; In: Nothing
;;; Out: Returns to (P+1) if there is no hosted buffer area
;;;      Returns to (P+1) if the hosted buffer area exists with:
;;;          A.X= start of hosted buffer area
;;;          A.M= number of registers in area - 1
;;; Uses: A[12:0], C, PT, DADD, +1 sub level
;;;
;;; **********************************************************************

              .section code, reorder
hostedBufferSetup:
              gosub   sysbuf
              rtn                   ; no system buffer
              c=data                ; read buffer header
              rcr     4
              c=0     xs            ; C.X= size of shell stack
              c=c+1   x             ; add one for buffer header
              a=a+c   x             ; A.X= start of buffer area
              rcr     3
              c=0     m             ; C[12:1]= number of registers in buffer area
              rcr     -2            ; C.M= number of registers in buffer area
              a=c     m             ; A.M= number of registers in buffer area
              a=a-1   m             ; A.M= number of registers in buffer area - 1
              rtnc                  ; no hosted buffers
              golong  RTNP2

;;; **********************************************************************
;;;
;;; newHostedBuffer - reserve space for a hosted buffer.
;;;
;;; Typical use is to call chkbufHosted to find a specific buffer.
;;; If it is not there, it can be created using createBufHosted.
;;; !! NOTE: This routine assumes that the hosted buffer does not exist !!
;;;
;;; In: C[1:0] = size of buffer
;;;     N[1:0] = buffer number 0-127
;;;
;;; If out of memory, returns to (P+1)
;;; If successful, returns to (P+2) with:
;;;      A.X = hosted buffer header address
;;;      DADD = hosted buffer header
;;; Uses: A, B, C, N, G, DADD, S7, active PT, +2 sub levels
;;;
;;; **********************************************************************

              .section code, reorder
              .public newHostedBuffer
newHostedBuffer:
              pt=     0
              g=c                   ; G= number of registers to reserve
              gosub   ensureSysBuf
              rtn
              c=data                ; read buffer header
              rcr     4
              c=0     xs            ; C.X= size of shell stack
              c=c+1   x             ; add one for buffer header
              gosub   growBuffer
              rtn
              c=0     m
              pt=     8
              c=g
              a=c     m             ; A[9:8]= size of this buffer
                                    ; rest of A.M cleared
              c=data
              c=a+c   m             ; update hosted buffer size
              data=c
              c=b     x             ; C.X= address of hosted buffer header
              dadd=c                ; select header register
              c=n
              rcr     2             ; C[13:12]= buffer number
              pt=     10
              c=g                   ; C[11:10]= buffer size
              data=c                ; write buffer header
              abex    x             ; A.X= address of buffer header
              golong  RTNP2

;;; **********************************************************************
;;;
;;; chkbufHosted - find a hosted buffer
;;;
;;; Locate a secondary buffer.
;;;
;;; In: C[1:0]= buffer number
;;; If not found, return to (P+1)
;;; If found, return to (P+2) with:
;;;   A.X= hosted buffer header address (selected)
;;; Uses: A, C, B.X, G, active PT, +1 sub level
;;;
;;; **********************************************************************

              .section code, reorder
              .public chkbufHosted
chkbufHosted: pt=     0
              g=c                   ; G= buffer number we are looking for
              gosub   hostedBufferSetup
              rtn                   ; no buffer
              pt=     0
              c=g                   ; C[1:0]= buffer number we are looking for
              bcex    x             ; B[1:0]= buffer number we are looking for
              pt=     1
10$:          acex    x             ; C.X= buffer header address
              dadd=c
              acex    x
              c=data                ; read a buffer header
              rcr     12            ; C[1:0]= buffer identity
              abex    x             ; A.X= buffer we are looking for
              ?a#c    wpt           ; is this the buffer we are looking for?
              gonc    20$           ; yes
              abex    x             ; A.X= buffer header address
                                    ; B.X= buffer we are looking for
              rcr     -2            ; C[1:0]= size
              c=0     xs            ; C.X= size
              a=a+c   x             ; advance to next buffer header
              c=0     m
              rcr     -3            ; C.M= size
              a=a-c   m             ; reduce remaining registers
              gonc    10$
              rtn                   ; no more

20$:          abex    x             ; A.X= buffer header address
              golong  RTNP2         ; done, return to (P+2)

;;; **********************************************************************
;;;
;;; reclaimHostedBuffer
;;;
;;; Reclaim a hosted buffer, typically called at power on by modules that
;;; want to retain a hosted buffer.
;;;
;;; In: Nothing
;;; Out: Nothing
;;; Uses: A, C, B.X, N, active PT=12, +2 sub levels
;;;
;;; **********************************************************************

              .section code, reorder
              .public reclaimHostedBuffer
reclaimHostedBuffer:
              gosub   chkbufHosted
              rtn
              c=data                ; clear upper bit in buffer
              rcr     -2
              cstex
              s7=0
              cstex
              rcr     2
              data=c
              rtn

;;; **********************************************************************
;;;
;;; releaseHostedBuffers - release all hosted buffers
;;;
;;; Mark all hosted buffers for removal.
;;;
;;; **********************************************************************

              .section code, reorder
              .public releaseHostedBuffers
releaseHostedBuffers:
              gosub   hostedBufferSetup
              rtn                   ; (P+1) no buffers
              pt=     13
              lc      8
              a=c     s             ; A.S= 8
10$:          acex    x
              dadd=c
              acex    x
              c=data
              c=a+c   s             ; set mark bit
              gonc    15$
              c=a+c   s             ; was set before, set it again
15$:          data=c
              rcr     10
              c=0     xs            ; C.X= size of this buffer
              a=a+c   x             ; advance pointer
              c=0     m
              rcr     -3
              a=a-c   m             ; decrement register counter
              gonc    10$
              rtn


;;; growHostedBuffer


;;; shrinkHostedBuffer
