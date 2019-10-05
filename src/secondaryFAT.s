

;;; **********************************************************************
;;;
;;; Secondary function address tables (FAT).
;;;
;;; These are used to break the limit of having 64 instructions in a
;;; single 4K page.
;;;
;;; A secondary function can be described by:
;;; XROM i,sub#
;;;    where sub# is the sub function number.
;;; The lowest 1023 (0-1022) can be bound to a key on a shell keyboard.
;;; Sub functions 0-2047 can be assigned to keys.
;;; (From programs and by name, up to 4K are possible, but for practical
;;; reasons it is probably best to keep within 2K secondary instructions,
;;; you are probably going to run out of memory before using them up
;;; anyway).
;;;
;;; The following structure is a secondary FAT header:
;;;   .con  .low12 next       ; points to next secondary FAT header,
;;;                           ;     or 0 to mark end
;;;   .con  entries           ; number of entries in this header table
;;;   .con  jprefix           ; the XROM j that acts as the prefix for
;;;                           ;     this secondary FAT
;;;   .con  startIndex        ; first entry is encoded as sub index # for XROM j
;;;   .con  .low12 switchBank ; func to switch to the bank where
;;;                           ;     actual table is
;;;   .con  location          ; location of FAT and routines
;;;                           ;     (potentially in other bank)
;;;
;;; Actual secondary FAT:
;;;   .fat  xxxx          ; a fat entry (points inside current bank)
;;;   ...
;;;   .con 0,0            ; end marker
;;;
;;; If the word at xFFE (this is part of the ROM ID) has the highest
;;; bit set (2XX), then there are secondary FAT tables. The  word at XFC6
;;; (located immediately before the bank switch routines as suggested
;;; by HP) points to the first secondary FAT header.
;;; An unlimited number of secondary FAT headers can be used by linking
;;; the 'next' field.
;;;
;;; The secondary FAT headers must all be in bank 1, the actual FATs pointed
;;; to may be in any bank. All instructions described in one such FAT must
;;; be inside the same bank as that FAT. Actual bank switching is described
;;; using the 'switchBank' routine.
;;;
;;; Note: The layout is meant to allow searching by:
;;;       1. global sub#  (known from pressing key)
;;;       2. NAME, searched sequentially
;;;       3. XROM i,j,localSub#  by executing XROM i,j and fetching the next
;;;          byte from program memory.
;;;       In all cases we need to scan the linked list of secondary FAT
;;;       headers. When searching by name we need scan the actual secondary
;;;       FAT. In the other cases we can just traverse the secondary FAT
;;;       headers and using that information find the correct secondary
;;;       FAT and directly index the right function.
;;;
;;; Note: Only MCODE instructions can be encoded in a secondary FAT!!!
;;;
;;; **********************************************************************
