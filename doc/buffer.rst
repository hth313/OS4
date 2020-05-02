**************
System buffer
**************

A system buffer is used to keep track of the OS4 state. As all buffers
it resides in the memory area between key assignments and user
programs, the so called free area.

The buffer number used is 15 which is a buffer number that is probably
not used by any other module as of this writing. 15 is normally used
for key assignments, so how can this work you may wonder. Well, a
buffer as defined ny HP is supposed to have the first two nibbles
(4-bit values) set the same way. This allowes for 14 buffers, numbered
1--14. The time module uses buffer 10, so it set the first two nibbles
to ``AA`` (``A`` hex is 10 decimal) for its buffer. However, ``FF`` would
not work as it could be mistaken for a key assignment register. The
answer is that we usually put ``1F`` there instead. The first nibble can
actually be any non-zero value except 15 and work properly with all
existing software. Taking advantage of this allowes for having buffer
0 and 15, for a total of 16 buffers. Buffer 0 is already used by the
Ladybug module which from version 1A takes advantage of the OS4 module,
which leaves 15 for the OS4 system buffer.

Buffer layout
=============

The buffer consists of a header register followed by several areas
that appear in a well defined order. The size of each area is kept in the
buffer header, which means that to get to a certain area, sizes of
areas before need to be summed and added to the buffer header
address. There are routines in OS4 to help with this, but normally you
will use more high level routines that deals with more complete
actions on the buffer, finding the area inside the buffer is just a
small detail.

The sizes are in the buffer header, but as they is a little shortage
of room, two of the sizes are single nibble and the reamining two uses
two nibbles. These have been chosen so that the two smaller ones are
less likely to need a lot of registers.

The header register is defined as follows:

``ID SZ BF SC:KA SH DF ST``

The ``ID`` is the identifier which normally set to ``1F``. The ``SZ``
field is the size of the buffer. These two fields are defined by the
HP-41 operating system and all buffers are like this.

The ``ST`` field is a set of flags that keeps track of the internal
state. You normally do not need to take these in account as they are
handled internally by OS4.

The ``DF`` field is used by the semi-merged mechanism to store a
postfix arguments during function entry. When entering a single
postfix argument, the default argument is stored here. For dual
postfix functions, this field is used to hold the first entered
argument.

The remaning for fields ``BF``, ``SC``, ``KA`` and ``SH`` are the
sizes of the different areas that follows the header. The sizes are
naturally used to tell the size of a field, so we know where it ends,
but it is also used when calculating the start address of a given
field. This is done by adding the sizes of all fields preceding the
field we are interested in, plus one for the buffer header and finally
the address of the buffer header.

.. note::

   You do not normally need to worry about the fields in the buffer
   header as they are internal to OS4. It should be sufficient to use
   the provided routines in the API, especially when making changes to
   field sizes, as there are certain invariants that need to be
   maintained to keep a consistent state. The built in routines
   take care of this.

.. figure:: _static/memory.*

   Key assignments and buffer area.


Area sizes
==========

Most of the areas are defined as being simply the size, where 0 means
that the area is empty. For secondary key assignments it adds two
additional registers for assignment bitmaps when it is non-zero,
meaning it will occupy 0, 3, 4 and up to 17 registers. The temporary
scratch area could in theory avoid having a nibble for its size, but
making it explicit simplifies the code. (It could in theory be
calculated from the rest of the sizes).


Shell registers
===============

Shells will be described in more detail later. For now it is enough to
know that a shell occupy 7 nibbles and two are stored into each buffer
shell register. The shell area is a stack, so the order of which they
appear describes how they affect the current behavior. The top of the
stack is in first register (the one with lowest address) and starts in
the lower half. There is no need to have any marker, like for normal
key assignments as the shell registers are kept inside the buffer
structure.

Hosted buffer area
==================

This is an area that keeps track of application buffers. These have
much of the same properties as ordinary buffers, but are actually
stored inside the system buffer. They are somewhat easier to use than
making your own buffer code and they are suitable for smaller buffers as
the overall buffer size (of the system buffer) is limited to 255
registers. They also have the advantage of having buffer identities
that are unrelated to normal buffers, making clashes far less likely.

Secondary assignments
=====================

Functions defined in secondary function address tables can be bound
to keys and are stored in the secondary assignment area. Two
assignments can be stored in one register. This gives seven nibbles
to describe one assignment. The function code has a two nibble XROM
number and a three nibble secondary function number. The two remaining
nibbles are the key-code.

Due to single nibble being used for the size of this area, there is a
limit of 30 secondary functions being assigned to keys.

The secondary assignments have bitmap registers for fast lookup, much
like what is used by the ordinary assignments. The ordinary bitmaps
shadow the secondaries in case they both say they are assigned.
This should normally not happen, unless you use existing functions to
load key assignments from secondary storage, like magnetic card. In
this case there are typically two variants, one to replace all
existing assignments and one to merge key assignments. With respect to
secondary assignments, they both behave as merging as they are put on
"top of" existing secondary assignments. This is because they are
unaware of the concept of secondary assignments. In this case the user
may need to run a routine to clear secondary assignement separately.

This also means that if you load key assignments over a secondary
assignment, the primary (ordinary) assignment takes precedence, but if
you clear the assignment through means outside OS4, the shadowed
secondary assignment may reappear.
