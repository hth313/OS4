********
Overview
********


OS4 is a system extension module that provides one major new
concept and expands existing features beyond what was originally
intended in the design of the original HP-41 mainframe (firmware).

OS4 is intended to be a foundation for writing powerful new MCODE
modules for the HP-41.

Page 4 module
=============

OS4 must be loaded to page 4 to work. The reason to require page 4 is
that OS4 needs to have access to the take over vector at address `4000`,
which was originally intended for diagnostic ROMs.

OS4 uses this vector to wedge itself into the operating system
and it is unfortunately impossible to do something like OS4 without
using this vector, as using a poll vector is not powerful enough.

This means that OS4 and modules depending on it are incompatible
with anything else that require page 4. These includes:

#. Diagnostic ROMs. These are take-over ROMs that will not give control back
   to normal operation.

#. Do not disable the printer. When a printer is disabled by using the switch
   it relocates itself at page 4. This will cause bus conflicts, so do not
   try that.

#. Modules using Library 4. This is a popular library that reside in page 4
   and OS4 is not compatible with those. This includes Library#4 and
   various diagnostic modules.

Page 4 has only a single (officially) defined entry point and that is
its very first address (4000 hex). This address is called whenever the
HP-41 wakes up (no matter if it is deep or light sleep). The normal
case is that page 4 is empty, in which case it executes as NOP, which
will cause an immediate return if called with a ``GOSUB`` instruction.
In the OS4 case, actual code is here and this is the means of which we
wedge the new functionality into the overall HP-41 behaviour.

There are no poll vectors at the top of the page, like in other
plug-in modules.

.. note::
   The hardware you use to load the OS4 module must be capable of
   reacting very fast and serve instruction fetches within 4 cycles after
   wake-up. The MLDL2000 has shown certain problems in this area when
   powered only from the HP-41. It seems to work when powered over USB,
   that is, being plugged into a computer in the other end. A hardware
   modification to the MLDL2000 may be needed to make this work.

Shells
======

The major new concept provided is a *shell* stack. Somewhat simplified, a
shell provides a way of installing new keyboard and display
behaviors. Such behaviors can be activated by the user to turn the
calculator into something very different compared to the default. This
transformation can be anything from mild to very dramatic.

An altered shell keyboard definition changes the standard keyboard and is
also active outside user mode. In fact, in user mode you can make assignments
over it as usual and you can optionally have the usual dynamic assignments
to the top key rows.

Basically everything works as you are used to, except that the HP-41
is no longer limited to its built-in standard layout. You get complete
flexibility to alter the basic behaviour while retaining all the
capabilities you are used to have!

Message system
==============

A new internal message handler system is now available. In some way it
can be seen as somewhat related to poll vectors, but it is more
flexible and more dynamic. A message handler descriptor is very
similar to a shell descriptor and reside in the same stack.

This makes it possible for a message originator to send (broadcast)
messages to anyone that are interested in a particular event. It also
allows for collaboration between the message originator and the
receivers. This allows for extending functionality in ways that may
have nothing to do with the keyboard or the display.

The message system can be used to notify such things as that a new
command is keyed in (which should clear the RPN return stack), or
that the ``CAT`` function was entered with a catalog number that was
not known. A message can be sent to ask if there are anyone who
wants to act on say ``CAT 23``. Any plug-in module present can register itself
and act on such messages.

The main software repository contains a list of known messages and this list
can be extended as needed.


Secondary FAT
=============

A 4K module page is limited to 64 instructions. This may have been an
ample amount in the early days when the HP-41 was designed. However, later
we got banked modules allowing up to 4 banks to be stacked into a single 4K
page. With 16K it is possible to host a lot of functionality in a
single addressable page and cap of 64 instructions may be a bit limiting.

OS4 defines an extension to the existing FAT mechanism which
greatly expands the number of instructions in a 4K address page. Depending on
how you see it, you get the ability to have an additional 1023
instructions in an 4K address page.
If you accept some limitations you can go up to 4096 additional instructions
(which would be very hard to fit into 16K words, if you think about it).

These extra instructions can reside in banked pages. They can be used
as functions on your redefined keyboard layouts (shell keyboards).
They will display in program mode and they can even be assigned to keys.
If you use an extension to the ``XEQ`` and ``ASN`` keys, you can access them
by name as any other instruction and they will in almost every way act as any
ordinary FAT instruction.

The limitations are mainly what is imposed by semi-merged operands, see below.


Semi-merged operands
====================

Instructions in plug-in modules can display a prompt like any built in
instruction, but the original mainframe is does not allow such instructions
to be stored into a program.

OS4 provides semi-merged instructions which allows plug-in
modules to have a prompting behavior that can be stored into program.
You key such combined instruction in program mode and they will be properly
recorded in the program. They will also display and execute properly
(with some caveats).

Built-in support for ordinary style postfix operands are provided.
Full custom prompting behavior is also possible, but you will need to provide
additional code on your own for such extended behavior. This is quite natural,
as you are making your own design.
Such custom behavior need to provide all aspects, such as recording, display and
proper execution.

In addition, secondary FAT instructions can have semi-merged behavior, including
custom behavior. There are essentially no limitations on how you can combine these
features.

Library routines
================

In addition to the above, OS4 provides many useful routines that
makes the life easier for the MCODE developer.

Banking
=======

The HP-41 banking mechanism is implemented by the memory systems and
the CPU is completely unaware of these instructions. This may seem a bit
strange, but the Nut CPU actually executes unknown instructions as a
no operation and certain bus peripherals descipher the bus activity
and act on the instructions instead.

The HP provided ILG9 chip which was used in later plug-in modules (and
the HP-41CX) is capable of using two banks. Such banks are presented
at the same page in the memory map, though of course only one at a
time! The bank switch instructions are used to switch between the
banks and careful layout of the software allows for switching banks in
and out in a controlled way, allowing more memory to be used by the
system. Most recently introduced memory systems allow for up to four
banks, this includes the MLDL2000, Clonix and HP-41CL.

The 1LG9 only act on bank switch instruction executed from /within/
its own memory. The MLDL2000 and HP-41CL mimics this behaviour by
pairing, so that page 8 and 9 are bank swithed together, then further
pages are paired in the same way. The Clonix module on the other hand
switches banks for all pages it serves and how that manifests itself
depends on the size of the Clonix module and more specifically which
pages it is configured to serve.

As a result of this, a banked module may or may not affect other
modules, depending on which memory hardware and in part also how it is
configured. While this may sound a bit scary, in normal situations
this is not a problem as banked software is typically written so that
secondary banks are only active in a temporary fashion and the bank is
restored to the primary bank when control is given back to the
operating system.

However, it also means that if you intend to make a very advanced
module and try to leave secondary banks active while not in control,
you /may/ get such setup to work in a given setup, but it may fail
when a user loads your module image to another memory system or
calculator configuration. Thus, it is probably safest to avoid such
practises.

Catalogs
========

Consider the catalog feature of the HP-41. The early HP-41C
provided 3 catalogs to show user programs, plugin modules and built-in
functions respectively. While you are in a catalog, you can stop and
step. When the catalog is stopped the HP-41 goes to light sleep and
consumes less battery power. If you press an underfined key, like
starting numeric entry, the catalogs exits and the pressed key is
obeyed.

The HP-41CX adds three additional catalogs and enhanced the existing
catalogs a bit. These new catalogs differs from the original
catalogs and are more like special programs. When the catalog is
stopped the HP-41 is still running at full speed in a busy loop,
consuming more power. If an undefined key is pressed, like numeric
entry, it has no effect, the key is ignored and the catalog remains
active.

The reason for this is that the original catalogs were carefully
crafted to exist in the operating system in a very specific way. The
mechanism used is very specific for this purpose and it was just
easier to provide the new ones as add-ons with somewhat inconsistent
behavior. Part of the reason was also that two of the three new
catalogs already existed as XROM functions in the Time and Extended
Functions modules, thus the catalog merely calls the provided EMDIR
and ALMCAT instructions.

The shell mechanism provides a couple of different shell variants which
we will explore in more detail later. Shells provide a very flexible
and extensible mechanismes that among other things are well suited
implementing new catalogs with similar properties as the original
on ess. New catalogs can even be implemented by different modules and
accessed from the same catalog key functionality.


Reserving identities
====================

The origial HP-41 never reserved buffer identities in a central
place. This has resulted in that different modules may use the same
buffer identity for different purposes, causing incompatibilities
between such modules. A similar problem exists for XROM identity
allocations, but this was unavoidable as only 31 such are available
and over the years hundreds of modules have been made.

As OS4 lists identities for extension points and hosted buffers in a
source respository on Github, there is a single central place where
they are defined. If you want to reserve such identities, simply edit
the OS4 header file and issue a pull request to reserve such identies,
avoiding potential clashes.
