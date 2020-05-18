# Release Notes for OS4

## Important information

OS4 is a bank switched module which consists of two pages that must be
loaded to page 4.

OS4 relies on hardware that bank switches page 4 independently of other
application modules. The original Clonix firmware bank switch all
pages loaded into a the same module, which means it does not work to
load OS4 and banked modules using OS4 to the same Clonix module.
A work around is to have OS4 in one Clonix module and other bank
switched modules that uses OS4 in a second Clonix module.

OS4 has been tested and is known to work with MLDL-2000 and HP-41CL.
OS4 also works on emulators and so far been tested successfully on
i41CX+ and dbnut (from NutStudio tools).

## Version 1A

Initial release, May 2020.

Initial developer release, also to be used with Ladybug 1A.
