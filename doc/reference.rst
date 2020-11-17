**********************
Entry points reference
**********************

API version check
=================

checkApiVersionOS4
------------------

.. index:: API version check, version check

**Entry point:** ``4F80``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; checkApiVersionOS4 docstart
   :end-before:  ;;; checkApiVersionOS4 docend


Fundamentals
============

Basic building blocks for dealing with packed pointers and other small
routines.

jump via packed pointer
-----------------------

.. index:: jump via packed pointer

This is a set of routines that fetch a packed pointer by offset
displacement from a given base address and pass control to it. By
using the ``GOSUB`` instruction to one of these routines you perform a
table indirect call to a packed pointer address. You can also use the
``GOLONG`` instruction to just transfer control to it.

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; jumpPacked docstart
   :end-before:  ;;; jumpPacked docend

call aligned subroutine
-----------------------

.. index:: call aligned subroutine, aligned subroutine

These are alternatives to the three word page relative jump and call
routines provided by mainframe. They require 4 alignment on the
destination address, but avoids the problem of temporary using a
subroutine level and can access the full 4K page.

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; gosubAligned docstart
   :end-before:  ;;; gosubAligned docend

return skipping ahead
---------------------

.. index:: return skipping ahead

These routines allow for returning to (P+2) and (P+3), that is,
skipping one or two instructions ahead in the return location.

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; RTNP2 docstart
   :end-before:  ;;; RTNP2 docend

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; RTNP3 docstart
   :end-before:  ;;; RTNP3 docend

unpack a packed pointer
-----------------------

.. index:: unpack a packed pointer

These routines read a packed pointer by offset displacement from a
given base address and returns the resulting address.

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; unpack docstart
   :end-before:  ;;; unpack docend

Return to mainframe
===================

.. index:: return to mainframe, mainframe; return to

XFNRC
-----

**Entry point:** ``4D30``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; XNFRC docstart
   :end-before:  ;;; XNFRC docend

XFNRPU
------

**Entry point:** ``4D34``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; XNFRPU docstart
   :end-before:  ;;; XNFRPU docend

resetMyBank
-----------

.. index:: bank switching

**Entry point:** ``4F90``

.. literalinclude:: ../src/secondaryFunctions.s
   :language: none
   :start-after: ;;; resetMyBank docstart
   :end-before:  ;;; resetMyBank docend

SKP_resetMyBank
---------------

.. index:: skip line; bank switching, yes/no test; bank switching

**Entry point:** ``4D59``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; SKP_resetMyBank docstart
   :end-before:  ;;; SKP_resetMyBank docend

NOSKP_resetMyBank
-----------------

**Entry point:** ``4D5F``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; NOSKP_resetMyBank docstart
   :end-before:  ;;; NOSKP_resetMyBank docend



General utilities
=================

XBCDBIN
-------

.. index:: floating point to binary, XBCDBIN, BCDBIN

**Entry point:** ``4F94``

.. literalinclude:: ../src/semiMerged.s
   :language: none
   :start-after: ;;; XBCDBIN docstart
   :end-before:  ;;; XBCDBIN docend

CXtoX
-----
.. index:: binary to floating point

**Entry point:** ``4F98``

.. literalinclude:: ../src/conversion.s
   :language: none
   :start-after: ;;; CXtoX docstart
   :end-before:  ;;; CXtoX docend

CtoXRcl
-------

**Entry point:** ``4F9a``

.. literalinclude:: ../src/conversion.s
   :language: none
   :start-after: ;;; CtoXRcl docstart
   :end-before:  ;;; CtoXRcl docend
   :lines: 1-3, 6-

CtoXDrop
--------

**Entry point:** ``4F9c``

.. literalinclude:: ../src/conversion.s
   :language: none
   :start-after: ;;; CtoXRcl docstart
   :end-before:  ;;; CtoXRcl docend
   :lines: 1-2, 4, 6-

CtoXFill
--------

**Entry point:** ``4F9e``

.. literalinclude:: ../src/conversion.s
   :language: none
   :start-after: ;;; CtoXRcl docstart
   :end-before:  ;;; CtoXRcl docend
   :lines: 1-2, 5-

pausingReset
------------

.. index:: reset pause, pause; reset

**Entry point:** ``4F96``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; pausingReset docstart
   :end-before:  ;;; pausingReset docend

getIndexX
---------

.. index:: register range

**Entry point:** ``4FA4``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; getIndexX docstart
   :end-before:  ;;; getIndexX docend

.. _error-exit-from-banks:

Error handling
==============

.. index:: error handling

These error routines are the same as found in the Extended Functions
module and later 41CX. They are provided in OS4 as they do not exist
in 41C and 41CV. Thus, if you rely on OS4 they are now available on
all HP-41 variants.

displayError
------------

**Entry point:** ``4F82``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; displayError docstart
   :end-before:  ;;; displayError docend

errorMessage
------------

**Entry point:** ``4F2A``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; errorMessage docstart
   :end-before:  ;;; errorMessage docend

errorExit
---------

**Entry point:** ``4F2C``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; errorExit docstart
   :end-before:  ;;; errorExit docend

noRoom
------

**Entry point:** ``4F28``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; noRoom docstart
   :end-before:  ;;; noRoom docend

noSysBuf
--------

**Entry point:** ``4F4A``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; noSysBuf docstart
   :end-before:  ;;; noSysBuf docend

ERRDE_resetMyBank
-----------------

**Entry point:** ``4D38``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; ERRDE_resetMyBank docstart
   :end-before:  ;;; ERRDE_resetMyBank docend

ERRNE_resetMyBank
-----------------

**Entry point:** ``4D3D``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; ERRNE_resetMyBank docstart
   :end-before:  ;;; ERRNE_resetMyBank docend

ERRAD_resetMyBank
-----------------

**Entry point:** ``4D42``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; ERRAD_resetMyBank docstart
   :end-before:  ;;; ERRAD_resetMyBank docend

ERROF_resetMyBank
-----------------

**Entry point:** ``4D47``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; ERROF_resetMyBank docstart
   :end-before:  ;;; ERROF_resetMyBank docend

errorExit_resetMyBank
---------------------

**Entry point:** ``4D4C``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; errorExit_resetMyBank docstart
   :end-before:  ;;; errorExit_resetMyBank docend

CHK_NO_S_resetMyBank
--------------------

**Entry point:** ``4D51``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; CHK_NO_S_resetMyBank docstart
   :end-before:  ;;; CHK_NO_S_resetMyBank docend


Ensure environment
==================

Some code may require certain optional hardware to be available for
correct operation. These routines allow for testing such requirements and
give a sensible error if the resource is not present.

ensureDrive
-----------

.. index:: HP-IL mass storage; testing for

Check for the mass storage HP-IL drive. This tests both that we have
an HP-IL module as well as some mass storage device connected to the
HP-IL loop.

**Entry point:** ``4F68``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; ensureDrive docstart
   :end-before:  ;;; ensureDrive docend

ensureHPIL
----------

.. index:: HP-IL; testing for

**Entry point:** ``4F44``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; ensureHPIL docstart
   :end-before:  ;;; ensureHPIL docend

ensure41CX
----------

.. index:: 41CX; testing for

Testing for 41CX is intended to ensure that the entry points for
accessing extended memory is available.

**Entry point:** ``4F46``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; ensure41CX docstart
   :end-before:  ;;; ensure41CX docend

ensureTimer
-----------

.. index:: timer; testing for

The timeout related routines will politely tell you if there is no
timer available. This routine is intended if you want to really bail
out and prevent further actions when the timer is missing.

**Entry point:** ``4F82``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; ensureTimer docstart
   :end-before:  ;;; ensureTimer docend

Data entry
==========

**Entry point:** ``4F2E``

.. literalinclude:: ../src/keyboard.s
   :language: none
   :start-after: ;;; clearSystemDataEntry docstart
   :end-before:  ;;; clearSystemDataEntry docend

.. index:: data entry

**Entry point:** ``4F22``

.. literalinclude:: ../src/core.s
   :language: none
   :start-after: ;;; fastDataEntry docstart
   :end-before:  ;;; fastDataEntry docend


Assignments
===========

.. index:: assignments

Functions related to assignments are mainly for handling assignments
of secondary functions which reside in the system buffer.

assignSecondary
---------------

.. index:: assignments; secondary

**Entry point:** ``4F54``

.. literalinclude:: ../src/assignment.s
   :language: none
   :start-after: ;;; assignSecondary docstart
   :end-before:  ;;; assignSecondary docend
   :lines: 1-3, 6-

.. note::
   If there is insufficient free space this function will cause a "NO
   ROOM" error exit. In this case any previous assignment made to the
   key is lost.

clearAssignment
---------------

**Entry point:** ``4F52``

This routine will remove an assignment to a given key code no matter
if it is a primary or secondary assignment (or both).

.. literalinclude:: ../src/assignment.s
   :language: none
   :start-after: ;;; clearAssignment docstart
   :end-before:  ;;; clearAssignment docend
   :lines: 1-4, 9-

clearSecondaryAssignments
-------------------------

**Entry point:** ``4F5E``

.. literalinclude:: ../src/assignment.s
   :language: none
   :start-after: ;;; clearSecondaryAssignments docstart
   :end-before:  ;;; clearSecondaryAssignments docend
   :lines: 1-4, 6-

findSecondaryAssignments
------------------------

**Entry point:** ``4F0C``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; findSecondaryAssignments docstart
   :end-before:  ;;; findSecondaryAssignments docend

.. index: assignment; remapping, remapping assignments

mapAssignments
--------------

This routine is called ``RSTKCA`` by HP. The variant presented here is
based on the one found in the Extended Functions module, enhanced with
the ability to choose either assignments from global program label
assignments or the key assignment registers when both are active. This
is mentioned in the comments in the Extended Functions module, but
that logic is actually not present in the code. The original comes
from the Card Reader which has this ability. Apparently, the code was
slightly stripped when moved but the comment was left as-is.

Here it is presented in all its glory with the addition that it is now
also handles secondary assignments and will rebuild those key
assignments map too. If a secondary assignment happens to be shadowed
by a primary assignment, as can be the result when loading primary
assignments using functions that are unaware of secondary assignments,
the secondary assignment is cleared.

**Entry point:** ``4FA0``

.. literalinclude:: ../src/assignment.s
   :language: none
   :start-after: ;;; mapAssignments docstart
   :end-before:  ;;; mapAssignments docend

Buffers
=======

.. index:: buffers

Buffer routines cover both ordinary I/O buffers, as well as hosted
buffers which are stored inside the system buffer.

findBuffer
----------

**Entry point:** ``4F06``

This routine is used to locate a buffer.

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; findBuffer docstart
   :end-before:  ;;; findBuffer docend
   :lines: 1-2, 4-

.. note::
   It is assumed that the buffer number has been loaded with the
   ``LDI`` instruction, which causes the upper two nibbles (``C[2:1]``
   of the ``C.X`` field) to be zero.

ensureBuffer
------------

**Entry point:** ``4F08``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; ensureBuffer docstart
   :end-before:  ;;; ensureBuffer docend
   :lines: 1-3, 5-

ensureBufferWithTrailer
------------------------

**Entry point:** ``4FA2``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; ensureBufferWithTrailer docstart
   :end-before:  ;;; ensureBufferWithTrailer docend

reclaimSystemBuffer
-------------------

**Entry point:** ``4F30``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; reclaimSystemBuffer docstart
   :end-before:  ;;; reclaimSystemBuffer docend

growBuffer
----------

**Entry point:** ``4F0A``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; growBuffer docstart
   :end-before:  ;;; growBuffer docend

shrinkBuffer
------------

**Entry point:** ``4F38``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; shrinkBuffer docstart
   :end-before:  ;;; shrinkBuffer docend

allocScratch
------------

.. index:: scratch area

**Entry point:** ``4F3A``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; allocScratch docstart
   :end-before:  ;;; allocScratch docend

scratchArea
-----------

**Entry point:** ``4F3E``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; scratchArea docstart
   :end-before:  ;;; scratchArea docend

clearScratch
------------

**Entry point:** ``4F3C``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; clearScratch docstart
   :end-before:  ;;; clearScratch docend

newHostedBuffer
---------------

.. index:: buffers; hosted, hosted buffers

**Entry point:** ``4F6E``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; newHostedBuffer docstart
   :end-before:  ;;; newHostedBuffer docend

findBufferHosted
----------------

**Entry point:** ``4F6A``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; findBufferHosted docstart
   :end-before:  ;;; findBufferHosted docend

reclaimHostedBuffer
-------------------

**Entry point:** ``4F6C``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; reclaimHostedBuffer docstart
   :end-before:  ;;; reclaimHostedBuffer docend

packHostedBuffers
-----------------

**Entry point:** ``4F74``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; packHostedBuffers docstart
   :end-before:  ;;; packHostedBuffers docend

growHostedBuffer
----------------

**Entry point:** ``4F70``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; growHostedBuffer docstart
   :end-before:  ;;; growHostedBuffer docend

shrinkHostedBuffer
------------------

**Entry point:** ``4F72``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; shrinkHostedBuffer docstart
   :end-before:  ;;; shrinkHostedBuffer docend

Shells
======

.. index:: shells

activateShell
-------------

.. index:: shells; activation, activation; of shells

**Entry point:** ``4F00``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; activateShell docstart
   :end-before:  ;;; activateShell docend

exitShell
---------

.. index:: shells; exiting

**Entry point:** ``4F02``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; exitShell docstart
   :end-before:  ;;; exitShell docend
   :lines: 1-3, 5-10, 13-

reclaimShell
------------

.. index:: shells; reclaim, reclaim; shells

**Entry point:** ``4F04``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; exitShell docstart
   :end-before:  ;;; exitShell docend
   :lines: 1-2, 4-5, 12-

exitTransientApp
----------------

.. index:: shells; transient application, transient applications

**Entry point:** ``4F40``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; exitTransientApp docstart
   :end-before:  ;;; exitTransientApp docend

exitApp
-------

.. index:: shells; exiting

**Entry point:** ``4F78``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; exitApp docstart
   :end-before:  ;;; exitApp docend

hasActiveTransientApp
---------------------

**Entry point:** ``4F42``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; hasActiveTransientApp docstart
   :end-before:  ;;; hasActiveTransientApp docend

activeApp
---------

**Entry point:** ``4F36``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; activeApp docstart
   :end-before:  ;;; activeApp docend

topShell
--------

**Entry point:** ``4F14``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; topShell docstart
   :end-before:  ;;; topShell docend

nextShell
---------

**Entry point:** ``4F18``

This routine can be used to find the next successive shell after
starting with a call to ``topShell``. You must preserve the ``M``
register while making successive calls.

topExtension
------------

**Entry point:** ``4F16``

This is similar to ``topShell`` but searches for extension points in
the shell stack.

shellDisplay
------------

.. index:: shells; default display, display; default

**Entry point:** ``4F10``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; shellDisplay docstart
   :end-before:  ;;; shellDisplay docend

displayDone
-----------

.. index:: shells; default display, display; default

**Entry point:** ``4F32``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; displayDone docstart
   :end-before:  ;;; displayDone docend

displayingMessage
-----------------

.. index:: message flag

**Entry point:** ``4F56``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; displayingMessage docstart
   :end-before:  ;;; displayingMessage docend

sendMessage
-----------

.. index:: extension handlers

**Entry point:** ``4F34``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; sendMessage docstart
   :end-before:  ;;; sendMessage docend

shellName
---------

**Entry point:** ``4F1A``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; shellName docstart
   :end-before:  ;;; shellName docend

shellKeyboard
-------------

**Entry point:** ``4F4C``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; shellKeyboard docstart
   :end-before:  ;;; shellKeyboard docend

Semi-merged
===========

.. index:: functions; semi-merged, semi-merged functions

These functions define semi-merged prompting functions.

.. note::
   A call to these routines are expected to appear first in a
   function. The OS4 code inspects the start of potential such
   functions and expects it to look in a particular way.

argument
--------

**Entry point:** ``4F1E``

.. literalinclude:: ../src/semiMerged.s
   :language: none
   :start-after: ;;; argument docstart
   :end-before:  ;;; argument docend

dualArgument
------------

**Entry point:** ``4F76``

.. literalinclude:: ../src/semiMerged.s
   :language: none
   :start-after: ;;; dualArgument docstart
   :end-before:  ;;; dualArgument docend

.. _postfix4095:

postfix4095
-----------

**Entry point:** ``4F92``

.. literalinclude:: ../src/semiMerged.s
   :language: none
   :start-after: ;;; postfix4095 docstart
   :end-before:  ;;; postfix4095 docend

Partial key sequences
=====================

.. index:: partial key sequences

XABTSEQ
-------

**Entry point:** ``4F5C``

.. literalinclude:: ../src/partial.s
   :language: none
   :start-after: ;;; XABTSEQ docstart
   :end-before:  ;;; XABTSEQ docend

Secondary functions
===================

.. index:: secondary functions, functions; secondary

XASRCH
------

This is a variant of the ``ASRCH`` routine in mainframe. This routine
works the same but will also locate secondary functions.

**Entry point:** ``4F4E``

.. literalinclude:: ../src/secondaryFunctions.s
   :language: none
   :start-after: ;;; XASRCH docstart
   :end-before:  ;;; XASRCH docend

resetBank
---------

.. index:: bank switching

**Entry point:** ``4F58``

.. literalinclude:: ../src/secondaryFunctions.s
   :language: none
   :start-after: ;;; resetBank docstart
   :end-before:  ;;; resetBank docend
   :lines: 1-3, 5-

secondaryAddress
----------------

.. index:: functions, secondary, secondary functions

**Entry point:** ``4F50``

.. literalinclude:: ../src/secondaryFunctions.s
   :language: none
   :start-after: ;;; secondaryAddress docstart
   :end-before:  ;;; secondaryAddress docend
   :lines: 1-3, 6-

runSecondary
------------

**Entry point:** ``4F60``

.. literalinclude:: ../src/secondaryFunctions.s
   :language: none
   :start-after: ;;; runSecondary docstart
   :end-before:  ;;; runSecondary docend

invokeSecondary
---------------

**Entry point:** ``4F5A``

.. literalinclude:: ../src/keyboard.s
   :language: none
   :start-after: ;;; invokeSecondary docstart
   :end-before:  ;;; invokeSecondary docend

Keyboard
========

.. index:: keyboard

keyKeyboard
-----------

**Entry point:** ``4F5A``

.. literalinclude:: ../src/keyboard.s
   :language: none
   :start-after: ;;; keyKeyboard docstart
   :end-before:  ;;; keyKeyboard docend

keyDispatch
-----------

**Entry point:** ``4F66``

.. literalinclude:: ../src/keyboard.s
   :language: none
   :start-after: ;;; keyDispatch docstart
   :end-before:  ;;; keyDispatch docend

assignKeycode
-------------

**Entry point:** ``4F8E``

.. literalinclude:: ../src/assignment.s
   :language: none
   :start-after: ;;; assignKeycode docstart
   :end-before:  ;;; assignKeycode docend
   :lines: 1-4, 6-

Timer
=====

OS4 allows for using the interval timer which can be useful for
timeouts or periodic updates of the display.

Only the active application will receive timeout events. The timeout
handler is in the shell descriptor (at offset 6).

setTimeout
----------

.. index:: timer

**Entry point:** ``4F62``

.. literalinclude:: ../src/timer.s
   :language: none
   :start-after: ;;; setTimeout docstart
   :end-before:  ;;; setTimeout docend

clearTimeout
------------

**Entry point:** ``4F64``

.. literalinclude:: ../src/timer.s
   :language: none
   :start-after: ;;; clearTimeout docstart
   :end-before:  ;;; clearTimeout docend

Catalog
========

.. index:: catalogs

The catalog functionality provides a framework that factors out most
of the structure around running a catalog.

catalog
-------

**Entry point:** ``4F7C`` ``catalog``

**Entry point:**  ``4F7E`` ``catalogWithSize``

.. literalinclude:: ../src/catalog.s
   :language: none
   :start-after: ;;; catalog docstart
   :end-before:  ;;; catalog docend

catalogEnd
----------

**Entry point:** ``4F88``

.. literalinclude:: ../src/catalog.s
   :language: none
   :start-after: ;;; catalogEnd docstart
   :end-before:  ;;; catalogEnd docend

catalogReturn
-------------

**Entry point:** ``4F8C``

.. literalinclude:: ../src/catalog.s
   :language: none
   :start-after: ;;; catalogReturn docstart
   :end-before:  ;;; catalogReturn docend

catalogStep
-----------

**Entry point:** ``4F84``

.. literalinclude:: ../src/catalog.s
   :language: none
   :start-after: ;;; catalogStep docstart
   :end-before:  ;;; catalogStep docend

catalogBack
-----------

**Entry point:** ``4F86``

.. literalinclude:: ../src/catalog.s
   :language: none
   :start-after: ;;; catalogBack docstart
   :end-before:  ;;; catalogBack docend

catalogRun
----------

**Entry point:** ``4F8A``

.. literalinclude:: ../src/catalog.s
   :language: none
   :start-after: ;;; catalogRun docstart
   :end-before:  ;;; catalogRun docend


Extended memory
===============

.. index:: extended memory, memory; extended

getXAdr
-------

If your function takes a postfix argument you will probably want to
use ``postfix4095`` together with ``getXAdr``, see :ref:`postfix4095`.

**Entry point:** ``4F12``

.. literalinclude:: ../src/xmem.s
   :language: none
   :start-after: ;;; getXAdr docstart
   :end-before:  ;;; getXAdr docend
