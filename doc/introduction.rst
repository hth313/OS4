************
Introduction
************

Welcome to the OS4 module for the HP-41 calculator!
OS4 is a powerful extension module which removes several limitations
that were originally designed into the HP-41 mainframe (the name used
by HP for the HP-41 firmware).

OS4 is a support module and requires other extension modules to expose
its capabilities to the user. One such module is Boost which makes
good use of OS4. You can also use OS4 in your own module projects.

At a very high level, OS4 does the following:

#. Removes the 64 function limitation for a single plug-in module
   page.

#. Support for programmable prompting XROM functions with one or two
   postfix arguments.

#. A robust way of defining new alternative keyboard layouts,
   supporting both full and partial layouts without relying on key
   assignments.

#. A way to override the default display of the X register with
   something different.

#. Support for writing temporary modes, such as input modes, clock
   style modes or catalogs, with interval timer support (if timer chip
   present) for periodic updates or timeout.

Plug-in module
==============

OS4 is a module image file that needs to be put in some programmable
plug-in module hardware. This can be a Clonix module, an MLDL or some
kind of ROM emulator.

It is also possible to use OS4 on HP-41 emulators.

The OS4 image is a 2x4K module. Two banks occupies a single 4K
page and must be loaded to address page 4.

This release
============

This version, 0A is meant for developers and users of Ladybug 1A. The
Boost module is currently in development, but is available to early
adopters.

Resource requirements
=====================

OS4 allocates some space from the free memory pool. How much is taken
depends on what you actually do with it, but expect around 2-7
registers for modest use.

Apart from this, it does not impose any restrictions on the
environment and will run comfortable on any HP-41C, HP-41CV, HP-41CX
or HP-41CL.

There is no XROM number used by this module as it is in page 4.

Using this guide
================

This guide assumes that you have a working knowledge about:

* The HP-41 calculator.
* Some understanding of, or interest in MCODE programming.

Furthermore, the reader of this guide is assumed to have some
understanding of programming the HP-41 at the MCODE level. It is after
all mainly aimed for developers of plug-in modules.

Thus, it is assumed that you understand notations such as ``C[2:0]``
or ``C.X`` which refers to a field in CPU ``C`` register. In this case
they both are the same, they refer to the three rightmost nibbles in
the register (the exponent field).

Further reading
===============

If you feel that you need to brush up your background knowledge, here
are some suggested reading:

* The *Owner's Manuals* supplied with the HP-41, Hewlett Packard Company.
* *Extend your HP-41*, W Mier-Jedrzejowicz, 1985.
* A programmer's handbook, Poul Kaarup
* The VASM listings (annotated mainframe source code)
* Boost manual

Document conventions
--------------------

Code examples are typically done in lower case as the author feels it
somewhat more relaxing to the eyes. If MCODE instructions are
discussed in the text they are however in upper case to make them
stand out more.


License
=======

The OS4 software and its manual is copyright by Håkan Thörngren.

MIT License

Copyright (c) 2020 Håkan Thörngren

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
