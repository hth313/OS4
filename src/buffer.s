;;; **********************************************************************
;;;
;;;           OS extension for the HP-41 series.
;;;
;;; System buffer.
;;;
;;; **********************************************************************

              #include "mainframe.i"

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
;;; Buffer header:
;;;   ID SZ KA 'SC:BF' SH DF ST
;;; where
;;;   ID - buffer ID
;;;   SZ - buffer size
;;;   KA - offset to first secondary KAR, 00 means no secondary KAR
;;;   BF - number of hosted buffers (single digit, 0-15 buffers possible)
;;;   SC - number of transient application scratch registers
;;;   SH - number of shell registers
;;;   DF - Default postfix byte during semi-merged argument entry.
;;;   ST - system buffer status flags, see OS4.h
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
;;;   These defines key assignments of secondary FAT entries. They are defined
;;;   as follows:
;;;     F0 XRSC KK XRSC KK
;;;   where
;;;     F0 - Is the usual KAR marker, which will not cause problems as it is
;;;          held inside a buffer.
;;;     XRSC - The function, XR is the XROM# 1-31 left shifted 3 steps to
;;;            align it with the highest bits. The lower 11 bits is the
;;;            index in the secondary FATs. Primary FAT instructions use
;;;            the normal assignment mechanism.
;;;            This allows for selecting any of the first 2048 secondary
;;;            FAT entries for a key.
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
;;; If not found, return to (P+1)
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
              rtnnc                 ; yes, we are out of spaace
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
;;;      Returns to P+2 if secondary KARs exists
;;;      A.X - address of first secondary KAR
;;;      B.X - address of chain head
;;; Uses: A, C, B.X, active PT=12, DADD, +1 sub levels
;;;
;;; Note: While scanning secondary KARs, you need to check both that
;;;       the register has F in nibble 13 and that the address is below
;;;       chain head (B.X). The routine stepKAR can be used for this.
;;;
;;;       If this routine indicates (by returning to P+2) that there are
;;;       secondary KARs, there will be at least one such register.
;;;
;;; **********************************************************************

              .public findKAR2
              .extern RTNP2
findKAR2:     gosub   sysbuf
              rtn                   ; no system buffer, return to P+1
              rcr     8             ; C[1:0] = secondary KAR offset
              c=0     xs
              ?c#0    x
              rtnnc                 ; no secondary KARs, return to P+1
              a=a+c   x             ; A.X= address of first secondary KAR
                                    ; (assume this can not give carry)
relayRTNP2:   golong  RTNP2         ; return to (P+2)


;;; **********************************************************************
;;;
;;; stepKAR - step to next KAR
;;;
;;; In: A.X - address of current KAR
;;;     B.X - address of chain head
;;; Out: Returns to P+1 if no more KAR
;;;      Returns to P+2 if there is a next KAR
;;;           A.X - incremented KAR pointer
;;;           C[12:0] - contents of that register
;;;           C[13] - 0
;;;           B.X - address of chain head
;;;           DADD - next KAR
;;; Uses: C, +0 sub levels, DADD
;;;
;;; **********************************************************************

              .public stepKAR
              .extern noRoom
stepKAR:      a=a+1   x             ; step to next KAR
              c=b     x             ; C.X= chain head .END.
              ?a<c    x             ; have we reached chainhead?
              rtnnc                 ; yes
              acex    x             ; no, select next register
              dadd=c
              acex    x
              c=data                ; read it
              c=c+1   s             ; is it a KAR?
              goc     relayRTNP2    ; yes
              rtn                   ; no


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
              rcr     4             ; C[1:0]= offset to secondary KAR
              pt=     1
              ?c#0    wpt           ; do we host secondary KARs?
              gonc    10$           ; no
              c=c+1   x             ; yes, bump offset
10$:          rcr     -8            ; re-align C
              data=c                ; write back updated header
              golong  RTNP2         ; all good, return to (P+2)


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
;;; Uses: A, B, C, G, DADD, active PT set to 10, +2 sub levels
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
              c=data                ; read buffer header
              rcr     4
              c=0     xs
              c=c+1   x             ; C.X= offset to scratch area to be

;;; !!! Fall into growBuffer !!!

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
;;; Uses: A, B, C, G, DADD, active PT set to 10, +1 sub levels
;;;
;;; **********************************************************************

              .public growBuffer
growBuffer:   gosub buffer1

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

              data=c                ; write back updated header

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
              rcr     4             ; C[1:0]= number of shell registers
              c=0     xs            ; C.X= number of shell registers
              c=c+1   x             ; C.X= index of scratch area
              pt=     4
              lc      0             ; C[3:4]= size of scratch area
              g=c                   ; G= size of scratch area

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
              a=a+c   x             ; A.X= where we want to open space
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
;;; Convert buffer pointer to a scratch area pointer. It is only sensible
;;;
;;; In: Nothing
;;; Out: A.X - pointer to scratch area
;;;      C[3] - size of scratch area (0-15 registers)
;;; Uses: A[12], A.X, C, B.X, active PT=12, DADD, +1 sub levels
;;;
;;; **********************************************************************

              .section code, reorder
              .public scratchArea
scratchArea:  gosub   sysbuf
              rtn                   ; (P+1) no system buffer
              c=data
              rcr     4
              c=0     xs
              c=c+1   x
              a=a+c   x
              rtn
