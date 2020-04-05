************
Introduction
************

Welcome to the OS4 module for the HP-41 calculator!
OS4 is a powerful extension module which removes several limitations
that were originally designed into the HP-41 mainframe (the name used
by HP for the firmware).

OS4 is a support module for other extension modules. You will need at
least one module that makes use of OS4 to unlock the capabilities.
One such module is Boost which makes good use of OS4. You can also use
OS4 in your own module projects.

At a very high level, OS4 provides the following:

#. Removes the 64 function limitation for a single plug-in module

#. Support for programmable prompting XROM functions with one or two
   postfix arguments

#. A robust way of defining new alternative keyboard layouts,
   supporting both full and partial layouts without using key
   assignments.

#. Such new keyboards can be coupled with its own custom default
   display behavior.

#. Support for writing temporary modes, such as input modes, clock or
   catalogs, with interval timer support (if timer chip present) for
   periodic updates or timeout.

Plug-in module
==============

OS4 is a module image that needs to be put in some programmable
plug-in module hardware. This can be a Clonix module, an MLDL or some
kind of ROM emulator. You need to consult the documentation of ROM
emulation hardware for this.

It is also possible to use OS4 on HP-41 emulators.

The OS4 image is a 2x4K module. Two banks occupies a single 4K
page and must be loaded to address page 4.

This release
============

This version, 0A is meant for developers and users of Ladybug 1A. The
Boost module is currently in development, but can be accessed for
early adopters.

Resource requirements
=====================

OS4 allocates some space from the free memory pool. How much is taken
depends on what you actually do with it, but expect at least 3-7
registers.

Apart from this, it does not impose any restrictions on the
environment and will run comfortable on any HP-41C, HP-41CV, HP-41CX
or HP-41CL.

There is no XROM number used by this module as it is in page 4.

Using this guide
================

This guide assumes that you have a working knowledge about:

* The HP-41 calculator, especially its RPN system.
* Have a good understanding of different number bases and working with
  different word sizes. Basically bits as used in most computers at
  its lowest level.


Further reading
===============

If you feel that you need to brush up your background knowledge, here
are some suggested reading:

* The *Owner's Manuals* supplied with the HP-41, Hewlett Packard Company.
* *Extend your HP-41*, W Mier-Jedrzejowicz, 1985.
* VASM listings
* Boost manual


License
=======

The OS4 software and its manual is copyright by Håkan Thörngren
2017 under the MIT license.

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
