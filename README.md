The HP-41 OS4 module
====================

Welcome to the OS4 module for the HP-41 calculator!
OS4 is a powerful extension module which removes several limitations
that were originally designed into the HP-41 mainframe (the name used
by HP for the HP-41 firmware).

OS4 is a support module and requires other extension modules to expose
its capabilities to the user. Examples of such modules are Ladybug and
Boost. You can also use OS4 in your own module projects.

At a very high level OS4 does the following:

1. Removes the 64 function limitation for a single plug-in module
   page.

2. Support for programmable prompting XROM functions with one or two
   postfix arguments.

3. Provides a robust way of defining new alternative keyboard layouts,
   supporting both full and partial layouts without relying on key
   assignments.

4. A way to override the default display of the X register with
   something else.

5. Support for writing temporary modes, such as input modes, updating
   clock style modes and catalogs. The interval timer can be borrowed
   (if timer chip present) to allow for periodic updates and timeouts
   in such modes.
