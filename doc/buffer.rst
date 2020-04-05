**************
System buffer
**************

A system buffer is used to keep track of the OS state. As all buffers
it resides in the memory area between key assignments and user
programs, the so called free area.

The buffer number used is 15 which is a buffer number that is probably
not used by any other module as of this writing. 15 is normally used
for key assignments, so how can this work you may wonder. Well, a
buffer as defined ny HP is supposed to have the first two nibbles
(4-bit values) set the same way. This allowes for 14 buffers, numbered
1-14. The time module uses buffer 10, so it set the first two nibbles
to `AA` (`A` hex is 10 decimal) for its buffer. However, `FF` would
not work as it could be mistaken for a key assignment register. The
answer is that we usually put `1F` there instead. The first nibble can
actually be any non-zero value except 15 and work properly with all
existing software. Taking advantage of this allowes for having buffer
0 and 15, for a total of 16 buffers. Buffer 0 is already used by the
Ladybug module which from versio 1 takes advatange of the OS4 module,
which leaves 15 for the OS4 system buffer.

Buffer layout
=============

The buffer makes use of a header register followed by several areas
that appear in a defined order. The size of each area is kept in the
buffer header which means that to get to a certain area you need to
sum the areas before it and then add one for the buffer header. There
are routines in OS4 to help with this, but normally you will use more
high level routines that deals with more complete actions on the
buffer, finding the area inside the buffer is just a small detai;.

The sizes are in the buffer header, but as they is a little shortage
of room, two of the sizes are single nibble and the reamining two uses
two nibbles. These have been chosen so that the two smaller ones are
less likely to need a lot of registers.

The header register is defined as follows:

ID SZ BF 'SC:KA' SH DF ST

The ID is the identifier which normally set to `1F`. The SZ field is
the size of the buffer. These two fields are defined by the HP-41
operating system and all buffers are like this.

The ST field is a set of flags that keeps track of the internal
state. You normally do not need to take these in account as they are
handled internally by OS4.

The DF field is a default postfix used by the semi-merged mechanism
and is also handled internally by OS4.

The remaning for fields BF, SC, KA and SH are the sizes of the
different areas that follows the header.

For the latest information and every detail it is probably a good idea
to also consult the source code of OS4.


Area sizes
==========

Most of the areas are defined as being simply the size, 0 means there
is no such area. For the secondary key assignments it adds two
additional registers for assignment bitmaps when it is non-zero,
meaning it will occupy 0, 3, 4 up to 17 registers. The temporary
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
making your own buffer code and are suitable for smaller buffers as
the overall buffer size (of the system buffer) is limited to 255
registers. They also have the advantage of having buffer identities
that are unrelated to normal buffers, making clashes far less likely.

Secondary assignments
=====================

Instructions defined in secondary function address tables can be bound
to keys and are stored in the secondary assignment area. Two
assignments are stored into one register and they actually have an
`F0` marker just like ordinary key assignment registers, though here
it servers no real practical use. The function code is the XROM
identity (5 bits) combined with the secondary function number in that
module. This means that the first 2048 secondary functions can be
assigned to keys.

Due to single nibble being used for the size, there is a limit of 30
secondary functions being assigned to keys.

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
