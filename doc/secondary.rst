*******************
Secondary functions
*******************

.. index:: functions, secondary, secondary functions

Secondary functions are additional XROM functions allows for up to
4096 additional functions that can be used if the provided 64
primary functions are not enough.

The ``XEQ'`` replacement function in the Boost module can be used to
access secondary functions by name, just as any other function. The
replacement ``ASN'`` function also allows them to be assigned to keys
in essentially the same way as ordinary XROM functions.

Storing secondary functions in programs is also possible using the
semi-merged functionality, they can also have postfix arguments
in programs.

It can be worth pointing out that once you have set up the secondary
FAT tables, everything is taken care of automatically by the OS4 and
Boost extension modules. There is no need to write any additional
specific code.

Secondary FAT
=============

.. index:: functions; secondary FAT, secondary FAT

The secondary function address table (FAT) consists of two parts.
The secondary FAT header is a linked list of structures in the primary
bank. This structure is rather small, typically 6--7
words. The actual FAT table is pointed to by the header structure and
is similar to the ordinary FAT. This table requires more space as it
uses two words for each function entry. It can be located in a
secondary bank, but all functions in it must be (or at least start) in
the same bank.

Each secondary FAT header table has an ordinary prefix XROM function
associated with it. This function is used to represent secondary
functions in RPN programs. As a result each secondary FAT table can
hold up to 256 secondary functions.

.. figure:: _static/secondaryFat.*

Execution by name
=================

.. index:: functions, execution by name

To find a secondary function by name, a similar routine to ``ASRCH`` in
mainframe is needed. As it is not possible to alter ``ASRCH`` which is in
mainframe ROM, OS4 provides a similar function that is aware of
secondary FATs. Execution by name is done by ``XEQ`` and the easiest
way is to use a replacement of ``XEQ`` that uses the
``XASRCH`` routine in OS4. The ``XEQ'`` function in the Boost module
is an example of this. As it is implemented using a system shell it
automatically replaces the ordinary ``XEQ`` key when Boost module is
inserted.

Assignments
===========

.. index:: assignment; of secondary functions, secondary functions; assignment

Assignments of secondary functions are stored in the OS4 system buffer.
The XROM identity is stored together with the secondary function
index. An assignment consumes a half register (seven nibbles), using
two nibbles for the XROM identity, three nibbles for the secondary
function identity and finally 2 nibbles for the key code. There is no
leading ``F0`` marker in this register as all nibbles are needed for
the assignments. This works as they are stored inside the system buffer.

As with the ordinary assignments there are bitmaps secondary
assignments for fast lookup if a key is assigned. These are also
stored in the OS4 system buffer, consuming two additional
registers when the first assignment is created.

Assignments are easily created using the ``ASN'`` function in the
Boost module, which is OS4 aware. This works very similar to the
already discussed ``XEQ'`` function. ``ASN'`` can handle assignments
of both primary and secondary functions.

As the OS4 module controls the keyboard it will also look for
assignments when appropriate. This will look for both primary and
secondary assignments and if both are present, the primary assignment
takes precedence. Normally they are no collisions, but in case you
load keys from storage medium you may get duplicate assignments. This
is because such mechanisms predates OS4 and only knows about primary
assignments.

This has a couple of caveats. If you manage to remove such assignments
outside the control of OS4 (by using another load key assignments that
replaces the current ones), the secondary assignments that were
shadowed will appear again. Loading keys from storage this way will
not reclaim the memory used for (shadowed) secondary  assignments.
Replacing keys this way only works on primary assignments. The
secondary assignments are always retained in a merge keys fashion in
such cases.

As a workaround, the function ``CLKYSEC`` in the Boost module can be
used to remove all secondary assignments. It simply calls the
``clearSecondaryAssignments`` routine in the OS4 API.

A secondary assignment that belongs to a module which is removed shows
up as ``XXROM ii,kkk`` if the key is pressed and held.

.. note::

   Secondary function on assigned keys are only searched for when
   there is at least one shell in the shell stack. If you have secondary
   assignments and remove every application and system shell from the
   stack, secondary assignments become invisible. This is unlikely to
   happen in reality as you need to have the ``ASN'`` function from
   the Boost module (or similar) to create them and it will always put
   a system shell on the shell stack.

In RPN programs
===============

.. index:: secondary functions; in programs

In program mode a normal XROM works as a prefix for representing
secondary functions. This is followed by a text literal that holds the
adjusted secondary function index. This index is based on the
secondary FAT it belongs to (0--255). Each secondary FAT header table
has such paired XROM that acts as the prefix for it.

You need to set aside one XROM function for each secondary FAT, which
is defined in the following way:

.. code-block:: ca65

                 .name   "(BPFX2)"     ; short name for prefix function
   Prefix2:      gosub   runSecondary  ; Must be first!
                 .con    1             ; I am secondary prefix XROM 6,1
                 ;; pops return address and never comes back

The name is not so important as it is normally suppressed by the
decorated view of the secondary function. It can be seen briefly
and also when stepping an RPN program by keeping the ``SST`` key
down. The function is just a call to ``runSecondary`` followed its own
XROM function number. This number is matched with the value stored in
secondary FAT header tables when scanning for a matching table.

As with all semi-merged functions, the fully decorated function is
shown in program mode followed by a text literal that is automatically
skipped when executed.

If a secondary function in program belongs to a module that is not
plugged in, it is shown as an XROM (the prefix XROM) followed by the
text literal. This is because in program memory the tables in the module
must be present to decode the real function number. When assigned to a key, the
actual full secondary index number is stored in the assignment. This
allows it to be displayed as ``XXROM`` when the key is kept pressed,
also when the module is removed.

.. note::
   A secondary function bound to a key that belongs to a module that is
   not plugged in cannot be entered in a program. This is also because the
   use of a XROM prefix function requires the secondary FAT to
   determine which XROM acts as prefix and also the base index for
   that table.

Defining
========

.. index:: secondary functions; defining

A secondary function is defined as any normal XROM function with a
name and an entry point. The name can have upper bits set to tell
that it is a prompting function. The first words at the entry point
can be NOP instructions (``000``) to indicate a non-programmable and
optionally execute direct (XKD).

Secondary functions can start in any bank. They do not have to be in
the primary bank as is the case with normal XROM functions. You should
however exit with the primary bank enabled.

Secondary FAT structure
=======================

.. index:: functions; secondary FAT, secondary FAT

The secondary FAT structure is different compared to the ordinary FAT and
consists of several parts:

#. A root pointer to the secondary FAT start is a packed pointer
   located at address ``0xFC2`` in the module page. As this location may
   contain other data in modules that are not OS4 aware, the module page
   image must also mark in the module ID field that this location
   has a valid root pointer, this is described next.

#. The module identity area consists of 4 words located at
   ``0xFFB``--``0xFFE`` in the module page. It forms a four letter
   module identity. The upper two  bits have special meanings as
   follows. ``0xFFD`` location tells whether the module
   is banked (this is defined and recommended by HP). The upper two bits
   in the ``0xFFE`` word tells whether there is a secondary FAT
   structure or not. If any of these two bits are set, the word at
   ``0xFC2`` is assumed to be a packed pointer to the start of the
   secondary FAT header structure.

#. The secondary FAT headers are small records that must be located
   in the primary bank. This forms a linked list of records. Each record
   has a packed pointer to the next record and some additional
   information described below.

#. The actual secondary FAT is pointed to from the secondary FAT
   header. This FAT is defined in the same way as the ordinary XROM
   FAT. It can be located in any bank, but all functions in it must be
   (or at least start) in the same bank. This bank is enabled by the
   bank switch routine in the secondary FAT header that points to it.

The bank switch routine should either be ``RTN`` for a primary bank,
or one of the ``ENROM`` instructions followed by a ``RTN``. That
``RTN`` instruction must be located at the following address in the
bank it enables. No registers should be affected by this code snippet.

Root pointer
------------

.. index:: secondary FAT; root pointer

The root pointer is just a packed pointer stored at location
``0xFC2``:

.. code-block:: ca65

                 .section PlaceMeAtFC2
   fatRoot:      .con    .low12 secondary1 ; Root pointer for secondary FAT headers


You also need to set one of the upper bits in the module identity
area in the word immediately before the checksum:

.. code-block:: ca65

   ;;; **********************************************************************
   ;;;
   ;;; Poll vectors, module identifier and checksum for primary bank
   ;;;
   ;;; **********************************************************************

                 .section pollVectors
                 nop                   ; Pause
                 nop                   ; Running
                 nop                   ; Wake w/o key
                 nop                   ; Powoff
                 nop                   ; I/O
                 goto    deepWake      ; Deep wake-up
                 goto    deepWake      ; Memory lost
                 .con    1             ; A
                 .con    '1'           ; 1
                 .con    0x20f         ; O (tagged for having banks)
                 .con    0x202         ; B (tagged as having secondaries)
                 .con    0             ; checksum position

Secondary FAT header
--------------------

.. index:: secondary FAT header

The secondary FAT header are small records that must be in the primary
bank. They form a linked list starting from root pointer. The first
word points to the next secondary FAT header record and the last one
has this word set to 0.

.. code-block:: ca65

   ;;; * First secondary FAT header, serving bank 1
                 .section Secondary1, reorder
                 .align  4
   secondary1:   .con    .low12 secondary2 ; pointer to next table
                 .con    (FAT1End - FAT1Start) / 2
                 .con    0             ; prefix XROM (XROM 6,0 - ROM header)
                 .con    0             ; start index
                 .con    .low12 FAT1Start
                 rtn                   ; this one is in bank 1,
                                       ; no need to switch bank

   ;;; * Second secondary FAT header, serving bank 2

                 .section Secondary1, reorder
                 .align  4
   secondary2:   .con    0             ; no next table
                 .con    (FAT2End - FAT2Start) / 2
                 .con    1             ; prefix XROM (XROM 6,1 - (BPFX2))
                 .con    256           ; start index
                 .con    .low12 FAT2Start
                 switchBank 2          ; this one is in bank 2
                 rtn

The second field is the number of entries in the secondary FAT we
describe. This is used for range checking.

The prefix XROM field is the function number in the main XROM of this
module that serves as the prefix XROM used in programs.

.. index:: secondary FAT; reserving identities

The start index is the function number of the first secondary function
stored in this table. Each prefix XROM can serve up to 256 functions
and we have a full range of 4096 secondary functions. Thus, we may
just step this by 256 for each secondary FAT header, which reserves
space for adding more functions later without affecting any index in
other tables. We essentially leave gaps for future secondary function
to be appended to the overall secondary function table.

A packed pointer to the actual FAT follows. The actual FAT pointed to
can be located in any bank. The next address holds a code snippet that
enables the bank it is located in.
If it is located in the primary bank, no change is needed so it
can just return. To switch bank you need to use the appropriate
``ENROM`` instruction followed by a ``RTN`` instruction
that must be in the bank it switches to! This can be accomplished
using some clever code arrangement. The easiest way is to use the
``switchBank`` macro which is defined as follows:

.. code-block:: ca65

   switchBank:   .macro  n
                 enrom\n
   10$:
                 .section Code\n
                 .shadow 10$
                 .endm

Secondary FAT table
-------------------

.. index:: secondary FAT

The actual secondary FAT looks exactly the same as the ordinary
FAT that starts at address ``0x002`` in a module page. The
secondary FAT can be located anywhere, but it must be aligned as it is
pointed out from the secondary FAT header using a packed pointer:

.. code-block:: ca65

                 .section Secondary2
                 .align  4
   FAT2Start:    .fat    COMPILE
                 .fat    RAMED
   FAT2End:      .con    0,0

Here we define two functions and terminate the table using two zero
values.

Design constraints
==================

The linked list of FAT secondary FAT headers allows for binding XROM
prefixes to a range of secondary functions. These prefix XROM
functions are needed when secondary functions are stored in
programs. To save space in RPN program memory, a single byte is used
as the identity, which means that you should not have more than 256
secondary functions in each FAT. Allowing more functions to be handled
by a single XROM prefix would cost an extra byte of program memory for
each secondary function. It was judged better to use an couple of such
XROM prefixes and save program space.


Bank switching
==============

.. index:: bank switching

Enabling the appropriate bank for secondary functions is done
automatically once you have set up the secondary FAT
structure. Switching back to the primary bank is done by calling the
``ENBNK1`` routine as defined by HP. It shall be  at page offset address
``FC7``. HP only defined two bank switchers and this was later
expanded to four, the full layout is as follows:

.. code-block:: ca65

   ENBNK3:       enrom3
                 rtn
   ENBNK4:       enrom4
                 rtn
   ENBNK1:       enrom1
                 rtn
   ENBNK2:       enrom2
                 rtn

This block of code should at page address ``0xFC3`` to ``0xFCA`` in
every bank. If you are not using all banks, replace the unused
switchers with two ``RTN`` instructions (or ``NOP`` and ``RTN``).

You should also set at least one of the two upper bits in page
address ``0xFFD`` to mark that the page is bank switched. Other ROMs
that want to enable different pages in your module
shall inspect these bits to determine if the page has multiple banks
and may then use the bank switch routines above to switch bank.

OS4 uses this technique to inspect secondary FATs which may be located in
other banks than the primary. However, OS4 only uses the ``ENBNK1``
routine as it uses the bank switch routine in the secondary FAT header
to enable other banks.
