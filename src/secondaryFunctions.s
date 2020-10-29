#include "mainframe.h"
#include "internals.h"

#define IN_OS4
#include "OS4.h"

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
;;; For key assignments and in program memory the full range is in theory
;;; possible, but that is a lot of functions!
;;;
;;; The following structure is a secondary FAT header:
;;;   .con  .low12 next       ; points to next secondary FAT header,
;;;                           ;     or 0 to mark end
;;;   .con  entries           ; number of entries in this header table
;;;                           ;  The table can be shorter, you can reserve
;;;                           ;  entries for the future that way, also
;;;                           ;  adjust startIndex for following tables!!
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


;;; XASRCH docstart
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
;;;      A[2:0]= sequence number of secondary
;;;      Note: Active bank is primary bank, which may not be the same
;;;            bank as the secondary.
;;;
;;; Uses: M, A, B, C, G, N, STATUS, ptr P, REG 9,
;;;       status bits 2,3,5,6,8,9
;;;       +2 sub levels
;;;
;;; **********************************************************************
;;; XASRCH docend

              .section code2, reorder
              .public XASRCH
              .extern jumpP1_B2, jumpP2_B2
              .extern unpack_B2, unpack0_B2, unpack1_B2, unpack3_B2, unpack4_B2
              .extern NXBYTP_B2, RTNP2_B2, RTNP2
              .extern gotoFunction, isArgument
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
              golong  enableBank1   ; return

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
              s5=0                  ; doing XROMs
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
              golong  to_0x263a

;;;  Handle secondary FATs
SEC00:        ?s6=1                 ; already looking at a secondaries?
              goc     50$           ; yes
              c=b     m
              gosub   secondary
              goto    SARO15        ; (P+1) no secondaries
              s6=1                  ; yes, we are going to look at secondaries
              rcr     -4            ; C[10:7]= address of next secondary
30$:          pt=     6
              c=b     wpt
              bcex    m             ; B[10:7]= address of next secondary FAT header
              c=b     m
              rcr     4             ; C[6:3]= address of secondary FAT header
              c=c+1   m             ; C[6:3] += 4
              c=c+1   m
              c=c+1   m
              c=c+1   m
              cxisa
              a=c                   ; A.X= packed address of secondary FAT
                                    ; A[6]= page
              gosub   jumpP1_B2     ; call bank switcher
              acex                  ; C.X= packed address of secondary FAT
                                    ; C[6]= page
              gosub   unpack_B2     ; C[6:3]= address of secondary FAT
              pt=     1
              goto    XSARO22

50$:          c=b     m
              gosub   resetBank_B2
              c=b     m
              rcr     4             ; C[6:3]= secondary FAT header
              cxisa                 ; read the next word
              ?c#0    x             ; end?
              gonc    SARO15        ; yes, look at next ROM
              gosub   unpack_B2
              rcr     -4
              goto    30$

;;; Look at next entry in the table
SARO20:       pt=     1             ; C[6:3]_LBL addr
XSARO21:      c=c+1   m
XSARO22:      cxisa
              bcex    x
              c=c+1   m
              cxisa
              ?b#0    x             ; end of table?
              goc     SARO25        ; no
              ?c#0    x
              gonc    SEC00         ; yes
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
              gosub   resetBank_B2
              c=n
              gosub   unpack4_B2
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
              a=a+c   x             ; A.X= secondary index
              goto    toBank1

50$:
; * Next two instructions (PT=7,LC 0) may not be necessary.
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
toBank1:      golong  enableBank1

;;; * Switch bank and jump to mainfram routine
              .section code2
to_0x263a:    switchBank 1
              golong  0x263a

;;; resetBank docstart
;;; **********************************************************************
;;;
;;; resetBank    - reset to primary bank (routine in bank 1)
;;; resetBank_B2 - reset to primary bank (routine in bank 2)
;;;
;;; Call the XFC7 entry in given bank to reset to bank 1. This routine is "safe"
;;; in that it is guarded by looking at the bank bit presence in the
;;; ROM identifier.
;;; The bankswitcher is assumed to be an enromX instruction followed
;;; by RTN, if not the 'Uses' statement here may not apply!
;;; This routine is in bank 1, the resetBank_B2 is a duplicate version
;;; in bank 2.
;;;
;;; In: C[6]= page
;;; Out: Primary bank selected, PT=2
;;; Uses: C[6:3], active PT
;;;
;;; **********************************************************************
;;; resetBank docend

resetBankM:   .macro
              pt=     5
              lc      0xf           ; xFFD
              lc      0xf
              lc      0xd
              cxisa
              ?c#0    xs            ; has banks?
              rtnnc                 ; no, do not assume there is code to
                                    ;  switch back to bank 1
              pt=     4
              lc      0xc           ; xFC7
              lc      7
              gotoc
              .endm

              .section code1, reorder
              .public resetBank
resetBank:    resetBankM

              .section code2, reorder
resetBank_B2: resetBankM

;;; **********************************************************************
;;;
;;; secondary - are there secondary functions
;;;
;;; Check if there are secondary functions and return the address to the
;;; first secondaty FAT header.
;;;
;;; Note: This routine is in bank 2 and returns without switching bank.
;;;
;;; In: C[6]= page
;;; Out: Returns to (P+1) if no secondaries exist
;;;      Returns to (P+2) if there are secondaries with:
;;;        C[6:3]= first secondary FAT header
;;; Uses: A.M, C[6:0], +0 sub levels
;;;
;;; **********************************************************************

              .section code2, reorder
secondary:    pt=     5
              lc      0xf           ; build page address XFFE
              lc      0xf
              lc      0xe
              cxisa
              ?c#0    xs            ; is there any secondary FAT?
              rtnnc                 ; no
              a=c     m
              c=stk                 ; bump return address (save one sub level)
              c=c+1   m
              stk=c
              acex    m
              pt=     4
              lc      0xc           ; build page address XFC2
              lc      2
              golong  unpack0_B2    ; fetch and unpack

;;; secondaryAddress docstart
;;; **********************************************************************
;;;
;;; secondaryAddress - look up a secondary function
;;;
;;; Note: This routine is in bank 2 and returns without switching bank.
;;;
;;; In: C[6]= page address
;;;     A.X= secondary function identity
;;; Out: If function does not exist:
;;;        A.M= 0
;;;      If function exists:
;;;        A[6:3]= address of secondary function
;;;        A[10:7]= address of bank switch routine
;;;        A.M= non-zero ([6:3] is the address which is non-zero if valid)
;;;        A.X= secondary function identity
;;;        active bank set for secondary
;;; Uses: A, B[12:0], C, active PT
;;;       +1 sub levels, or +2 sub levels called from outside OS4
;;;
;;; **********************************************************************
;;; secondaryAddress docend

              .section code2, reorder
              .public secondaryAddress
secondaryAddress:
              a=0     s
secondaryAddress10:
              b=a     x             ; B.X= secondary function identity
              gosub   secondary
              goto    18$           ; (P+1) no secondaries
10$:          a=b     x
              c=c+1   m
              c=c+1   m
              c=c+1   m
              cxisa                 ; get index offset used here
              c=c-1   m             ; step back to FAT+1
              c=c-1   m
              a=a-c   x             ; adjust index for this table
              goc     15$           ; outside, skip this one
              cxisa                 ; C.X= number of entries on this secondary table
              ?a<c    x             ; in range?
              goc     20$           ; yes
15$:          c=c-1   m
              cxisa
              ?c#0    x             ; do we have a next secondary table?
18$:          gonc    notFound      ; no, does not exist (also relay)
              gosub   unpack_B2     ; read next pointer
              goto    10$

20$:          ?a#0    s             ; coming from secondaryProgram?
              gonc    lookupFAT     ; no
              c=c-1   m             ; yes
              acex    m             ; A[6:3]= the secondary FAT header
              rtn
lookupFAT:    c=c+1   m
              c=c+1   m
              c=c+1   m
              cxisa                 ; C.X= packed pointer to secondary FAT
              c=c+c   x
              c=c+c   x             ; C.X= page address of secondary FAT
              a=c     m             ; A[6:3]= address in secondary FAT header
              rcr     -3            ; C[5:3]= page address of secondary FAT
              acex    m             ; A[5:3]= page address of secondary FAT
                                    ; C[6:3]= address in secondary FAT header
              gosub   jumpP1_B2     ; switch bank
              rcr     -4
              b=c     m             ; B[10:7]= bank switcher routine
              rcr     4
              pt=     5
              acex    wpt           ; C[6:3]= start of secondary FAT
                                    ; C.X= index
              c=c+c   x             ; index * 2
              acex    x
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
              a=c     wpt           ; A[3:0]= address of secondary function
              asl
              asl
              asl                   ; A[6:3]= address of secondary function
              abex    x             ; A.X= secondary function identity
              pt=     6
              b=a     wpt           ; B[10:7]= bank switcher
                                    ; B[6:3]= XADR
                                    ; B.X= secondary function identity
              abex    m             ; A[10:7]= bank switcher
                                    ; A[6:3]= XADR
              abex    x             ; A.X= secondary function identity
                                    ; (preserve B.S)
              rtn

notFound:     a=0     m             ; not found
              rtn

;;; **********************************************************************
;;;
;;; secondaryProgram - how to represent a secondary in program memory
;;;
;;; Get information needed for how to store a secondary function in a
;;; program. This consists of the XROM prefix to be used and the adjusted
;;; secondary number (for that prefix).
;;;
;;; Note: This routine enters and returns in bank 1, though it does
;;;       switch to bank 2 internally.
;;;
;;; In: C[6]= page address
;;;     A.X= secondary function identifier
;;; Out: Returns to (P+1) if function does not exist
;;;      Returns to (P+2) if exists and:
;;;        B[1:0]= adjusted secondary function identity
;;;        A[3:0]= XROM function code
;;; Uses: A, C, +3 sub levels
;;;
;;; **********************************************************************

              .section code1, reorder
              .public secondaryProgram
              .extern  RTNP2
secondaryProgram:
              switchBank 2
              a=0     s
              a=a+1   s
              gosub   secondaryAddress10
              ?a#0    m
              gonc    10$
              b=a     x             ; B[1:0]= adjusted secondary function identity
              acex    m             ; C[6:3]= secondary FAT header
              c=c+1   m
              c=c+1   m
              cxisa                 ; read XROM j prefix
              pt=     3
              lc      10
              a=c                   ; A[3]= 10
                                    ; A.X= j prefix
              pt=     5
              c=0     wpt           ; C[6:3]= P000
              cxisa                 ; read XROM i
              c=0     s
              rcr     -1
              c=c+c   x
              c=c+c   x
              a=a+c   x
              enrom1
10$:          golong  enableBank1

              .section code1
              .shadow 10$
              golong  RTNP2

;;; runSecondary docstart
;;; **********************************************************************
;;;
;;; runSecondary - run-time handling of secondary invocation
;;;
;;; In: STK= called from ROM page, @STK is prefix function number
;;;
;;; Out: does not return to caller
;;; Uses: N/A
;;;
;;; **********************************************************************
;;; runSecondary docend

              .section code2, reorder
              .public runSecondary
              .extern systemBuffer
runSecondary: s8=0                  ; not Text 1
              s9=0                  ; no text literal consulted
              c=stk                 ; C[6:3]= some page address
              cxisa
              a=c     x             ; A.X= XROM prefix code
              gosub   secondary
              goto    100$          ; (P+1) not found
10$:          c=c+1   m
              m=c                   ; M= secondary FAT header pointer + 1
              c=c+1   m
              cxisa
              ?a#c    x             ; the prefix we are looking for?
              gonc    20$           ; yes
              c=c-1   m
              c=c-1   m
              cxisa
              ?c#0    x             ; are there more tables?
99$:          gonc    toERRNE       ; no - does not exist
              gosub   unpack_B2
              goto    10$

100$:         golong  enableBank1

20$:          c=c+1   m
              ?s13=1                ; running?
              goc     25$           ; yes
              ?s4=1                 ; no, single stepping?
              goc     25$           ; yes
              c=regn  9             ; read function code
              c=c+1   m             ; check validity of it
                                    ; C.M should have all bits set
              gonc    toERRNE       ; nope
              c=c-1   s             ; C.S -= 1
              goc     23$           ; done, clobber REGN9.M
              c=c-1   m             ; accept once more, restore all bits set
                                    ;  in REGN9.M
23$:          regn=c  9
              goto    35$

25$:          s9=1                  ; secondary identifier from program memory
              gosub   NXBYTP_B2
              b=a
              a=c     x             ; A.X= instruction byte
              pt=     1
              c=c+1   pt            ; is it a text literal?
              gonc    toERRNE       ; no
              rcr     1
              c=c-1   s             ; is it Text 0?
              goc     toERRNE       ; yes
              acex    s             ; A.S= Text # literal - 1
              ldi     Text1
              ?a#c    x             ; is it actually Text 1?
              goc     27$           ; no
              s8=1                  ; yes (if accepted we step over this later)
27$:          abex                  ; B.S= Text # literal - 1
                                    ; A[3:0]= address
              gosub   INCAD         ; step to secondary identifier
              gosub   GTBYT         ; read identifier
              acex
              n=c                   ; N= address
              acex

35$:          c=0     xs
              a=c     x             ; A.X= index in FAT
              c=m                   ; C[6:3]= secondary FAT header pointer + 1
              cxisa                 ; C.X= number of functions
              ?a<c    x             ; in range?
toERRNE:      golnc   ERRNE_B2      ; no, flag as error
              gosub   lookupFAT
              b=a     m             ; B[6:3]= XADR
              c=b     m             ; C[6:3]= XADR

;;; Here we switch to bank 1 to call isArgument, systemBuffer and gotoFunction
              switchBank 1
              gosub   isArgument
              goto    75$           ; not semi-merged
              ?s8=1                 ; semi-merged, does it use Text1 (actually
                                    ;  lacking its semi-merged argument?)
              goc     toErrneInBank1 ; yes, corrupt, say NONEXISTENT
              ?s9=1                 ; semi-merged, fetching from program memory?
              gonc    xgotoFunction ; no
              c=b     s             ; C.S= Text literal count - 1
              ?s7=1                 ; dual arguments?
              gonc    72$           ; no
              c=c-1   s
72$:          c=c-1   s
              ?c#0    s             ; correct text literal length?
              goc     toErrneInBank1 ; no
              gosub   systemBuffer
              goto    xgotoFunction ; (P+1) no system buffer, this will cause
                                    ;  and error later in argument handling
              c=data                ; tell argument handling that we are
              cstex                 ;  executing a secondary
              st=1    Flag_SEC_Argument
              cstex
              data=c

              goto    xgotoFunction ; yes, we will need the text literal when
                                    ;  fetching semi-merged operands, so we do
                                    ;  not skip over it now

75$:          ?s8=1
toErrneInBank1:
              golnc   ERRNE         ; not Text1
              c=n
              a=c                   ; A= address
              gosub   PUTPC         ; step over Text1
xgotoFunction:
              abex    m             ; A[6:3]= XADR
              golong  gotoFunction

;;; Insert a bank switch (in bank 2) prior to a jump to ERRNE located in bank1
;;; to make the bank switch and then jump to ERRNE.
              .section code2
              .shadow toErrneInBank1 - 1
ERRNE_B2:     enrom1

;;; **********************************************************************
;;;
;;; inProgramSecondary - find secondary as stored in program memory
;;; inProgramSecondary_B1 - same as inProgramSecondary, but callable from
;;;                         bank 1 and uses +3 sub levels
;;;
;;; Note: This routine is in bank 2 and returns without switching bank.
;;;
;;; In: M[6:3]= points to word before program memory suffix
;;;     B.X= secondary function after XROM prefix
;;; Out: If function does not exist:
;;;        A.M= 0
;;;        M[5:3] and M.X= function number after XROM
;;;      If function exists:
;;;        A[6:3]= address of secondary function
;;;        A.X= secondary function identity
;;;        M.X= actual function number
;;;        M[5:3]= function number after XROM
;;;        active bank set for secondary
;;; Uses: A, B, C, M, PT, +2 sub levels
;;;
;;; **********************************************************************

              .section code2, reorder
              .public inProgramSecondary
inProgramSecondary:
              c=m
              c=c+1   m
              cxisa                 ; C.X= read jj suffix
              a=c     x             ; A.X= prefix XROM number (jj of XROM ii,jj)
              gosub   secondary
              goto    99$
              bcex    m             ; B[6:3]= pointer to secondary FAT header

10$:          c=b     m             ; C[6:3]= pointer to secondary FAT header
              c=c+1   m
              c=c+1   m
              cxisa
              ?a#c    x             ; this secondary
              gonc    20$           ; yes
              c=b     m
              cxisa
              ?c#0    x             ; is there a next table?
              gonc    99$           ; no
              gosub   unpack_B2     ; point to next
              bcex    m
              goto    10$
20$:          c=b     m
              c=c+1   m
              cxisa                 ; C.X= number of functions here
              abex    x             ; A.X= actual function number
              ?a<c    x             ; in range?
              golc    lookupFAT     ; yes
99$:          a=0     m             ; not found
              rtn

              .public inProgramSecondary_B1
              .section code1
inProgramSecondary_B1:
              switchBank 2
              gosub   inProgramSecondary
              switchBank 1
              rtn
