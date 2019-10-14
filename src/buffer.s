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
;;;   ID SZ KA BF SH DF ST
;;; where
;;;   ID - buffer ID
;;;   SZ - buffer size
;;;   KA - offset to first secondary KAR, 00 means no secondary KAR
;;;   BF - number of hosted buffers
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
;;; Uses: A, C, B.X, active PT=12, DADD, +0 sub levels
;;;
;;; Note: For chkbuf, buffer number in C[0] and C[2:1] must be zero!!!
;;;       Use 'ldi' or 'c=0 x' to ensure that.
;;;
;;; This routine is called at every light sleep wake up, so it has to
;;; be fast.
;;;
;;; Typical execution time (here) is:
;;;
;;;   13 + KARs * 12 + otherBufs * 17 + 16 if found
;;;
;;; So for 8 assignments and skipping 2 buffers, it would take 111 cycles
;;; or 16ms on a standard HP-41. A 50x NEWT would be about 10 times faster
;;; as it needs to access status register 13 once, then each KAR and one
;;; for each buffer header.
;;;
;;; Does not call any subroutines (must not, because it can be called
;;; during partial key sequences).
;;;
;;; **********************************************************************

              .section code
              .public sysbuf, chkbuf
sysbuf:       ldi     15
chkbuf:       dadd=c                ; select chip 0
              pt=     12
              rcr     2
              ldi     0xc0 - 1
              a=c                   ; A[12] = desired buffer,
                                    ; A.X = start address - 1
              c=regn  c
              bcex    x             ; B.X= chain head address

1$:           a=a+1   x             ; start of search loop
2$:           c=b     x             ; C.X= chain head .END.
              ?a<c    x             ; have we reached chainhead?
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
;;; getbuf - get a buffer
;;;
;;; Ensure that we have a buffer. Buffer is only created if there is room for
;;; two registers, but we actually only write a single header register.
;;; The reason is that in order to store anything, we need to have at least
;;; 2 registers, so there is no point of creating anything otherwise.
;;;
;;; If not found, return to (P+1)
;;; If found, return to (P+2) with:
;;;   A.X = address of buffer start register
;;;   DADD = first address of buffer
;;; Uses: A, C, B.X, active PT=12, DADD, +1 sub level
;;;
;;; **********************************************************************

              .section code
              .public getbuf

getbuf:       gosub   sysbuf
              goto    10$           ; need to create buffer
5$:           golong  RTNP2         ; buffer exists

10$:          b=a     x             ; B.X= first free register
              c=0     x
              dadd=c                ; select chip 0
              gosub   MEMLFT
              a=c     x
              ldi     2             ; ensure at least 2 free registers
              ?a<c    x
              rtnc                  ; no room, return to (P+1)
              c=b     x
              dadd=c                ; select header
              a=c                   ; A.X= buffer start address
              c=0                   ; header= 1F010000000000
              pt=     13
              lc      1
              lc      15            ; buffer 15
              lc      0
              lc      1
              data=c
              goto    5$


;;; **********************************************************************
;;;
;;; insertShell - insert a shell register on top of stack
;;;
;;; In: A.X= buffer header address
;;;     M= contents to write to the new register
;;; If no room for inserting a register, return to (P+1)
;;; If register was inserted, return to (P+2) with:
;;; Out: A.X= buffer header address
;;;      B.X= the location of the newly added space
;;; Uses: A, B, C, G, DADD, active PT set to 10, +1 sub level
;;;
;;; **********************************************************************

              .section code
              .public insertShell
insertShell:  ldi     1
              pt=     0
              g=c
              gosub   openSpace
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
;;; openSpace - add space to buffer
;;;
;;; In: A.X= buffer header address
;;;     C.X= offset where to add registers
;;;     G= number of registers to add
;;; Out: Returns to P+1 if it is not possible to grow the buffer
;;;      Returns to P+2 if successful
;;;      B.X= the location of the newly added space
;;;      A.X= buffer header address
;;; Uses: A, B, C, G, DADD, active PT set to 10, +0 sub levels
;;;
;;; **********************************************************************

              .public openSpace
              .section code
openSpace:    b=a     x             ; B.X= buffer header
              a=a+c   x             ; A.X= where we want to open space
              c=0
              dadd=c
              pt=     3
              c=g
              a=c     m             ; A.M= counter

              c=regn  13
              acex    x             ; A.X= free memory pointer (at .END. now)
              bcex    x             ; B.X= where to open space
              rcr     -3
              bcex    m             ; B[5:3]= buffer header pointer


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

10$:          c=0     m
              pt=     10
              c=g
              a=c     m             ; A[11:10]= number of registers to add
                                    ; rest of A.M is zero
              c=b     m
              rcr     3             ; C.X= buffer header address
              dadd=c
              c=data                ; load buffer header
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
              c=data                ; C= register contents to move
              acex
              rcr     3
              c=c-1   x             ; C.X= destination pointer
              dadd=c
              rcr     -3
              acex
              data=c                ; write moved value to destination
              ?a<b    x             ; are we done?
              gonc    15$           ; no

              c=b     m
              rcr     3
              a=c     x             ; A.X= buffer header
              golong  RTNP2         ; done, return to (P+2)
