************
Installation
************

The OS4 image consists of two banks that occupy a single 4K
page and it must be loaded to address page 4.

How this is done depends on your hardware or emulator.

The module emulator you use must support a banked page 4 and also
allow for independent bank switching of page groups. The HP-41CL and
MLDL-2000 supports this. MLDLs and module emulation hardware from long
ago will probably not be able to support OS4.

.. note::
   Clonix and NoV modules will require an update of its firmware to a
   version that allows independent bank pages, as the original
   firmware bank switch all pages held by the module.

.. note::
   The hardware you use to load the OS4 module must be capable of
   reacting very fast and serve instruction fetches within 4 cycles after
   wake-up. The MLDL-2000 has shown certain problems in this area when
   powered only from the HP-41. It seems to work when powered over USB,
   that is, being plugged into a computer in the other end. A hardware
   modification to the MLDL-2000 may be needed to make this work.

Programming
===========

To make it easier to develop modules using OS4 the ``OS4.h`` header
file exists. This is provided in the source distribution along with
the fill source code. It is also available in NutStudio tools, making
it possible to just using a single include to get access to the entry
points and definitions suitable for the developer. Simply:

.. code-block:: ca65

   #include "OS4.h"

and you are good to go.
