************
Installation
************

.. index:: installation

The OS4 image consists of two banks that occupy a single 4K
page and it must be loaded to address page 4.

How this is done depends on your hardware or emulator.

The module emulator you use must support a banked page 4 and also
allow for independent bank switching of page groups. The HP-41CL and
MLDL-2000 support this. Other MLDLs and module emulation hardware from
long ago will probably not be able to support OS4.

.. index:: Clonix, NoV modules

.. note::
   Clonix and NoV modules will require an update of its firmware to a
   version that allows independent bank pages, as the original
   firmware bank switch all pages simultaneously held by the module.
   A work around is to load OS4 and non-banked modules in one
   Clonix module while banked application modules are loaded to a
   second Clonix module.

.. note::
   The hardware you use to load the OS4 module must be capable of
   reacting very fast and serve instruction fetches within 4 cycles after
   wake-up. The MLDL-2000 has shown certain problems in this area when
   powered by the HP-41. It seems to work when powered over USB,
   that is, being plugged into a computer in the other end. A hardware
   modification to the MLDL-2000 may be needed to make it work
   reliably with OS4 when power by the HP-41 alone.

Programming
===========

To make it easier to develop modules using OS4 the ``OS4.h`` header
file exists. This is provided in the source distribution along with
the fill source code. It is also available in NutStudio tools
distribution. This single header file provides definitions of all
entry points and useful definitions. Include it in your source file
and you are good to go:

.. code-block:: ca65

   #include "OS4.h"



Version check
=============

.. index:: API version check, version check

To allow future changes to OS4 there is a mechanism for checking if
the plugged in OS4 module is compatible with your own module. The
``checkApiVersionOS4`` routine should be called from the deep wake up
poll vector entry:

.. code-block:: ca65

   deepWake:     n=c                   ; N= ROMCHK state
                 ldi     0x000         ; I need major version 0 at least
                 gosub   checkApiVersionOS4

The number passed to ``checkApiVersionOS4`` is the required version of
OS4. You can find the current version number used in such context
early in the ``OS4.h`` header file.

This version number is API related and is not the same as the version
of the OS4 release.

You can either load the version number defined in ``OS4.h``, or
better, the API version your software requires.

.. note::

   If you use the ``ApiVersionOS4`` constant defined in ``OS4.h``,
   then your software will automatically demand a later version of OS4
   if you upgrade OS4, even if you do not actually use any of the
   additional features provided with that version.

This API version number consists of two parts. The lower 8 bits are an
increasing number that is bumped whenever new entry points are added,
or additional things are provided by existing entry points. The upper
4 bits are a major version number that must match precisely. Changing
the major number means that anything may have been moved or altered
(except the version check itself).

.. note::

   If the version is old, "OLD OS4" is displayed as an error
   message. This may have the consequence that poll entries are
   skipped, but the calculator may still work (to some
   degree). However, anything may be broken and the user should
   hopefully understand that the current configuration should not be
   used.
