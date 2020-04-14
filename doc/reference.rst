**********************
Entry points reference
**********************


Assignments
===========

Functions related to assignments are mainly for handling assignments
of secondary functions which reside in the system buffer.

**assignSecondary**
-------------------

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

**clearAssignment**
-------------------

**Entry point:** ``4F52``

This routine will remove an assignment to a given key-code no matter
if it is a primary or secondary assignment (or both).

.. literalinclude:: ../src/assignment.s
   :language: none
   :start-after: ;;; clearAssignment docstart
   :end-before:  ;;; clearAssignment docend
   :lines: 1-4, 9-

**clearSecondaryAssignments**
-----------------------------

**Entry point:** ``4F5E``

.. literalinclude:: ../src/assignment.s
   :language: none
   :start-after: ;;; clearSecondaryAssignments docstart
   :end-before:  ;;; clearSecondaryAssignments docend
   :lines: 1-4, 6-

**findSecondaryAssignments**
------------

**Entry point:** ``4F0C``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; findSecondaryAssignments docstart
   :end-before:  ;;; findSecondaryAssignments docend


Buffers
=======

Buffer routines cover both ordinary I/O buffers, as well as hosted
buffers which are stored inside the system buffer.

**findBuffer**
--------------

**Entry point:** ``4F06``

This routine has two entry points, one to find the system buffer and
one that takes the buffer number (0--15) from ``C.X``.

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; findBuffer docstart
   :end-before:  ;;; findBuffer docend
   :lines: 1-2, 4-

.. note::
   It is assumed that the buffer number has been loaded with the
   ``LDI`` instruction, which causes the upper two nibbles (``C[2:1]``
   of the ``C.X`` field) to be zero.

**ensureBuffer**
----------------

**Entry point:** ``4F08``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; ensureBuffer docstart
   :end-before:  ;;; ensureBuffer docend
   :lines: 1-3, 5-

**reclaimSystemBuffer**
-----------------------

**Entry point:** ``4F30``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; reclaimSystemBuffer docstart
   :end-before:  ;;; reclaimSystemBuffer docend

**growBuffer**
--------------

**Entry point:** ``4F0A``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; growBuffer docstart
   :end-before:  ;;; growBuffer docend

**shrinkBuffer**
----------------

**Entry point:** ``4F38``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; shrinkBuffer docstart
   :end-before:  ;;; shrinkBuffer docend

**allocScratch**
----------------

**Entry point:** ``4F3A``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; allocScratch docstart
   :end-before:  ;;; allocScratch docend

**scratchArea**
---------------

**Entry point:** ``4F3E``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; scratchArea docstart
   :end-before:  ;;; scratchArea docend

**clearScratch**
----------------

**Entry point:** ``4F3C``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; clearScratch docstart
   :end-before:  ;;; clearScratch docend

**newHostedBuffer**
-------------------

**Entry point:** ``4F6E``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; newHostedBuffer docstart
   :end-before:  ;;; newHostedBuffer docend

**findBufferHosted**
---------------------

**Entry point:** ``4F6A``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; findBufferHosted docstart
   :end-before:  ;;; findBufferHosted docend

**reclaimHostedBuffer**
-----------------------

**Entry point:** ``4F6C``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; reclaimHostedBuffer docstart
   :end-before:  ;;; reclaimHostedBuffer docend

**packHostedBuffers**
----------------------

**Entry point:** ``4F74``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; packHostedBuffers docstart
   :end-before:  ;;; packHostedBuffers docend

**growHostedBuffer**
--------------------

**Entry point:** ``4F70``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; growHostedBuffer docstart
   :end-before:  ;;; growHostedBuffer docend

**shrinkHostedBuffer**
-----------------------

**Entry point:** ``4F72``

.. literalinclude:: ../src/buffer.s
   :language: none
   :start-after: ;;; shrinkHostedBuffer docstart
   :end-before:  ;;; shrinkHostedBuffer docend

Shells
======

**activateShell**
-----------------

**Entry point:** ``4F00``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; activateShell docstart
   :end-before:  ;;; activateShell docend

**exitShell**
-------------

**Entry point:** ``4F02``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; exitShell docstart
   :end-before:  ;;; exitShell docend
   :lines: 1-3, 5-10, 13-

**reclaimShell**
----------------

**Entry point:** ``4F04``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; exitShell docstart
   :end-before:  ;;; exitShell docend
   :lines: 1-2, 4-5, 12-

**exitTransientApp**
--------------------

**Entry point:** ``4F40``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; exitTransientApp docstart
   :end-before:  ;;; exitTransientApp docend

**exitApp**
-----------

**Entry point:** ``4F78``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; exitApp docstart
   :end-before:  ;;; exitApp docend

**hasActiveTransientApp**
-------------------------

**Entry point:** ``4F42``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; hasActiveTransientApp docstart
   :end-before:  ;;; hasActiveTransientApp docend

**activeApp**
-------------

**Entry point:** ``4F36``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; activeApp docstart
   :end-before:  ;;; activeApp docend

**topShell**
------------

**Entry point:** ``4F14``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; topShell docstart
   :end-before:  ;;; topShell docend

**nextShell**
-------------

**Entry point:** ``4F18``

This routine can be used to find the next successive shell after
starting with a call to ``topShell``. You must preserve the ``M``
register while making successive calls.

**topExtension**
----------------

**Entry point:** ``4F16``

This is similar to ``topShell`` but searches for extension points in
the shell stack instead.

**shellDisplay**
----------------

**Entry point:** ``4F10``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; shellDisplay docstart
   :end-before:  ;;; shellDisplay docend

**displayDone**
----------------

**Entry point:** ``4F32``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; displayDone docstart
   :end-before:  ;;; displayDone docend

**sendMessage**
---------------

**Entry point:** ``4F34``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; sendMessage docstart
   :end-before:  ;;; sendMessage docend

**shellName**
-------------

**Entry point:** ``4F1A``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; shellName docstart
   :end-before:  ;;; shellName docend

**shellKeyboard**
-----------------

**Entry point:** ``4F4C``

.. literalinclude:: ../src/shell.s
   :language: none
   :start-after: ;;; shellKeyboard docstart
   :end-before:  ;;; shellKeyboard docend

Semi-merged
===========

These functions define semi-merged prompting functions.

.. note::
   A call to these routines are expected to appear first in a
   function. The OS4 code will inspect the start of such functions and
   expects it to look this way.

**argument**
------------

**Entry point:** ``4F1E``

.. literalinclude:: ../src/semiMerged.s
   :language: none
   :start-after: ;;; argument docstart
   :end-before:  ;;; argument docend

**dualArgument**
----------------

**Entry point:** ``4F76``

.. literalinclude:: ../src/semiMerged.s
   :language: none
   :start-after: ;;; dualArgument docstart
   :end-before:  ;;; dualArgument docend

Partial key sequences
=====================

**XABTSEQ**
-----------

**Entry point:** ``4F5C``

.. literalinclude:: ../src/partial.s
   :language: none
   :start-after: ;;; XABTSEQ docstart
   :end-before:  ;;; XABTSEQ docend

Secondary functions
===================

**XASRCH**
-----------

This is a variant of the ``ASRCH`` routine in mainframe. This routine
works the same, but will also locate secondary functions.

**Entry point:** ``4F4E``

.. literalinclude:: ../src/secondaryFunctions.s
   :language: none
   :start-after: ;;; XASRCH docstart
   :end-before:  ;;; XASRCH docend

**resetBank**
--------------

**Entry point:** ``4F58``

.. literalinclude:: ../src/secondaryFunctions.s
   :language: none
   :start-after: ;;; resetBank docstart
   :end-before:  ;;; resetBank docend
   :lines: 1-3, 5-

**secondaryAddress**
--------------------

**Entry point:** ``4F50``

.. literalinclude:: ../src/secondaryFunctions.s
   :language: none
   :start-after: ;;; secondaryAddress docstart
   :end-before:  ;;; secondaryAddress docend
   :lines: 1-3, 6-

**runSecondary**
----------------

**Entry point:** ``4F60``

.. literalinclude:: ../src/secondaryFunctions.s
   :language: none
   :start-after: ;;; runSecondary docstart
   :end-before:  ;;; runSecondary docend

**invokeSecondary**
-------------------

**Entry point:** ``4F5A``

.. literalinclude:: ../src/keyboard.s
   :language: none
   :start-after: ;;; invokeSecondary docstart
   :end-before:  ;;; invokeSecondary docend

Keyboard
========

**keyKeyboard**
---------------

**Entry point:** ``4F5A``

.. literalinclude:: ../src/keyboard.s
   :language: none
   :start-after: ;;; keyKeyboard docstart
   :end-before:  ;;; keyKeyboard docend

**keyDispatch**
---------------

**Entry point:** ``4F66``

.. literalinclude:: ../src/keyboard.s
   :language: none
   :start-after: ;;; keyDispatch docstart
   :end-before:  ;;; keyDispatch docend

Timer
=====

OS4 allows for using the interval timer which can be useful for
timeouts or periodic updates of the display.

**setTimeout**
---------------

**Entry point:** ``4F62``

.. literalinclude:: ../src/timer.s
   :language: none
   :start-after: ;;; setTimeout docstart
   :end-before:  ;;; setTimeout docend

**clearTimeout**
----------------

**Entry point:** ``4F64``

.. literalinclude:: ../src/timer.s
   :language: none
   :start-after: ;;; clearTimeout docstart
   :end-before:  ;;; clearTimeout docend

Catalog
========

**catalog**
-----------

**Entry point:** ``4F7C``

.. literalinclude:: ../src/catalog.s
   :language: none
   :start-after: ;;; catalog docstart
   :end-before:  ;;; catalog docend

Extended memory
===============

**getXAdr**
-----------

**Entry point:** ``4F12``

.. literalinclude:: ../src/xmem.s
   :language: none
   :start-after: ;;; getXAdr docstart
   :end-before:  ;;; getXAdr docend
