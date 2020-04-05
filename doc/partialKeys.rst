Partial key sequences
=====================

Some functions on on the HP-41 prompt for arguments. Internally these
are called partial key sequences. The OS4 module provides various
support for prompting functions built on top of this mechanism.

Between key presses to fill out the prompt the calculator goes to
sleep to redude power consumption.


State
-----

Two bytes called ``ptemp1`` and ``ptemp2`` are used to keep track of
the state during partial key sequences. While the partial key sequence
is active, these are kept in either the ``ST`` (flag) and ``G``
registers.

When not processing key presses, `ptemp2` is kept in a status register
and `ptemp1` is built each time as it contains information about what
kind of key was just pressed.
The code that will handle the next key press is kept on the top of the
processor stack. Combined, these can be seen as a continuation, the
information needed to process the next key is saved in a concise way.

Display prompt
--------------

Functions that prompt for input have bits set in their function name
header. This indicates to the code that is decoding which function to
run that the function needs to prompt for an argument before it can
actually run. At this point, the instruction code is saved in a status
register and the upper bits are stored in the ``ptemp1`` and
``ptemp2`` state bytes. The value of these bits informs what class of
prompting function this is. Among other things it controls the number
of initial underscores.

At this point the function name is written to the LCD followed by a
blank. The prompt underscores are added using a call to a ``NEXT``
routine where the numeric suffix tells now many underscores to add, i.e.
``NEXT2`` adds two underscores. The ``NEXT`` routine will not return
until a key is pressed again and in the mean time the calculator goes
to standby. Thus the return address to the caller of ``NEXT`` is kept
on the processor stack until there is a key press to act upon.

Before you get control back, all underscores are removed from the
display and return will be to the address following the call if
back-arrow key was pressed, otherwise it will be the return address
plus one. This makes it easy to decode back-arrow key and ``ptemp1``
is loaded in the ``ST`` flag register, making it easy to dispatch on
different classes of keys.

If you accept the input you append what was keyed to the LCD, which
can be one or more characters in case one of the top keys that often
act as ``01``-``10`` is pressed. If further input is needed you call
the appropriate ``NEXT`` routine to output the number of underscores
desired.

Rolling your own
----------------

For certain functions it is desirable to use the prompt mechanism, but
this poses several problems as using prompting XROM functions requires
some care. The operating system is quite permissive in allowing
prompting XROMs, but there are several limitations on what actually
works. 

Known bugs and limitations
^^^^^^^^^^^^^^^^^^^^^^^^^^

There are two main classes of prompting functions, those that take
alpha arguments and those that take numeric arguments. HP utilized
alpha input for XROM functions, but they are not programmable. Numeric
input with XROMs was not used by HP, but it is  also
allowed. Unfortunately, there are some bugs in the code related to
this. These will be discussed further down.


``PRP`` (print program) in the printer is an example of an XROM that
prompts for alpha input. As such function cannot be represented in a
program it is non-programmable.

.. note::
   Later this way of doing alpha input to XROM functions used the
   alpha register. This was used for file names in the HP-IL mass
   storage and Extended Functions/Memory modules. As they take input
   from the alpha register they are programmable. They are also more
   flexible as they allowed for dual input, i.e. specifying a program
   but storing it in a file under a different name. 

XROM functions prompting works up to a point. There is no built-in
support for representing them in a program so they need to be
non-programmable. Later we will look at semi-merged functions which is
provided by OS4 and it is a way to work around this limitation.
There are some bugs and unexpected behavior related to numeric
prompting XROM functions:

# If the function is allowed to prompt for a stack register, the
  function being built gets corrupted.

# The printer will also get confused and print the wrong instruction
  postfix.


Custom prompting
----------------

Custom prompting can be used if you want full control of the prompt
behavior. This only works for non-programmable functions. Typical use
is functions such as ``XEQ` and ``ASN``, which could have replacements
that provide richer functionality.

Marking the name header of a function makes it possible to choose
among the built-in standard prompt behavior. If you want to design the
prompt behavior on your own you need to override it. OS4 makes this
possible using a special marker that needs to appear as the first
instruction in the function (after any leading ``NOP`` instructions
that mark it as non-programmable and possibly also XKD.


.. code-block:: ca65

                 .con    '\'' + 0x80   ; '
                 .con    0x0e          ; N
                 .con    0x100 + 19    ; S
                 .con    0x101         ; A
   myASN:        nop                   ; non-programmable
                 gosub   partialKey    ; marker partial key takeover
                 goto    assign        ; when executed, argument is done and we will
                                       ;   perform the actual assignment
                 goto    abortASN      ; <-
                 ...                   ; normal processing

   assign:                             ; actual run behavior after prompt done

   abortASN:     golong XABTSEQ

The ``partialKey`` marks the function as a partial key sequence
takeover function. The initial number of underscores in the initial
prompt is dictated by the bits in the name header. An ordinary partial
key sequence function is started and the return address for the next
key processing is initially set to inside mainframe (which depends on
the prompt bits in the name header, as usual). OS4 detects that there
is a call to ``partialKey`` as first real instruction and alters the
return address to be the return address of this call, plus one.

When the first key is pressed in response to the prompt it is handled
by the code following the call to ``partialKey``. The normal
back-arrow handler is firstm, then processing for other keys, which is
how the ``NEXT`` routines work in mainframe.

Thus, the purpose of the name field bits is only to put up the initial
prompt. The main purpose of the marker is to tell OS4 that the
function wants to do its own processing, so it alters the return
address kept on the stack for the next key processing to point to your
key handler code.

When the prompt has been fully filled in you will normally exit by
jumping to one of the null test entry points, i.e. ``NULT_``,
``NULT_3`` or ``NULT_4`` to do null testing and if key is released
execute the function.

Execution is done the normal way by actually running the function. As
the first instruction is a call to ``partialKey``, it will get
executed. So far it only acted as a marker for redirecting
(overriding) the prompt handler. Executing it will cause it to return
the next line (the one before the initial prompt handler entry points
that we skipped over before) it should be a short jump to the actual
code that performs the function.

Then what about the collected prompt data? Normally alpha input is in
the Q register and a numeric operand is in ``A.X``. If you want
something else you need to store it somewhere before you called the
null test handler code. As the Q registers is available for prompt
arguments, it can be a good place.

.. note::
   Make a jump to ``XABTSEQ`` To abort partial key processing. This
   works almost identical to ``ABTSEQ`` in mainframe that has the same
   purpose, but ``XABTSEQ`` performs some additional clean-ups for the
   purpose of OS4.

.. note::
   Using a system shell makes it possible to have such special
   functionality bound to a key. The boost module uses this to provide
   replacements for ``XEQ`` and ``ASN``, but you are not limited to
   improving existing functionality, you can provide something
   completely new.

Design considerations
^^^^^^^^^^^^^^^^^^^^^

Some extension modules (like CCD) provide prompt underscores up front
for several fields. This may be seen as user friendly, but existing
base functionality like ``ASN`` do not present up front that it will
prompt for a key once you entered the function name. In addition, the
key prompt is a single underscore, even though the actual key pressed
will be presented as a two digit number.

Thus, you are rather free to do whatever you want and it is nothing
wrong to take a field at a time and just prompt for the next thing,
even if you know that you eventually will prompt for additional things
following a known pattern. On the other hand, making it more elaborate
may make it easier for the user to understand it. There is really no
right or wrong.

OS4 support
^^^^^^^^^^^

Some prompt support functionality is provided by OS4. The ``parseNumber``
routine can be used for requesting decimal numbers. This can prompt
for a given number of digits and has an accept predicate, making it
possible to check the input to be in a specific range, i.e. 0-511 or
1-31. Impossible input is detected early which causes a blink.

.. code-block:: ca65

                 gosub   parseNumber
                 .con    .low12 accept_1_31
                 .con    2             ; request 2 digits

To allow the ``EEX`` key to be used to extend the range you need to
include its mask value:

.. code-block:: ca65

                 gosub   parseNumber
                 .con    .low12 accept_1_31
                 .con    2 | ParseNumber_AllowEEX ; request 2 digits, allow EEX
