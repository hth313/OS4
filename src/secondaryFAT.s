#include "mainframe.i"


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
;;;                           ;     this secondary FAT (when stored in program)
;;;   .con  startIndex        ; first entry is encoded as sub index # for XROM j
;;;   .con  .low12 location   ; location of FAT and routines
;;;                           ;     actual table is
;;;                           ;     (potentially in other bank)
;;;   switcher                ; routine to switch bank to where the table is
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


;;; **********************************************************************
;;;
;;;  XASRCH - alpha search
;;;
;;; Locate the address of an alpha string. The alpha string may apply to
;;; an alpha label in RAM or a function in the mainframe or plug-in ROMs.
;;; If the function is located in a plug-in ROM, return the XROM function
;;; code. This function is similar to ASRCH in mainframe, but secondary
;;; FATs are also searched. If the function is located in the mainframe,
;;; return its function code. If the function is located in RAM, return
;;; the alpha label address.
;;
;;; In:  M[13:0] and REG 9[13:0] = alpha label (2 COPIES)
;;;
;;; Out: S6=0 implies primary instruction found:
;;;      C[3:0]=   address (if user lang, this is address of first
;;;                         byte of label)
;;;      C[7:4]= function code
;;;      S2=1/0 implies ROM/RAM address
;;;      C=0 implies not found
;;;      S9=1/0 implies microcode/user code
;;;      S5=1 implies a mainframe function
;;;      chip 0 enabled
;;;
;;;      S6=1 implies a secondary XROM was found:
;;;      N[6:3]= points to secondary FAT header
;;;      B[6:3]= points to the XROM page address (X000)
;;;      C[2:0]= sequence number of secondary
;;;      Note: Active bank set to where the secondary is!
;;;
;;; Uses: M, A, B, C, G, N, STATUS, ptr P, REG 9,
;;;       status bits 2,3,5,6,8,9
;;;       +2 sub levels
;;;
;;; **********************************************************************

              .section code, reorder
              .public XASRCH
              .extern RTNP30, unpack, unpack0, unpack4, jumpC5, callInd, RTNP2
XASRCH:       c=regn  13            ; A[3:0]_END addr (RAM 1st)
              pt=     3
              lc      4             ; C[2:0]_END link
              pt=     3
              a=c     wpt
              dadd=c
              c=data
              rcr     2
SARA10:       ?c#0    x             ; END?
              gonc    XSAROM        ; yes
              gsblng  UPLINK        ; get nxt link addr
              c=c+1   s             ; ALBL?
              gonc    SARA10        ; nope
SARA20:       rcr     9             ; G_# alpha LBL chars
              c=c-1   pt
              g=c
              b=a     wpt           ; A[7:0]_LBL addr & char addr
              c=b     wpt
              rcr     10
              c=b     wpt
              a=c                   ; get 1st char
              gsblng  INCAD2
              gsblng  INCADA
              c=m                   ; B[13:0]_alpha string
              bcex
              abex
SARA30:       abex                  ; get nxt byte
              pt=     3
              gsblng  NXBYTA
              abex
              pt=     1
              ?a#c    wpt           ; equal?
              goc     SARA40        ; nope
              asr                   ; shift to NXTCHAR
              asr
              c=g                   ; dec count LBL chars
              c=c-1   pt
              g=c
              ?c#0    pt            ; end LBL chars?
              gonc    SARA50        ; yes
              ?a#0    wpt           ; end str chars?
              goc     SARA30        ; nope
SARA40:       pt=     3             ; get nxt link
              c=b
              rcr     4
              a=c     wpt
              rcr     5
              goto    SARA10
SARA50:       ?a#0    wpt           ; end str chars?
              goc     SARA40        ; nope
              c=0     x             ; enable chip 0
              dadd=c
              c=b                   ; C[3:0]_addr
              rcr     4
              s2=     0             ; RAM
              s9=     0             ; usercode_true
              rtn                   ; return

;;; **********************************************************************
;;;
;;; Done with CAT 1 search, now look at plug-in ROMs (CAT 2) and eventually
;;; the ones in mainframe (CAT 3).
;;;
;;; **********************************************************************

XSAROM:       pt=     2             ; PT_1 & A[13]_6
              lc      6
              rcr     3
              a=c     s
              c=m
SARO02:       bcex                  ; convert ASCII char to LCD
              abex    wpt
              gsblng  MASK
              nop
              pt=     1
              ?c#0    xs            ; special character?
              gonc    1$            ; nope
              lc      4             ; adjust special character
              pt=     1
1$:           bcex                  ; place LCD char in string
              bcex    wpt
              rcr     2
              ?c#0    wpt           ; done?
              gonc    SARO04        ; yes
              a=a-1   s             ; 7 chars?
              goc     SARO06        ; yes
              goto    SARO02        ; next char
SARO04:       rcr     2             ; right-justify
              ?c#0    wpt
              gonc    SARO04
SARO06:       m=c                   ; M_LCD char string
              pt=     6             ; B[M]_C[M]_56K
              c=0
              dadd=c                ; -  (sel chip 0)
              lc      5             ; start looking from page 5
SARO11:       bcex    m
SARO10:       c=b     m
              pt=     0             ; G= XROM ID
              cxisa
              g=c
              c=c+1   m
              cxisa
              ?c#0    x             ; table there?
              goc     SARO20        ; yes
SARO15:       s6=0                  ; not looking at secondary FAT
              pt=     6             ; adjust addr
              c=b     m
              c=c+1   pt
              gonc    SARO11

;;; Join forces with mainframe to look at page 3 (41CX) and mainframe
;;; table (catalog 3).
              golong  0x263a

;;;  Handle secondary FATs
SEC00:        ?s6=1                 ; already looking at a secondaries?
              goc     50$           ; yes
              c=b     m
              gosub   secondary
              goto    SARO15        ; (P+1) no secondaries
              s6=1                  ; yes, we are going to look at secondaries
              acex    m
              rcr     -4            ; C[10:7]= address of next secondary
30$:          pt=     6
              c=b     wpt
              bcex    m             ; B[10:7]= address of next secondary FAT header
              c=b     m
              rcr     4             ; C[6:3]= address of secondary FAT header
              c=c+1   m             ; C[6:3] += 5
              c=c+1   m
              c=c+1   m
              gosub   RTNP30        ; call bank switcher
              c=c-1   m             ; step back to point to seconday
                                    ;   FAT location entry
              gosub   unpack0       ; C[6:3]= address of secondary FAT
              pt=     1
              goto    XSARO22

50$:          c=b     m
              rcr     4             ; C[6:3]= secondary FAT header
              cxisa                 ; read the next work
              ?c#0    x             ; end?
              gonc    55$           ; yes
              gosub   unpack
              rcr     -4
              goto    30$

55$:          c=b     m
              gosub   resetBank
              goto    SARO15        ; next ROM

;;; Look at next entry in the table
SARO20:       pt=     1             ; C[6:3]_LBL addr
XSARO21:      c=c+1   m
XSARO22:      cxisa
              bcex    x
              c=c+1   m
              cxisa
              ?b#0    x             ; end of table?
              goc     SARO25        ; no
              ?c#0    x             ; yes
              gonc    SEC00
SARO25:       bcex    x
              a=c
              rcr     5
              a=a+c   pt
              rcr     9
              acex    x
              rcr     12
              c=b     wpt
              n=c                   ; save LBL addr in N
              rcr     11
              acex    x
              c=c+c   xs
              c=c+c   xs
              c=c+c   xs
              gonc    SARO45
              c=c+1   m             ; C[13]_# LBL chars
              c=c+1   m
              a=c
              cxisa
              rcr     1
              a=c     s
              c=regn  9             ; - (A[13:0]_alpha chars)
              acex
              c=c-1   s
              c=c+1   m
SARO30:       c=c+1   m             ; C[1:0]_1 LBL char
              cxisa                 ; equal?
              ?a#c    wpt
              goc     SARO40        ; no
              c=c-1   s             ; dec LBL count
              asr                   ; shift a to next char
              asr
              ?c#0    s             ; end of LBL?
              goc     SARO35        ; nope
              ?a#0    wpt           ; end of chrs?
              goc     SARO40        ; nope
              s9=     0             ; user_true
              goto    SARO55
SARO35:       ?a#0    wpt           ; end of chrs?
              goc     SARO30        ; nope, tst nxt char
SARO40:       rcr     5             ; get nxt tbl entry
              goto    XSARO21

SARO45:       a=c                   ; A_ALPHA string
              c=m
              acex
SARO47:       c=c-1   m             ; get nxt char
              cxisa
              ?c#0    wpt           ; is there a prompt string?
              gonc    SARO48        ; no
              s8=     0             ; S8_END bit
              cstex
              ?s7=1
              gonc    1$
              s7=     0
              s8=     1
1$:           cstex
              ?a#c    wpt           ; equal?
              goc     SARO48        ; nope
              asr
              asr
              ?s8=1                 ; end of LBL?
              goc     SARO50        ; yes
              ?a#0    wpt           ; end of chars?
              goc     SARO47        ; nope
SARO48:       rcr     5             ; get nxt entry
              golong  XSARO21
SARO50:       ?a#0    wpt           ; end of chars?
              goc     SARO48        ; nope
              s9=     1             ; MCODE true
SARO55:       c=n                   ; C[3:0]_ADDR & F.C.
              ?s6=1                 ; is this a secondary?
              gonc    50$           ; no
              rcr     5
              a=c                   ; A[3:0]= instruction address
              c=b
              rcr     4             ; C[6:3]= secondary FAT header
              n=c                   ; N[6:3]= secondary FAT header
              gosub   unpack4
              rcr     3             ; C[3:0]= secondary FAT start
              c=a-c                 ; C[3:0]= offset to instruction in table
              c=c+c
              c=c+c
              c=c+c
              csr                   ; C[2:0]= secondary instruction offset
              a=c     x             ; A[2:0]= secondary instruction offset
              c=n
              c=c+1   m
              c=c+1   m
              c=c+1   m             ; C[6:3]= point to start index
              cxisa
              c=a+c   x             ; C.X= secondary index
              rtn

50$:
; * Next two instructions (P T=7,LC 0) may not be necessary.
              pt=     7
              lc      0
              a=c                   ; C[7:4]_XROM F.C.
              rcr     2             ; construct table index part
              c=c-1   m
              c=c-1   m
              c=c+c   m
              c=c+c   m
              c=c+c   m
              csr     m
              c=c+c   m             ; construct ROM ID part
              c=c+c   m
              pt=     5
              c=g
              c=c+c   m
              c=c+c   m
              pt=     7             ; construct XROM FC part
              lc      10
              pt=     3
              acex    wpt           ; C[3:0]_ROM ADDR & C[5:4]_F.C.
              s2=     1
              rtn

;;; **********************************************************************
;;;
;;; resetBank - reset to primary bank
;;;
;;; Call the XFC7 entry in given bank to reset to bank 1. This assumes
;;; that there is such routine at that point (or at least a RTN).
;;; The bankswitcher is assumed to be an enromX instruction followed
;;; by RTN, if not the 'Uses' statement here may not apply!
;;;
;;; In: C[6]= page
;;; Out: Primary bank selected, PT=2
;;; Uses: C[6:3], active PT
;;;
;;; **********************************************************************

              .section code, reorder
              .public resetBank
resetBank:    pt=     5             ; C[6:3]= XFC7 to switch back to bank 1
              lc      0xf
              lc      0xc
              lc      7
              gotoc


;;; **********************************************************************
;;;
;;; secondary - are there secondary functions
;;;
;;; Check if there are secondary functions and return the address to the
;;; first secondaty FAT header.
;;;
;;; In: C[6]= page
;;; Out: Returns to (P+1) if no secondaries exist
;;;      Returns to (P+2) if there are secondaries with:
;;;        A[6:3]= first secondary FAT header
;;; Uses: A.M, C[6:0]
;;;
;;; **********************************************************************

              .section code, reorder
              .public secondary
secondary:    pt=     5
              lc      0xf           ; build page address XFFE
              lc      0xf
              lc      0xe
              cxisa
              ?c#0    xs            ; is there any secondary FAT?
              rtnnc                 ; no
              pt=     4
              lc      0xc           ; build page address XFC6
              lc      6
              gosub   unpack0       ; fetch and unpack
              a=c     m
              golong  RTNP2


;;; **********************************************************************
;;;
;;; secondaryAddress - look up a secondary function
;;;
;;; In: C[6]= page address
;;;     A.X= secondary function identity
;;; Out: Returns to (P+1) if function does not exist
;;;      Returns to (P+2) if exists and:
;;;        A[6:3]= address of secondary function
;;;        active bank set for secondary
;;; Uses:
;;;
;;; **********************************************************************

              .section code, reorder
              .public secondaryAddress
secondaryAddress:
              gosub   secondary
              rtn                   ; (P+1) no secondaries
              acex    m
10$:          c=c+1   m
              cxisa                 ; C.X= number of entries on this secondary
              ?a<c    x             ; in range?
              goc     20$           ; yes
              a=a-c   x             ; deduct entries in this secondary
              c=c-1   m
              cxisa
              ?c#0    x             ; do we have a next secodary?
              rtnnc                 ; no, does not exist
              gosub   unpack        ; read next pointer
              goto    10$

20$:          a=c     m             ; A[6:3]= FAT header pointer
              gosub   jumpC5        ; switch bank
              acex
              c=c+c   x             ; index * 2
              acex    x
              gosub   unpack4       ; get start location of FAT
              rcr     3
              c=a+c   x             ; add offset to entry
              rcr     -3
              cxisa
              pt=     1
              a=c     x             ; A[1:0]= high byte of FAT address
              rcr     5
              a=a+c   pt            ; A[1] += page
              asl
              asl
              rcr     9             ; restore address
              c=c+1   m             ; C[6:3]= point to low word
              cxisa
              a=c    wpt            ; A[3:0]= address of secondary function
              asl
              asl
              asl                   ; A[6:3]= address of secondary function
              golong  RTNP2
