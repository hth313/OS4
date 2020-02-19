Page 4 module
=============

The OS4 module occupy page 4 in the HP-41 memory map. This page is
normally used for the diagnostic ROM. Page 4 has a couple of special
properties that makes it different from all other pages.

# It only has a single (officially) defined entry point and that is
its very first address (4000 hex). This address is called whenever the
HP-41 wakes up (no matter if it is deep or light sleep). The normal
case is that page 4 is empty, in which case it executes as NOP, which
will cause an immediate return if called with a ``GOSUB`` instruction.
In the OS4 case, actual code is here and this is the means of which we
wedge the new functionality into the overall HP-41 behaviour.

# There are no poll vectors at the top of the page, like in other
plug-in modules.

# Do not disable the printer! Disabling a physical printer actually
causes it to relocate it to page 4, causing a bus conflict. The first
words of the printer modules are crafted carefully to make it able to
be called at location 4000 and return back, while at the same time
look as a proper module when plugged into page 6 (where it normally
goes).

# There can only be a single module in page 4, which makes the OS4
module incompatible with all other modules that occupy
page 4. Examples of this are the Forth module, Library#4 and various
diagnostic modules.

# The hardware you use to load the OS4 module must be capable of
reacting very fast and serve instruction fetches within 4 cycles after
wake-up. The MLDL2000 has shown certain problems in this area when
powered only from the HP-41. It seems to work when powered over USB,
that is, being plugged into a computer in the other end. A hardware
modification to the MLDL2000 may be needed to make this work.


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


Shell
=====

The main new feature that OS4 provides is the Shell concept. A shell
is basically a way to override the built-in keyboard and display
routine with a custom variant. The idea is to introduce new modes to
the HP-41 that allows for radically different behaviour than you are
used to, while still providing the additional features you are used to
have. 

Think of it like having the ability of changing the standard keyboard
layout, perhaps also altering how the X register is shown, how numeric
input is done, whithout doing key assignments. The actual
standard keyboard is under full control of an MCODE application,
while retaining the ability to reassign keys on top of it in user mode
and the HP-41 will go to light sleep as usual, being able to access
other modes, like program and alpha, serve alarms, show the clock or
catalogs. Basically everything works as you are used to, except that
the HP-41 is no longer limited to its built-in standard layout.
You get complete flexibility to alter the basic behaviour while
retaining all the abilities you are used to have!


Catalogs
========

Let look at the catalog feature of the HP-41. The early HP-41C
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

