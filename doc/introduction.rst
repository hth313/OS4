************
Introduction
************

Welcome to the OS4 module for the HP-41 calculator!
OS4 is a powerful extension module which removes several limitations
that were originally designed into the HP-41 mainframe (the name used
by HP for the HP-41 firmware).

OS4 is a support module and requires other extension modules to expose
its capabilities to the user. Examples of such modules are Ladybug and
Boost. You can also use OS4 in your own module projects.

At a very high level OS4 does the following:

#. Removes the 64 function limitation for a single plug-in module
   page.

#. Support for programmable prompting XROM functions with one or two
   postfix arguments.

#. Provides a robust way of defining new alternative keyboard layouts,
   supporting both full and partial layouts without relying on key
   assignments.

#. A way to override the default display of the X register with
   something else.

#. Support for writing temporary modes, such as input modes, updating
   clock style modes and catalogs. The interval timer can be borrowed
   (if timer chip present) to allow for periodic updates and timeouts
   in such modes.

Plug-in module
==============

OS4 is a module image file that needs to be loaded in some programmable
plug-in module hardware. This can be a Clonix module, an MLDL or the
HP-41CL. It is also possible to use OS4 on HP-41 emulators.

The OS4 image is a 2x4K module. Two banks occupies a single 4K
page and it must be loaded to address page 4.

.. index:: memory; requirements

Resource requirements
=====================

OS4 allocates some space from the free memory pool. How much is taken
depends on what you actually do with it, but expect 2-7 registers for
modest use.

Apart from this, OS4 does not impose any restrictions on the
environment and will run comfortable on any HP-41C, HP-41CV, HP-41CX
or HP-41CL.

There is no XROM number used by this module as it is in page 4.

Using this guide
================

If you only want to use OS4 because another module requires it, simply
load the module image to page 4 and put this guide aside.

This guide is aimed to MCODE developers that want to explore and
develop modules using OS4. It can also be of interest to those
that want to know how it works internally or want to study how to
write HP-41 MCODE.

This guide assumes that you have a working knowledge of:

* The HP-41 calculator.
* Understanding of low level programming.

Further reading
===============

If you feel that you need to brush up your background knowledge, here
are some suggested reading:

* The *Owner's Manuals* supplied with the HP-41, Hewlett Packard Company
* *MCODE Programming for Beginners*, Ken Emery, 1985
* *Extend your HP-41*, W Mier-Jedrzejowicz, 1985
* NutStudio Tools Documentation
* A programmer's handbook, Poul Kaarup
* The VASM listings (annotated mainframe source code)

Document conventions
--------------------

Code examples are shown in lower case as the author feels it
somewhat more relaxing to the eyes. If MCODE instructions are
discussed in the text they are in upper case to make them stand out
more.

The development tools used in this guide is NutStudio tools which
contains a macro assembler, a linker, a librarian and a debugger. The
debugger includes a simulator and a comprehensive scripting
abilities. The assembler and linker fully supports generating banked
modules and can generate ELF/DWARF images to allow for source level
debugging. This has been a very useful tool chain in developing and
testing OS4. VisualStudio Code has been used as the a main debugger
front-end (user interface).

Acknowledgments
===============

Some of the code sequences used in OS4 have been borrowed from, or is
based on source code found elsewhere. This has been done in good faith
as the routines are very much needed for this project.
No permissions for this have been asked for, or been granted by the
original authors or copyright owners.

Part of the code is based on code that is copyright by Hewlett Packard
Company. This includes code used for the HP-41 power on sequence, the
search routine in function address tables (``ASRCH``), the code that
deals with the assignment bitmap. Also the key dispatch routine
``keyDispatch`` (originally named ``KEY-FC``) comes from the Time
module and the buffer search routine borrows ideas from the Time
module. The ``mapAssignments`` function (originally called ``RSTKCA``)
comes from the Extended Functions module with additions presents in
the Card Reader ROM. The range function GTINDX and friends codes from
the Extended functions module (also part of HP-41CX).

The ``XBCDBIN`` routine to convert a floating point number number to
binary (similar to ``BCDBIN`` found in mainframe, but with more useful
range) is written by Ken Emery, reference PPCCJ V11N5P6.

License
=======

The OS4 software and its manual are under copyright using a permissive
open source license.

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
