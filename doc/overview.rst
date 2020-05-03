********
Overview
********


OS4 is intended to be a foundation for writing powerful new MCODE
modules for the HP-41.

Page 4 module
=============

OS4 must be loaded to page 4 to work. The reason it requires page 4 is
that OS4 needs to have access to the take over vector at address
``0x4000``, which was originally intended for diagnostic ROMs.

OS4 uses this vector to wedge itself into the existing operating
system. It is unfortunately impossible to do something like OS4
without using this vector, as using a poll vector is not powerful
enough.

This means that OS4 and modules depending on it are incompatible
with anything else that require page 4. These includes:

#. Diagnostic ROMs. These are take-over ROMs that will not give control back
   to normal operation.

#. Do not disable the printer. When a printer is disabled by using the switch
   it relocates itself at page 4. This will cause bus conflicts, so do not
   try that.

#. Modules using Library#4. This is a popular library that resides in
   page 4 is incompatible with OS4. This naturally includes any
   modules that rely on Library#4

Page 4 has only a single (officially) defined entry point and that is
its first address (``0x4000``). This address is called whenever the
HP-41 wakes up (no matter if it is deep or light sleep) and when it is
about to go back to light sleep again. The normal case is that page 4
is empty, in which case it executes as NOP, which will cause an
immediate return if called with a ``GOSUB`` instruction.
In the OS4 case there is actual code here that takes control. It is not
a complete take over, as it reuses as much as possible of the already
existing built-in functionality as possible.

There are no poll vectors at the top of the page like there are in
normal plug-in modules.

Shells
======

.. index:: shells

A new concept provided is a *shell* which provides
a way of installing new keyboard and display behaviors.
Such behaviors can be activated by the user to turn the
calculator into something very different compared to the default. This
transformation can be anything from mild to very dramatic.

A shell keyboard definition changes the standard keyboard and is
also active outside of user mode. In user mode it is possible to make
assignments as usual and you have the usual dynamic assignments on the
top key rows. With OS4 such dynamic assignments are optional.

Basically everything works as you are used to, except that the HP-41
no longer is limited to its standard built-in keyboard layout. You get complete
flexibility to alter the basic behavior while retaining all the
capabilities you are used to have.

Message system
==============

.. index:: message system

A new internal message handler system is now available. In some way it
can be seen as somewhat related to poll vectors, but it is more
flexible and more dynamic. Message handler descriptors are stored in
the same stack as the shell descriptors.

It is possible for a message originator to send (broadcast)
messages to anyone that are interested in a particular event. It also
allows for collaboration between the message originator and the
receivers. Messages can be about anything of interest and is in no way
tied to the keyboard or display.

The message system can be used to notify such things as that a new
command is keyed in (which should clear the RPN return stack), or
that the ``CAT`` function was entered with a catalog number that was
not known. A message can then be sent to ask if there are anyone who
wants to act on it, i.e. ``CAT 23``. Any plug-in module present can
register itself and act on such messages.

The main software repository contains a list of known messages and this list
can be added to as needed.


Secondary FAT
=============

.. index:: secondary functions, functions; secondary

A 4K module page is limited to 64 functions. This may have been an
ample amount in the early days when the HP-41 was designed. However, later
we got banked modules allowing up to 4 banks to be stacked into a single 4K
page. With 16K it is possible to host a lot of functionality in a
single addressable page and 64 functions may be too limiting.

OS4 defines an extension to the existing FAT mechanism which
greatly expands the number of functions in a 4K address page. You can
have up to 4096 additional functions (which would be very hard to fit
into 16K words, if you  think about it).

These extra functions may reside in banked pages. As with any other
function, they can be on redefined keyboard layouts (shell keyboards),
they will display in program mode and they can be assigned to keys.
If you use an extension to the ``XEQ`` and ``ASN`` keys, you can access them
by name as any other function. In fact, they will in almost every
way act as any ordinary FAT function.

The limitations are mainly what is imposed by semi-merged operands, see below.


Semi-merged operands
====================

.. index:: functions; semi-merged

Functions in plug-in modules can display a prompt like any built in
function, but the original mainframe does not allow such functions
to be stored into a program.

OS4 provides semi-merged functions which allows plug-in
modules to have a prompting behavior that can be stored in programs.
You key such combined function in the normal way in program mode and
they will be properly recorded in the program. They will also display
and execute correctly (with some caveats).

Built-in support for ordinary style postfix operands are provided.
Full custom prompting behavior is also possible, but you will need to provide
additional code on your own for such alternative behavior.
Such custom behavior need to provide all expected behavior, such as
recording, display and proper execution.

In addition, secondary FAT functions can also have semi-merged behavior, including
custom behavior. There are essentially no limitations on how you can combine these
features.

Library routines
================

In addition to the above, OS4 provides many useful routines that
makes the life easier for the MCODE developer.

Banking
=======

.. index:: banking

The HP-41 banking mechanism is implemented by the memory systems and
the CPU is completely unaware of this. This may seem a bit
strange, but the Nut CPU actually executes unknown functions as a
no operation and bus peripherals decipher the bus activity and act on
the instructions instead.

The 1LG9 ROM memory chip provided by HP is capable of using two
banks. It was used in the HP-41CX and by some plug-in modules.
Such banks are presented at the same page address in the memory map,
though of course only one at a time. The bank switch functions are
used to switch between the banks and careful layout of the software
allows for switching banks in and out in a controlled way, allowing
more memory to be used by the system. Most recently introduced memory
systems allow for up to  four banks, this includes the MLDL-2000,
Clonix and HP-41CL.

The 1LG9 only act on bank switch instruction executed from /within/
its own memory. The MLDL-2000 and HP-41CL mimics this behavior by
pairing, so that page 8 and 9 are bank switched together, then pages
following are paired in the same way. The original Clonix module on
the other hand switches banks for all pages it serves and how that
manifests itself depends on the size of the Clonix module and more
specifically which pages it is configured to serve.

As a result of this, a banked module may or may not affect other
modules, depending on which memory hardware and in part also how it is
configured. While this may sound a bit scary, in normal situations
this is not a problem as banked software is typically written so that
secondary banks are only active in a temporary fashion and the bank is
restored to the primary bank when control is given back to the
operating system.

However, it also means that if you intend to make a very advanced
module and try to leave secondary banks active while not in control,
while you *may* get such setup to work in a given setup, it may
fail when a user loads your module image to another memory system or
calculator configuration. Thus, it is probably safest to avoid such
practices.

Catalogs
========

The original HP-41C mainframe provided three catalogs (1--3) to show
user programs, functions in plug-in modules and built-in
functions respectively. While you are in a catalog, you can stop and
step. When the catalog is stopped the HP-41 goes to light sleep and
consumes less battery power. If you press an undefined key, like
starting numeric entry, the catalogs exits and the pressed key is
obeyed.

The HP-41CX adds three additional catalogs and enhanced the previous
catalogs. These new catalogs differ from the original
catalogs and are more like special programs. When the catalog is
stopped the HP-41 is still running at full speed in a busy loop,
consuming more power. If an undefined key is pressed, like numeric
entry, the key is ignored and the catalog remains active.

The reason for this is that the original catalogs were carefully
crafted to exist in the operating system in a very specific way. The
mechanism used is very specific for this purpose and it was just
easier to provide the new ones as add-ons with a somewhat inconsistent
behavior. Part of the reason was also that two of the three new
catalogs already existed as XROM functions in the Time and Extended
Functions modules, thus the catalog merely calls the already existing
EMDIR and ALMCAT functions.

The shell mechanism provides a shell variant that is ideally suited
for implementing new catalogs with similar properties as the original
catalogs. This includes going to sleep consuming less power while
waiting for a key press and ability to terminate the catalog and
perform the action of a key, if not defined by the catalog. New
catalogs can even be implemented by different modules and accessed
using the same catalog key.


Reserving identities
====================

.. index:: reserving identities, identities; reserving

The original HP-41 never reserved buffer identities in a central
place. This has resulted in that different modules may use the same
buffer identity for different purposes, causing incompatibilities
between such modules. A similar problem exists for XROM identity
allocations, but this was unavoidable as only 31 such are available
and over the years hundreds of modules have been made.

As OS4 lists identities for extension points and hosted buffers in a
source repository on Github, there is a single central place where
they are defined. If you want to reserve such identities, simply edit
the OS4 header file and issue a pull request to reserve some identity,
avoiding potential clashes.
