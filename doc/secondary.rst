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
semi-merged functionality, they can even have postfix arguments that
are stored in programs.

It can be worth pointing out that once you have set up the secondary
FAT tables, everything is taken care of automatically by the OS4 and
Boost extension modules. There is no need to write any additional
specific code apart from bank switching if you use that.

Secondary FAT
=============

.. index:: functions; secondary FAT, secondary FAT

The secondary function address table (FAT) consists of two parts.
The header structure is a
linked list of secondary FAT headers that are located in the primary
bank. This structure is rather small, typically 6--7 words. The actual
FAT table is pointed to by the header structure and is similar to
the ordinary FAT. This table requires more space as it requires two
words for each function entry. It can be located in a secondary bank,
however, all functions in it must be (or at least start) in the same
bank.

Each secondary FAT header table has an ordinary prefix XROM function
associated with it. This function is used when one of the secondary
functions are used in an RPN program. Thus, each secondary FAT table can
hold up to 256 secondary functions.

Execution by name
=================

.. index:: functions, execution by name

To find a secondary function by name, a similar routine to ``ASRCH`` in
mainframe is needed. As it is not possible to ``alter`` ASRCH, which is in
mainframe ROM, OS4 provides a similar function that is aware of
secondary FATs. Execution by name is done by ``XEQ`` and the simplest
way is to use a replacement of ``XEQ`` which instead uses the
``XASRCH`` routine in OS4. The ``XEQ'`` function in the Boost module
does this and is also uses a system shell, it automatically replaces
the ordinary ``XEQ`` key when Boost module is inserted.

Assignments
===========

.. index:: assignment; of secondary functions, secondary functions; assignment

Assignments of secondary function are stored in the OS4 system buffer.
It stores the XROM of the module identity together with the secondary
index. An assignment takes half a register, using two nibbles
for the XROM identity, three nibbles for the secondary function
identity and finally 2 nibbles for the key code. There is no leading
``F0`` marker in this register as all nibbles are needed for the
assignments. This works as it is stored inside the system buffer.

Similar to ordinary assignments, bitmaps for these assignments are
also stored in the OS4 system buffer, consuming two additional
registers when the first assignment is created.

Assignments are easily created using the ``ASN'`` function in the
Boost module which similar to ``XEQ'`` is OS4 aware and will deal
with both primary and secondary functions.

As the OS4 module controls the keyboard, it will automatically look for
assignments when appropriate. It will look for both primary and
secondary assignments and if both are present, any primary assignment
takes precedence. Normally they are no collisions, but in case you
load keys from storage medium you may get duplicate assignments. This
is because such mechanisms predates OS4 and only know about primary
assignments.

This has a couple of caveats. If you manage to remove such assignments
outside the control of OS4 (by using another load key assignments that
replaces the current ones), the secondary assignments that were
shadowed will appear again. Loading keys from storage this way will
not reclaim the memory used for (shadowed) secondary  assignments.
Replacing keys this way only works on primary assignments, for
secondary assignments it acts as a merge keys on top of it.

As a workaround, the function ``CLKYSEC`` in the Boost module can be
used to remove all secondary assignments, it simply calls the
``clearSecondaryAssignments`` routine in the OS4 API.

A secondary assignment that belongs to a module that is removed (no
longer plugged in) shows up as ``XXROM ii,kkk`` if the key is pressed
and held.

.. note::

   Secondary function on assigned keys are only searched for when
   there is shells in the shell stack. If you have secondary
   assignments and remove every application and system shell from the
   stack, secondary assignments become invisible. This is unlikely to
   happen in reality as you need to have the ``ASN'`` function from
   the Boost module (or similar) to create them and that is made
   possible by a system shell.

In RPN programs
===============

.. index:: secondary functions; in programs

In program mode a normal XROM works as a prefix for running
secondary functions coupled with the semi-merged ability provided by
OS4. Each secondary FAT header table is paired with one such prefix
XROM function.

You need to set aside one XROM function for each secondary FAT, which
is defined in the following way:

.. code-block:: ca65

                 .name   "(BPFX2)"     ; short name for prefix function
   Prefix2:      gosub   runSecondary  ; Must be first!
                 .con    1             ; I am secondary prefix XROM 6,1
                 ;; pops return address and never comes back

The name is not so important as it is normally suppressed by the
decorated view of the secondary function, but it can be seen briefly
and also when stepping an RPN program by keeping the ``SST`` key
down. The function is just a call to ``runSecondary`` followed by the
XROM function number of this function. This number is matched with
the value stored in secondary FAT header tables when scanning for the
appropriate table.

As with all semi-merged functions, the fully decorated function is
shown in program mode followed by a text literal that is automatically
skipped when executed.

If a secondary function in program belongs to a module that is not
plugged in, it is shown as an XROM (the prefix XROM) followed by the
text literal. This is because in a program, the tables in the module
are needed to decode the real function number. When assigned to a key, the
actual full secondary index number is stored in the assignment, so it
can be displayed as ``XXROM`` when the key is kept pressed, also when
the module is removed.

.. note::
   A secondary function bound to a key that belongs to a module that is
   not plugged in cannot be entered in a program. This is because the
   use of a XROM prefix function requires the secondary FAT tables
   to determine which XROM acts as prefix and to properly calculate
   its index in that table.

Defining
========

.. index:: secondary functions; defining

A secondary function is defined as any normal XROM function, with a
name and an entry point. The name can have upper bits set to tell
that it is a prompting function. The first words at the entry point
may be ``000`` to indicate a non-programmable and optionally execute
direct (XKD).

Secondary functions can start in any bank, they do not have to be in
the primary bank as is the case with normal XROM functions. You should
however exit with the primary bank enabled.

Secondary FAT structure
=======================

.. index:: functions; secondary FAT, secondary FAT

The secondary FAT structure is different to the ordinary FAT and
consists of several parts:

#. A root pointer to the secondary FAT start is a packed pointer
   located at ``0xFC2`` in the module page. As this location may
   contain other data in modules that are not OS4 aware, the module page
   image must also set some upper bits in the module ID field at the end
   of the page, which is described next.

#. The module identity area consists of 4 words located at
   ``0xFFB``--``0xFFE`` in the module page. It forms a four letter
   module identity. The upper two  bits have special meanings as
   follows. ``0xFFD`` tells whether the module
   is banked (this is defined and recommended by HP). The upper two bits
   in the ``0xFFE`` word tells whether there is a secondary FAT
   structure or not. If any of these two bits are set, the word at
   ``0xFC2`` is assumed to be a packed pointer to the start of the
   secondary FAT header structure.

#. The secondary FAT headers are small records that must be located
   in the primary bank. This is a linked list of records. Each record
   has a packed pointer to the next record, the number of
   secondary functions it owns, the XROM prefix function number, a packed
   pointer to the actual secondary FAT table and a bank switch routine.

#. The actual secondary FAT is pointed to from the secondary FAT
   header. This FAT is defined in the same way as the ordinary XROM
   FAT. It can be located in any bank, but all functions in it must be
   (or at least start) in the same bank. This bank is enabled by the
   bank switch routine in its secondary FAT header.

The bank switch routine should either be ``RTN`` for a primary bank,
or one of the ``ENROM`` instructions followed by a ``RTN`` and that
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

                 ...

You also need to set one of the upper bits in the module identity
area, in the word immediately before the checksum:

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
describe. This is used for range checking lookups in the actual
function table.

The prefix XROM field is the function number in the main XROM of this
module that serves as the prefix XROM used in programs.

.. index:: secondary FAT; reserving identities

The start index is the function number of the first secondary function
stored in this table. Each prefix XROM can serve up to 256 functions
and we have a full range of 4096 secondary functions. Thus, we can
just step this by 256 for each secondary FAT header, which allows for
adding functions later to the function table without affecting any
offsets of already existing secondary functions. We essentially leave
gaps for future secondary function to be appended to the secondary
function table.

A packed pointer to the actual function table follows. This function
table that can be located in any bank and the address following is a
routine to enable the bank it is located in.
If it is located in the primary bank, no change is needed so it
can just return. If it actually wants to switch the bank it needs and
appropriate ``ENROM`` instruction followed by a ``RTN`` instruction
that must be in the bank we switched to! This can be accomplished
using some clever code arrangement, but is easy if you use the
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
primary FAT that starts at address ``0x002`` in the module page. The
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

The linked list of FAT secondary FAT headers allow for binding XROM
prefixes to a range of secondary functions. These prefix XROM
functions are needed when secondary functions are stored in
programs. To save space in RPN program memory, a single byte is used
as the identity, which means that you should not have more than 256
secondary functions in each FAT.


Bank switching
==============

.. index:: bank switching

Enabling the appropriate bank for secondary functions is done
automatically once you have set up the secondary FAT
structure. Switching back to the primary bank is done by calling the
``ENBNK1`` routine as defined by HP, it exists at page offset address
``FC7`` in the page. As HP only defined two bank switchers and this
was later expanded to four, the layout is as follows:

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

You also need to set at least one of the two upper bits in page
address ``0xFFD`` to mark that the page is bank switched. Other ROMs
that want to enable different pages in your module
shall inspect these bits to determine if the page has multiple banks
and may then use the page switch routines above to switch banks. OS4
uses this technique to inspect secondary FATs which may be located in
other banks than the active one.
