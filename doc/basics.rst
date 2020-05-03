******
Basics
******

In this chapter we go through some concepts that are used internally
in OS4. This is not a primer on MCODE programming or the Nut CPU, you
are expected to have some basic understanding of MCODE programming.

Addressing
==========

.. index:: memory; ROM

ROM addressing is done using 16-bit addresses. This gives a total of
64K of addressable memory space. The HP-41 mainframe divides this up
in 4K blocks and treats each such block as a page. There is really
nothing magic about having such 4K blocks in the Nut architecture, it
is just a way of dividing up the memory to allow for extensibility.

Each memory location holds a 10-bit word and as most instructions are
single word. The only exceptions are the absolute jump and go
subroutine instructions which takes two words. However, they are able
to reach any fixed location in the 16-bit addressing space.
(The ``POWOFF`` instruction needs to be followed by a ``NOP``, so it can be seen
as taking two words as well).

As the Nut CPU has notoriously bad addressing capabilities, the only
way to read data from the ROM space is using the ``CXISA`` instruction
which expects an address in the ``6:3`` field of the C register.

Packed pointer
--------------

.. index:: packed pointers, pointers; packed

As we often work inside a single (often relocatable) 4K page it is
convenient to have a compact notation to describe a location inside
such page.
We will often know which page we are in, as we may be called
from it or having some pointer to some ROM structure at hand. Thus,
the 4-bit page address is typically known through some context we
already have.

Here we have a slight problem as we need 12 bits to describe such
address and a ROM word is only 10 bits wide. To make it possible to
describe a location inside the entire page, OS4 uses a concept called
a packed pointer which is a 12-bit page pointer right shifted two
locations, resulting in a single 10-bit value.

To unpack a packed pointer, the 10 bit value is left shifted two times
and combined with the page address. This means that the actual address
needs to be aligned at an even of four address, i.e. the address must
end with ``0``, ``4``, ``8`` or ``C`` (hex).

In other words, we can describe an address within my own module using
a single 10-bit word and it can be placed anywhere in a page
relocatable module, provided we follow the alignment constraint.

If you are using NutStudio tools the ``.align`` directive allows you
to easily specify an alignment of four and the ``.low12`` relocation
operator makes it possible to obtain a packed pointer:

.. code-block:: ca65

                 .align  4                  ; align table
   table:        .con    .low12 FAT1Start   ; single word pointer

Return status
=============

.. index:: return; different status, return address

A routine may need to deal with possible error conditions.  For
flexibility it may be better to return some error condition rather
than displaying an error message. The caller may have another way of
dealing with a failure, than showing an error message.

Due to the nature of the Nut CPU it turns out that it is often easy to
do this by returning to different locations rather than returning
some kind of error code. At the call site it looks like this:

.. code-block:: ca65

                 gosub   findBuffer
                 goto    noBuffer      ; (P+1) not found
   foundBuffer:  ...

We call this ``(P+n)`` and this works well thanks that almost all
instructions are single word (including short jumps) and we most often
want to branch to some alternative location and do something else.

The caller will just ``RTN`` to get to ``(P+1)``, and the success case
``(P+2)`` means it needs to return to the following location:

.. code-block:: ca65

   RTNP2:        c=stk
                 c=c+1   m
                 gotoc

The disadvantage here is that we clobber the address field
(``6:3``) of the C register, which means that we cannot pass any return
value there, as we often use the incremented return when successful.

Buffer advice
=============

.. index:: buffers; advice

I/O buffers, or just buffers for short, were defined from the beginning
in the HP-41 mainframe. However, they were first used by the Time
module, about two years after the introduction.

A buffer can have any size from a single register up to 255
registers. The first word is called the buffer header and the leftmost
four nibbles of this register have well defined meanings.

The first two are defined to be the buffer number 1-14 duplicated in
both nibbles. The Time module which used 10 will therefore put 10 in
both nibbles, or ``AA`` in hex.

The following two nibbles, a byte (eight bits) is the size of the
buffer. The buffer header is included in this count. Eight bits limits
the size to 255 (as the size 0 has no useful meaning).

Even though the buffer number was defined to be a double word like
``AA``, the information carried in the first nibble is only zero
or non-zero. Zero means that the buffer is marked for removal and
any other value means that it is active.

The last register used in buffer must be non-empty as the operating
system will scan from the other direction to find free registers and
the first non-zero register found is considered occupied.

Non-null registers
------------------

.. index:: buffers; null registers, null registers; in buffers

The Time module buffer code take precautions to never store a zero
value inside a buffer too. This is due to some 67/97 card reader bug
which I have not been able to find out what it means. I suspect that the
card reader (at least early versions) may scan for free registers
looking at individual registers also inside buffers.

As a result, you should probably avoid storing empty registers inside
the buffer to avoid potential memory corruption.

System buffer
=============

.. index:: buffers; system, system buffer

The OS4 module needs to store its own information somewhere.
The mainframe code typically uses the 0--15 RAM address
status area for such purposes, so that space already occupied. The
safest way to find some free memory is to use a buffer and the OS4
module allocated a system buffer with number 15.

The advantages of using a buffer are that it is a safe area and it can
grow (and shrink) dynamically as needed, rather than being fixed.

The disadvantages of using a buffer are that it takes a little bit
time to locate it and we may run out of space if there are no free
registers that can be occupied when the buffer needs to grow.

Keyboard
========

.. index:: keyboard

HP calculators before the arrival of the HP-41 used fixed keyboard
layouts and an increasing number of shift keys culminating with the HP-67 that
carried no less than three different shift keys. The HP-41 made away
with this and went back to a single shift key and the reassignable
keyboard in user mode.

As you are probably familiar with the HP-41, you know about its
ability to reassign keys, keys that talk and can be NULLed (to inspect
the current behavior).
There are actually a lot of different aspects on how the keyboard can
be reassigned and different classes of functional behavior that may
not be obvious until you look closer at it.


Reassigned keys
---------------

Keys can be reassigned and change behavior in user mode. If in doubt,
you can press and hold the key to see its current behavior. On top of
this, the top two rows are dynamically bound to single letter labels
in the current RPN program.

Key-codes
=========

.. index:: key codes

There are several ways key codes are represented in the HP-41.
The key codes returned from the keyboard as read by a machine
instruction does not match the ways we want to present them to the
user. The key codes presented to the user are for key assignments and
match a logical layout related to rows and columns on the
keyboard. Internally though, the 0--79 and 1--80 forms are used. These
forms are easily converted between by increment (or decrement) the
key code by one. The reason for the two forms is that the internal
key tables use an index starting at 0 (0--79 form), but 0 is reserved
for an empty assignment slot in the key assignment registers, so the
number is incremented by one, giving the 1--80 form, which makes it
possible to tell a deleted assignment apart from an active assignment.

Internal key tables are just an array of function codes where we take
advantage of the extra two bits in a ROM word to decode a special
meanings, like a digit entry key or a function that ends digit entry or
not. As we want to allow storing also XROM functions on keyboard, the
actual encoding used by OS4 differs somewhat from the ones used in the
operating system.

If most of the keys are given a meaning it makes sense to define a
keyboard like an array indexed in 0--79 form, just like the built in
keyboards. As an alternative, OS4 provides a way of defining a sparse
keyboard where a 0--79 key-code is stored paired with its
function. In this case a linear scan is used, which saves space
if few keys are defined, while still being reasonable fast.

As also secondary functions can be bound to keyboard definitions,
there are some further schemes and details on how more advanced
keyboards are defined. This is further described in XXXX.

Return to mainframe
===================

.. index:: functions; returning from, return from functions

The normal behavior for an MCODE function is to exit using a ``RTN``
instruction. As the invocation mechanism push the address of ``NFRPU``
on the stack before giving control, this is where we will normally
return. This exit point enables stack lift (sets the internal push
flag, CPU flag 11) and falls into ``NFRC``.

If you used up all four levels of CPU stack, you must exit back using
a ``GOLONG`` instruction instead. By design, XKD functions (seldom
used functions that execute immediately on key down) does not have
``NFRPU`` pushed on the stack, so they also must ``GOLONG`` back. Such
functions may want to return back to ``NFRKB`` instead as it waits for
key release and resets the keyboard (useful as it acted immediately on
key down).
