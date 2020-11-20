**********
Addressing
**********

Addressing is the way we refer to different memory locations. The
HP-41 separates ROM from RAM  by using entirely different access
mechanisms. Normally this is typical for Harvard architectures though
on the HP-41, RAM works basically the same as I/O
peripherals. Addressing RAM is notoriously tricky on the HP-41, while
ROM is somewhat easier.

ROM
===

.. index:: memory; ROM

ROM normally stores programs. With the ``CXISA`` instruction that
was introduced with the HP-41 Nut CPU (compared to its predecessors),
it is possible to read ROM locations for data purposes. This can be
used to store strings, constants and tables. The address to read from
is placed in ``C[6:3]`` (the address field of the CPU ``C`` register)
and the fetched word is loaded to ``C[2:0]`` (the exponent field of
the same ``C`` register). On MLDLs, there is often a ``WROM``
instruction which does the opposite, it writes the word in ``C[2:0]]``
to ROM at the address in ``C[6:3]`` (actually RAM pretending to be ROM
to the HP-41).

It can be worth knowing that some instructions are not decoded by the
CPU, but by peripherals listening on the bus. The ``WROM`` is an
example of this. The Nut CPU sees it as a no-operation, but the MLDL
hardware decodes it and acts on it. The bank selection instructions
are similar in that they are handled by the ROM hardware and typically
act only if the bank select instruction is fetched from the same
memory chip. Peripheral device select, and its read and write
instructions are decoded by peripherals in a similar way.

Stack
=====

.. index:: stack; CPU, CPU stack

The four level internal stack also interacts with the ``C[6:3]``
field, making it possible to move between top of stack and
``C[6:3]``. This field is aligned with the mantissa field, but it is
shorter (four nibbles instead of ten), which makes it possible to use
instructions acting on the mantissa field to manipulate an address
without setting up any field pointers.
This is handy as it allows for manipulation of the return
address, making it possible to signal different outcomes of a
subroutine call by returning to slightly different
locations.

.. code-block:: ca65

   RTNP2:        c=stk
                 c=c+1   m
                 gotoc

This routine returns one address ahead of what it would normally
do. Here we get the address from top of the stack into
``C[6:3]``. Then it is incremented by one, but we operate on
the mantissa field which is wider. For practical reasons [#FFFF]_ this
gives identical result as if we had used the more narrow address
field. Finally the ``GOTOC`` instruction jumps to the address in
``C[6:3]`` (the stack address plus one in this case).

This style is used in many MCODE programs to handle returns with
different outcome, e.g. to signal a failure condition by returning to
the normal return address and the success case returns one step
ahead. This works as almost every instruction (including short
branches) is a single word on the Nut CPU.

As the stack is only four levels deep we need to take care
not nesting subroutines too deep. If you study existing code,
e.g. mainframe code, you will find that the number of subroutine
levels used is often documented. Should you nest too deep, you will
end up jumping to address 0 which is not entirely harmful as that is
where we end when starting execution, though the code will not work
the way it was supposed.

RAM
===

.. index:: memory; RAM

RAM registers are as wide as the internal registers, 56 bits or 14
nibbles. This is quite generous, but addressing RAM memory is kind of
painful. Typically we calculate and address in the ``C[2:0]`` field, also
called ``C.X`` field. The good news is that this is one of the more
powerful fields of the CPU, as we can load any 10-bit constant using
the ``LDI`` instruction and perform arithmetics there.

To address a RAM address, we use the ``DADD=C`` instruction which
takes the address from ``C.X`` and selects that data location.
After that we probably want to either
read or write, so the address in ``C.X`` is in the way. To make it
worse, if we want to perform any kind of address arithmetics, it is
natural to have the address in ``A.X``. Unfortunately, there is no
instruction to copy the contents of ``A.X`` to ``C.X``, instead we
need to exchange them, select the address location, then exchange (or
copy, as we can copy in the opposite direction) the address back the
``A.X`` to avoid losing it.

While the RAM chip allows for direct addressing inside the current
16-register window, we can almost never use it as the memory system is
quite flexible in how it partitions things, which makes it impossible to
know how an arbitrary address translates to a fixed offset inside the
current 16-register RAM chip.

The mainframe makes good use of the lower registers (address 0--15),
internally called chip 0. By selecting any low address (0--15), we
can access any of these registers by its number. For other RAM access,
we are essentially bound to addressing a single register at a time,
and repeat the selection procedure whenever we access any nearby
register.

.. note::

   It can be worth knowing that when the HP-15C code was ported over to
   the Advantage ROM, it relied a lot on fixed addressing. To avoid having
   to rewrite it to use dynamically calculated addresses, the HP engineers
   (ex-HP actually it seems) set up a fixed address area using a
   buffer so that fixed addressing could be used.
   This was done in a tricky way by storing a buffer below the key
   assignment registers (which is the only fixed location outside
   chip 0). However, it cannot normally be there, so a lot of measures
   were taken to not leave it there under normal operation.

.. rubric:: Footnotes
.. [#FFFF]
   The mantissa field increment may affect all 10 nibbles, not just
   the four in the address field. This happens when the value in the
   address field is ``0xffff``, which is unlikely in this case as it
   would mean the return address would be to the last address of the
   memory space, where there normally is a module checksum.
   Even if we should affect all nibbles in the mantissa field, it is
   rarely a problem anyway as there seldom is anything kept there of
   value in cases where we work on the address part of the field.
