**************
System buffer
**************

.. index:: buffers; system, system buffer

A system buffer is used to keep track of the OS4 state. As all other
buffers it resides in the memory area between key assignments and user
programs, the so called buffer area.

The buffer number used is 15, which is a buffer number that is probably
not used by any other module as of this writing. 15 is normally used
for key assignments, so you may wonder how this can work. A buffer as
defined by HP is suggested to have the first two nibbles (4-bit
values) both set to the buffer number. This allows for 14 buffers, numbered
1--14. The time module uses buffer 10, so it sets the first two nibbles
to ``AA`` (``A`` hex is 10 decimal) for its buffer. However, ``FF`` would
not work as it could be mistaken for a key assignment register. The
answer is that OS4 stored ``1F`` there instead. The first nibble can
actually be any non-zero value except 15 and work properly. Taking
advantage of this allows for having buffer 0 and 15, for a total of 16
buffers. Buffer 0 is already used by the Ladybug module which from
version 1A takes advantage of the OS4 module, which leaves 15 for the
OS4 system buffer.

Buffer layout
=============

The buffer consists of a header register followed by several areas
that appear in a defined order. The size of each area is kept in the
buffer header, which means that to get to a certain area, sizes of
areas before need to be summed and added to the buffer header
address. There are routines in OS4 to help with this, but normally you
will use more high level routines that deal with more complete
actions on the buffer, finding the area inside the buffer is just a
small detail.

The sizes are in the buffer header. Some are two nibbles (a byte) and
two are single nibble sizes, as there is a little shortage of room in
the buffer header. These single nibble ones have been chosen to be
those that are less likely to need a lot of registers.

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

The remaining for fields ``BF``, ``SC``, ``KA`` and ``SH`` are the
sizes of the different areas that follows the header. From the sizes
we know the size of each area and by knowing the order we can also
calculate the start address of each area by knowing the buffer header
address.

.. note::

   You do not normally need to worry about the fields in the buffer
   header as they are internal to OS4. It should be sufficient to use
   the provided routines in the API. It is important to use the provided
   routines when making changes to area sizes, as there are certain
   invariants that need to be maintained to keep the state consistent.

.. figure:: _static/memory.*

   Key assignments and buffer area.


Area sizes
==========

Most of the areas are defined as being simply the size, where 0 means
that the area is empty. For secondary key assignments we add two
additional registers for assignment bitmaps when it is non-zero,
meaning it will occupy 0, 3, 4 and up to 17 registers. The temporary
scratch area could in theory avoid having a nibble for its size, but
making it explicit simplifies the code. (It could in theory be
calculated from the rest of the sizes).


Shell registers
===============

Shells will be described in more detail later. For now it is enough to
know that a shell occupies 7 nibbles and two are stored into each buffer
shell register. The shell area is a stack, so the order of which they
appear describes how they affect the current behavior. The top of the
stack is in first register (the one with lowest address) and starts in
the lower half. There is no need to have any special marker (``F0``)
as with normal key assignments, as the shell registers are kept inside
the buffer structure.

Hosted buffer area
==================

This is an area that keeps track of application buffers. These have
much of the same properties as ordinary buffers, but are actually
stored inside the system buffer. They are somewhat easier to use than
making your own buffer code and are suitable for smaller buffers as
the overall buffer size (of the system buffer) is limited to 255
registers. They also have the advantage of having buffer identities
that are unrelated to normal buffers, making clashes far less likely.

Secondary assignments
=====================

.. index:: assignments; secondary, secondary assignments

Functions defined in secondary function address tables can be bound
to keys and are stored in the secondary assignment area. Two
assignments can be stored in one register. This gives seven nibbles
to describe one assignment. The function code has a two nibbles XROM
number and a three nibbles secondary function number. The two remaining
nibbles are the key code.

Due to using a single nibble being used for the size of this area, there is a
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
may need to run a routine to clear secondary assignment separately.

This also means that if you load key assignments over a secondary
assignment, the primary (ordinary) assignment takes precedence, but if
you clear the assignment through means outside OS4, the shadowed
secondary assignment may reappear.
