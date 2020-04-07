*******************
Secondary functions
*******************

Secondary functions are additional XROM functions allows for up to
4096 additional functions that can be used if the provided 64
primary functions are not enough.

The ``XEQ'`` replacement function in the Boost module can be used to
access secondary functions by name, just as any other function. The
replacemnt ``ASN'`` function also allows them to be assigned to keys
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

The secondary FAT is split in two parts. The main structure is a
linked list of secondary FAT headers that are located in the primary
bank. This structure is rather small, typically 6-7 words. The actual
FAT table is pointed to by the header structure and this is similar to
the ordinary FAT. This table is usually larger as it requires two
words for each entry, so it is allowed to have it in any bank. All
functions in it must however reside (or at least start) in the same
bank as the secondary FAT that points to it.

Each secondary FAT header table has an ordinary prefix XROM that is
used when stored in an RPN program. Thus, each secondary FAT table can
hold up to 256 functions.

Execution by name
=================

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


In RPN programs
===============

In program mode a normal XROM works as a prefix for running
secondary functions coupled with the semi-merged ability provided by
OS4.

As with all semi-merged functions, the fully decorated function is
shown in program mode followed by a text literal that is automatically
skipped when executed.

If a secondary function in program belongs to a module that is not
plugged in, it is shown as an XROM (the prefix XROM) followed by the
text literal. This is because in a program, the tables in the module
are needed to decode the real function number.When bound to a key, the
actual full secondary index number is stored in the assignment, so it
will be displayed as ``XXROM`` if the module is removed.

.. note:: 
   A secondary function bound to a key that belongs to a module that is
   not plugged in cannot be entered in a program. This is because the
   use of a XROM prefix function requires the secondary FAT tables
   to determine which XROM acts as prefix and to properly calculate
   its secondary (adjusted) index.

Defining
========

A secondary function is defined as any normal XROM function, with a
name and an entry point. The name can have upper bits set to tell
that it is a prompting function. The first words at the entry point
may be 000 to indicate a non-programmable and optionally execute
direct (XKD).

The only minor thing that differs here is that the secondary
function is somewhat more flexible as it may be placed entirely in a
secondary bank while normal XROM functions must start in the primary
bank.

Secondary FAT
=============

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
   header. This FAT is defined in the same way as the ordinary XROM FAT,
   except that is does not need any ``0x000`` end marker. It can also be
   located in any bank, but all functions in it must be (or at least
   start) in the same bank. This bank is enabled by the bank switch
   routine in its secondary FAT header.

The bank switch routine should either be ``RTN`` for a primary bank,
or one of the ``ENROM`` instructions followed by a ``RTN`` and that
``RTN`` instruction must be located at the following address in the
bank it enables. No registers should be affected by this code snippet.

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
