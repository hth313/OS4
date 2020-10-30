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

## Version 1C

Bug fix release, November 2020.

## API version 1

This version bumps the API version to 1. If you requre any of the newly
added routines `resetMyBank`, `postfix4095` or `XBCDBIN` you need to
ensure that you are running with at least API version 1.

### Corrections

* Secondary functions without any semi-merged argument would not
  display properly in program mode. It could go and display DATA ERROR
  or do weird things rather than showing the instruction.

* Running secondary functions from program memory that did not have
  any semi-merged argument caused the execution of the instruction
  byte inside the text wrapper, which was the function number. This
  could cause all kinds of problems, but as they usually are low
  numbered it was often a LBL. If the secondary function was a test
  function that would skip the next line, it would not work as
  intended.

* Secondary functions using default semi-merged operand did not work
  properly and ended up giving `NONEXISTENT` error.

## Version 1B

Follow up release, May 2020.

### Corrections

* Loading OS4 by itself without Boost present caused the HP-41 not
  being able to turn on properly.
* The ensureHPIL routine would most likely report "`NO HP-IL`" even
  when there was an HP-IL module present.
* Secondary functions could not be execute if a printer was attached.

## Version 1A

Initial release, May 2020.

Initial developer release, also to be used with Ladybug 1A.
