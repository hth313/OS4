Secondary functions
===================

Secondary functions are additional XROM functions that can be used for
defining additional functions to the already available 64 in the
FAT. Up to 4095 such functions can be created and it is possible to have
them in secondary banks. If the XEQ replacement in the Boost module
(or a similar mechanism) is used, they can be keyed from the keyboard
in the same way as any other named function. In fact, you will only
see that the differ when stored in a program. Full support for
execution by name, assignment and storage use in RPN programs is
provided.

If you are familiar with how the HP-41 internals work, you may wonder
how it is possible to provide a large number of additional functions
rather seamlessly. The answer is in part the OS4 module uses page 4
and its take-over vector.

It can be worth pointing out that once you have set up the secondary
FAT tables, everything is take care automatically by the OS4 and Boost
extension modules. There is no need to write any specific code and it
all works basically as usual from the user's point of view.

Secondary FAT
--------------

The secondary FAT is split in two parts. The main structure is a
linked list of secondary FAT headers that are located in the main
bank. This structure is rather small, typically 6-7 words. The actual
FAT table is pointed to by the header structure and this is similar to
the ordinary FAT. As this table is potentially larger, as it requires
two words for each entry, it is allowed to exist in any bank. All
functions in it must however reside (or at least start) in the same
bank as its secondary FAT.

Each secondary FAT header table has an ordinary prefix XROM that is
used when stored in an RPN program. Thus, each secondary FAT table can
hold up to 256 extra functions.

Execution by name
-----------------

To find a secondary function by name, a similar routine to ASRCH in
mainframe is needed. As it is not possible to alter ASRCH, which is in
mainframe ROM, OS4 provides a similar function that is aware of
secondary FATs. Execution by name is done by ``XEQ`` and the simplest
way is to us a replacement of ``XEQ`` that makes use of the
replacement called ``XASRCH`` in OS4. The ``XEQ'`` function in the
Boost module does this and is also a system shell, so it automatically
replaces the ordinary ``XEQ`` key when Boost is installed.

Assignments
-----------

Assignments of secondary function are stored in the OS4 system buffer.
It stores the XROM of the module identity together with the full
secondary index. An assignment takes half a register, using two nibbles
for the XROM identity, three nibbles for the secondary function
identity and finally 2 nibbles for the key code. Thus, seven nibbles,
or half a register is needed which means that two assignments share a
single registers. All bits (14 nibbles) in the register is used for
the two assignments and there is no leading ``F0`` marker. This works
as they are stored inside the buffer. 

Similar to ordinary assignments, bitmaps for these assignments are
also stored in the OS4 system buffer. These take up two registers.

Assignments are easily created using the ``ASN'`` function in the
Boost module which similarly to ``XEQ'`` is OS4 aware and will deal
with both primary and secondary functions.

As the OS4 module control keyboard, it will automatically look for
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
used to remove all secondary assignments, it simply calls
``clearSecondaryAssignments`` in the OS4 API.

Functionality to erase of compact secondary key assignments are
currently not provided.

A secondary assignment that belongs to a module that is removed (no
longer plugged in) shows up as ``XROM ii,kkk`` if the key is pressed
and held.


In RPN programs
----------------

In program mode a normal XROMs works as a prefixes for running
secondary functions coupled with the semi-merged ability provided by
OS4.

As all semi-merged functions, the fully decorated instruction is shown
in program mode followed by a text literal that is automatically
skipped when executed.

If a secondary function in program belongs to a module that is not
plugged in, it is shown as an XROM (the prefix XROM) followed by the
text literal. This is because in a program, the combination of the
prefix XROM and the text literal are used to get the index of the
secondary and find it. This interpretation can only be done when the
module to be inserted. When bound to a key, the actual full secondary
index number is stored in the assignment, so it will be displayed as
XXROM if the module is removed.

.. note:: 
   A secondary function bound to a key belonging to a module that is
   not plugged in cannot be entered in a program. This is because the
   use of XROM prefix instructions requires the secondary FAT tables
   to determine which XROM acts as prefix and to properly calculate
   its secondary (adjusted) index.

Defining
--------

A secondary function is defined as any normal XROM function, use a
name and an entry point. The name can have upper bits set to tell
that it is a prompting function. The first words at the entry point
may be 000 to indicate a non-programmable and optionally that it is
XKD.

The only minor thing that differs at this point is that the secondary
function is somewhat more flexible as it may be placed entirely in a
secondary bank while normal XROM functions must start in the primary
bank.

Displaying
----------

If you press and hold a key with a secondary function assigned, it is
shown with its name representation. The same is true in programs,
though they are actually stored using an ordinary XROM followed by a
text literal.


Secondary FAT
-------------

The secondary FAT structure is different to the ordinary FAT and
consists of several parts.

# The root pointer to the secondary FAT start is a packed pointer
located at `FC6` hexadecimal in the module page. As this location may
contain other data in modules that are not OS4 aware, the module page
image must also set some upper bits in the module ID field at the end
of the page, which is described next.

# The module Id area consists of 4 words located at `FFB`-`FFE` in the
module page. It contains a four letter module identity. The upper two
bits have special meaning as follows. `FFD` tells whether the module
is banked (this is defined and recommended by HP). The upper two bits
in the `FFE` words tells whether there are OS4 secondaries or not. If
any of these two bits are set, the word at `FC6` is assumed to be a
packed pointer to the start of the secondary FAT header structure.

# The secondary FAT headers are small records that need to be located
in the primary bank. This is a linked list of records. Each record
has a packed pointer to the next record, the number of
secondary functions it owns, the XROM prefix function number, a packed
pointer to the actual secondary FAT table and a bank switcher routine.

# The actual secondary FAT is pointed to from the secondary FAT
header. This FAT is defined in the same way as the ordinary XROM FAT,
except that is does not need any `000` end marker. It can also be
located in any bank, but all functions in it must be (or at least
start) in the same bank. This bank is enabled by the bank switcher
routine in its secondary FAT header. This routine should either be
``RTN`` for a primary bank, or one of the ``ENROM`` instructions
followed by a ``RTN``. No registers should be affected by this code
snippet.

Design constraints
------------------

The linked list of FAT secondary FAT headers allows for binding XROM
prefixes to a range of secondary functions which is needed when they
are stored in programs. To save space in RPN program memory, a single
byte is used as a prefix, which means that you should not have more
than 256 secondary functions in a single table. Each single table also
need to share the same bank.


Bank switching
--------------

Enabling the appropriate bank for secondary functions is done
automatically once you have set up the secondary FAT
structure. Switching back to the primary bank is done by calling the
``ENBNK1`` routine as defined by HP, it exists at page offset address
``FC7`` in the page:

    ENBNK1:       enrom1
                  rtn
    ENBNK2:       enrom2
                  rtn



