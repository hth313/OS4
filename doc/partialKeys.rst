*********************
Partial key sequences
*********************

.. index:: partial key sequences

Some functions prompt for arguments. Internally these are called
partial key sequences. The OS4 module provides various support for
prompting functions built on top of this mechanism.

One of several nice features of the prompting system on the HP-41 is
that the calculator goes to sleep between key presses to reduce power
consumption.


State
======

Two bytes called ``ptemp1`` and ``ptemp2`` are used to keep track of
the state during partial key sequences. While the partial key sequence
is active they are kept in either the ``ST`` (flag) and ``G``
registers.

When not processing key presses, ``ptemp2`` is preserved in a status
register (in chip 0) and ``ptemp1`` is rebuilt each time as it
contains information about what kind of key was just pressed.
The address of the code that will handle the next key press is kept on
the top of the processor stack. Together these are the context
needed to process the next key.

Display prompt
==============

Functions that prompt for input have bits set in the function name
header to indicate that it is a prompting function.
This also tells that the function needs to prompt for an argument before it can
actually run. At this point, the function code is saved in a status
register and the upper bits are stored in the ``ptemp2`` state
byte. The value of these bits informs what class of prompting function
it belongs to. Among other things it controls the number of initial
underscores.

The function name is written to the LCD followed by a
blank and prompt underscores are added by a call to a ``NEXT``
routine where its numeric suffix tells now many underscores to add, e.g.
``NEXT2`` adds two underscores. The ``NEXT`` routine will not return
until a key is pressed and the calculator goes to light sleep.
A partial key sequence flag is also set to indicate that the
calculator is processing a prompt. The return address to the caller of
``NEXT`` is kept on the processor stack while the calculator is in
light sleep waiting for the next key press.

Before giving control back, all underscores are removed from the
display. Then it returns to the address following the call to ``NEXT``
if back-arrow key was pressed, or to the following address if some
other key was pressed. This makes it easy to decode back-arrow key and
``ptemp1`` is set up in the ``ST`` flag register, making it easy to
dispatch on different classes of keys.

If you accept the input you append what was keyed to the LCD, which
can be one or more characters, e.g. the top rows keys often
act as ``01``--``10`` when pressed. If further input is needed you call
the appropriate ``NEXT`` routine to output the number of underscores
desired.

Rolling your own
================

For certain functions it is desirable to use the prompt mechanism, but
there are several problems with prompting XROM functions which requires
some care. The operating system is quite permissive in allowing
prompting XROMs, but there are limitations on what actually works in
practice.

Known bugs and limitations
--------------------------

There are two main classes of prompting functions, those that take
alpha arguments and those that take numeric arguments. HP utilized
alpha input for XROM functions but they are not programmable. Numeric
input with XROMs was not used by HP, but is also possible.
Unfortunately, there are some bugs in the code related to
this, which will be discussed below.


``PRP`` (print program) in the printer is an example of an XROM that
prompts for alpha input. As such function cannot be represented in a
program it is non-programmable.

.. note::
   Later this way of doing alpha input to XROM functions used the
   alpha register. This was used for file names in the HP-IL mass
   storage and Extended Functions/Memory modules. As they take input
   from the alpha register they can be made programmable. They are also more
   flexible as they allowed for dual input, e.g. specifying a program
   but storing it in a file under a different name.

Prompting XROM functions work up to a point. There is no built-in
support for representing them in a program so they need to be
non-programmable. In the previous chapter we looked at semi-merged
functions which is provided by OS4 and it is a way to work around this
limitation.
There are also some bugs and unexpected behavior related to numeric
prompting XROM functions:

#. If the function is allowed to prompt for a stack register, the
   XROM function being built becomes corrupted.

#. The printer will get confused and print the wrong function
   postfix.

.. note::

   The semi-merged postfix mechanism contains code that works around
   the problem with entering stack registers corrupting the instruction.

Custom prompting
================

.. index:: custom prompting

Custom prompting can be used if you want full control of the prompting
behavior. This only works for non-programmable functions. Typical use
are functions such as ``XEQ`` and ``ASN``, where replacements can
provide additional capabilities using custom prompting.

Marking the name header of a function makes it possible to choose
among the built-in standard prompt behaviors. If you want to design the
prompt behavior on your own you need to override it. OS4 makes this
possible using a special marker that needs to appear as the first
instruction in the function (after any leading ``NOP`` instructions
that mark it as non-programmable and possibly also XKD).


.. code-block:: ca65

                 .con    '\'' + 0x80   ; '
                 .con    0x0e          ; N
                 .con    0x100 + 19    ; S
                 .con    0x101         ; A
   myASN:        nop                   ; non-programmable
                 gosub   partialKey    ; marker partial key takeover
                 goto    assign        ; actual execution of ASN
                 goto    abortASN      ; <-
                 ...                   ; normal argument processing

   assign:                             ; actual run behavior after prompt done

   abortASN:     golong XABTSEQ

The call to ``partialKey`` marks the function as a partial key sequence
takeover function. The number of underscores in the initial
prompt is determined by the bits in the name header. An ordinary partial
key sequence function is started and the return address for the next
key processing is initially set to inside mainframe (which depends on
the prompt bits in the name header). OS4 detects that there
is a call to ``partialKey`` as first real instruction in the function
that is prompting and alters the return address that points somewhere
in mainframe so that it instead is the return address of the call to
``partialKey``, plus one.

When the first key is pressed in response to the prompt, it is handled
by the code following the call to ``partialKey`` plus one. The normal
back-arrow handler is first, then processing for other keys, which is
how the ``NEXT`` routines work in mainframe.

The purpose of the name field bits is only to put up the initial
prompt. The purpose of the ``GOSUB partialKey`` marker is to tell OS4
that the function wants to do its own processing.
OS4 alters the return address kept on the stack for the next key
processing to point to your own key handler code.

When the prompt has been fully filled in you should jump to one of the
null test entry points, e.g. ``NULT_``, ``NULT_3`` or ``NULT_4`` to do
null testing and if key is released in time execute the function.

Execution is done the normal way by actually running the function. As
the first instruction is a call to ``partialKey`` it will get
executed. Previously it has only acted as a marker for redirecting
(overriding) the prompt handler. Executing it will do nothing as it
immediately returns to the next line (the one the prompt handler
skipped over before). It should be a short jump to the actual
code that performs the function.

What about the collected prompt input data? Normally, alpha input is in
the Q register and a numeric operand is in ``A.X``. If you want
something else you need to store it somewhere before you call the
null test handler code. As the Q registers is available for prompt
arguments, it can be a good choice.

.. note::
   Make a jump to ``XABTSEQ`` to abort partial key processing. This
   works almost identical to ``ABTSEQ`` in mainframe which has the same
   purpose, except that ``XABTSEQ`` performs some additional clean-ups
   for the purpose of OS4.

.. note::
   The Boost module uses this to provide replacements for ``XEQ`` and
   ``ASN``. However, you are not limited to improving existing
   functionality, you can provide something completely new.

Design considerations
---------------------

Some extension modules (like CCD) show prompt underscores immediately
for more than one field, e.g. the two arguments of an ``XROM``.
This may be seen as user friendly, but existing base functionality
like ``ASN`` do not present up front that it will also prompt for a
key once you entered the function name. In addition, the
key prompt is a single underscore, even though the actual key pressed
will be presented as a two digit number.

Thus, you are rather free to do whatever you want and there is nothing
unusual with taking a field at a time and gradually prompt for the next thing,
even if you know that you eventually will prompt for additional things
following a known pattern. On the other hand, making it more elaborate
may make it easier for the user to understand it. The take-away is
that both ways have been in used for long and are accepted, there is
nothing right or wrong.

Limitations
-----------

If you decide to use the prompt mechanism offered by mainframe with
your XROM function it is possible to do so, but normal limitations
apply. The bug with stack operands exists (unless you use a corrected
mainframe ROM). The function must be non-programmable and your function
cannot be a secondary functions. The ``CAT'`` catalog replacement
function in the Boost module is currently implemented in this way.

If you take over prompt handling but in the end make use of existing
functionality in mainframe it will not work properly with secondary
functions. One example of this is the ``ASN'`` assign replacement
function in the Boost module. It uses the mainframe code to ask for
the key code as its final step. After this it tries to execute the
function from mainframe and it cannot execute secondary
functions. This forces it to be an ordinary XROM function.


Support functions
-----------------

Some prompt support functionality can be found in the Boost
module. The ``parseNumber`` routine can be used for requesting decimal
numbers. This can prompt for a given number of digits and has an
accept predicate, making it possible to check the input to be in a
specific range, e.g. 0--511 or 1--31. Impossible input is detected as
soon as possible, resulting in refused input and a display blink.

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
