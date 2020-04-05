**********
Addressing
**********

Addressing is the way we refer to different memory locations. The
HP-41 separates ROM from RAM  by using entirely different access
mechanisms. Normally this is typical for Harvard architectures, though
on the HP-41, RAM works basically the same as I/O. Addressing both
ROM and RAM are actually notoriously tricky on the HP-41, though ROM
is somewhat easier.

ROM
===

ROM normally stores programs, but with the ``CXISA`` instruction that
was introduced with the HP-41 Nut CPU (compared to its predecessors),
it is possible to read ROM locations for data purposes. This can be
used to store strings, constants and tables. The address is kept in
``C[6:3]`` and the fetched word is loaded to ``C[2:0]``. On MLDLs,
there is often a ``WROM`` instruction which does the opposite, store
the word to ROM (actually RAM pretending to be ROM to the HP-41).

It can be worth knowing that some instructions are not decoded by the
CPU, but by peripherals listening on the bus. The ``WROM`` is an
example of this. The Nut CPU sees it as a no-operation, but the MLDL
hardware decodes it and acts on it. The bank selection instructions
are handled by the ROM hardware and typically act only if the bank
select instruction is fetched from the same memory chip.
I/O selection, read and write instructions are decoded by peripherals
in a similar way.


Stack
=====

The four level internal stack also interacts with the ``C[6:3]``
field, making it possible to move between top of stack and
``C[6:3]``. The low nibble corresponds to the low part of the mantissa
field, making it possible to use instruction acting on the mantissa
field to manipulate an address without setting up any field pointers.
This is handy as it allows for manipulation of the return
address, making it possible to signal different outcomes of a
subroutine call by returning to slightly different
positions.

<<example>>

Furthermore, we have the ``GOTOC`` instruction which loads
``PC`` with the ``C[6:3]`` field. This is useful after calculating a
destination address in that we immediately can transfer control to it
without pushing it on the stack and issuing a ``RTN``, a sometimes
used idiom on other CPUs.

The stack being only four levels deep means that we need to take care
not nesting subroutines too deep, which is why you find entry points
in mainframe often state the number of extra subroutine levels
used. Should you nest to deep, you will end up jumping to address 0
which is not entirely harmful as that is where we end when starting
execution, though the code will not do what it is supposed to do.


RAM
===

The RAM registers are as wide as the internal registers, 56 bits or 14
nibbles. This is quite generous, but addressing RAM memory is kind of
painful. Typically we calculate and address in the ``C[2:0]``, also
called ``C.X`` field. The good new is that this is one of the more
powerful fields of the CPU, as we can load any 10-bit constant using
the ``LDI`` instruction and perform arithmetics there.

To address a RAM address, we use the ``DADD=C`` instruction which
takes the address from ``C.X``. After that we probably want to either
read or write, so the address in ``C.X`` is in the way. To make it
worse, if we want to perform any kind of address arithmetics, it is
natural to have the address in ``A.X``. Unfortunately, there is no
instruction to copy the contents of ``A.X`` to ``C.X``, instead we
need to exchange them, select the address, then exchange (or copy, as
we can copy in the opposite direction) the address back the ``A.X`` to
avoid losing it.

While the RAM chip allows for direct addressing inside the current
16-register window, we can almost never use it as the memory system is
quite flexible in how it partitions things, making it impossible to
know how an arbitrary address translates to a fixed offset inside the
current 16-register RAM chip.

The mainframe makes good use of the lowest 16 register as status set 0
(SS0). By selecting any low address, we can access these registers by
number.

.. note::
   The only exception is location 0 in the chip, which is special
   in the there is no instruction read it, it has to be read by first
   selecting its address and then using ``C=DATA`` which reads currently
   selected register.

It can be worth knowing that when the HP-15C code was ported over to
the Advantage ROM, it relied a lot on fixed addressing. To avoid having
to rewrite it to use dynamically calculated addresses, the HP engineers
(ex-HP actually it seems) set up a fixed address area using a
buffer so that fixed addressing could be used.
This was done in a tricky way by storing a buffer below the key
assignment registers (which is the only fixed location outside
SS0). However, it cannot normally be there, so a lot of measures were
taken to not leave it there under normal operation.
