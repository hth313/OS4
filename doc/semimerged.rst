*********************
Semi-merged functions
*********************

Semi-merged function are prompting XROM functions that take postfix
arguments. This is much like many built-in functions, i.e. ``RCL``.

Instructions such as ``RCL`` is made up of two parts, the instruction
and its postfix argument. On the HP-41 they are displayed in programs
as a fully merged instruction.

The problem with XROM is that they cannot be entered in a program
together with a postfix argument. The semi-merged feature makes this
possible.

Postfix operands
================

As we cannot alter the mainframe, there is no way to store a fully
merged XROm function in a program step. What we can do is storing it
in two parts, first the XROM function and then its argument. As the
argument can be any byte, it is not possible to store it raw by
itself, as it may grab following bytes making the program impossible
to view and edit.

Instead we wrap the postfix byte using a text literal. This means that
there are actually two program steps:

.. code-block:: ca65

   10 ...
   11 SL 36
   12 "$"
   13 ...

Note that the ``SL 36`` instruction is fully shown as a merged
instruction, but it is followed by its wrapped postfix byte (36
corresponds to ASCII $).

This also works when using indirect addressing:

.. code-block:: ca65

   10 ...
   11 SL IND Z
   12 "*"
   13 ...

As the ``SL`` instruction is a two byte XROM instruction followed by a
single letter ASCII constant, the whole instruction requires four
bytes of program memory.

When executed, the text literal is simply skipped and has no effect
on the alpha register.

.. note::
   It is intentional that the postfix byte is shown. While it can be
   possible to hide it somewhat, it is judged to be better to actually
   show what is going on. This provides better control over program
   memory editing, as the postfix part actually does take a program
   step and will not be considered merged when following an
   instruction that skips the next line. (You may still be able to use
   it after such skip instruction, but it will execute the text
   literal in this case, altering the alpha register.)

.. index:: default operands, operands; default

Default operand
---------------

If the postfix operand is missing, the instruction reverts to a
default behavior. For a shift instruction, it means shift one step:

.. code-block:: ca65

   10 ...
   11 SL 01
   12 ...        ; not a single letter text literal

Such instruction costs two bytes (the XROM itself without any postfix
operand). It executes as a single shift as shown. As it is a single
instruction, it also works well following a test instruction.

If you enter the ``SL 01`` instruction, it takes advantage of the
default and does not store a postfix byte in program memory.

If you delete the postfix operand from program memory, the instruction
that used it will change to its default behavior, which can be seen
when the instruction is shown.

.. note::
   Some care is needed when using default behavior with prompting
   instructions. It will still look for its argument and if you have a
   single character alpha constant that you intended to be an alpha
   constant, then it will become part of the previous
   instruction. This should seldom happen, but if it does, the easiest
   way to deal with it is by rearranging instructions.


.. index:: single stepping

Single stepping
===============

When you single step a semi-merged instruction in run mode (to execute
the program step by step), it works properly, but visual feedback of
the instruction when the ``SST`` key is pressed and held, is just the
bare instruction without any postfix operand.

Dual operand functions
======================

With OS4 you are not limited to a single postfix operand, a function
may use two. This is useful things like comparisons or exchange
between two registers.

In the following example the ``<`` instruction is used to compare two
register operands. As all dual operand instructions it is displayed
infix in a program. A bit in its control word can be used to specify
that it should be followed by a question mark, meant to indicate that
it will optionally skip the next program line.

When entered the instruction is shown first followed by the prompt
underscores:

.. image:: _static/lcd-less-than-program-1.*

Then if we start entering a stack operand:

.. image:: _static/lcd-less-than-program-2.*

When complete the first operand is followed by the second prompt:

.. image:: _static/lcd-less-than-program-3.*

Here the second operand is partially entered:

.. image:: _static/lcd-less-than-program-4.*

When the instruction is complete it will show the text literal to
accept further program steps. (Here shown with some weird
characters due to limitations in the simulator used for screen
capture. On a real calculator they will various characters, often with
all segments on).

.. image:: _static/lcd-less-than-program-5.*

If we now back stop to the previous line we can see the decorated
instruction. In this case it is somewhat too long for the display
making the line number scroll off the display:

.. image:: _static/lcd-less-than-program-6.*

.. note::
   During input the function name is shown first and the operands
   follow it. Once completed the function name is shown between its
   two arguments.

The prompt mechanism is the same as the built-in one, synthetic status
register operands cannot be keyed in. Using synthetic techniques, or
hex editing the program makes it possible to have them in a program:

.. image:: _static/lcd-less-than-program-7.*

.. note::
   If you are observant you may have noticed that the program line
   number is the same for the semi-merged step being entered as the
   text literal being shown when done. This is because two program
   steps are inserted up front in program memory which advances the
   program line counter twice. The user is shown the decorated
   semi-merged instruction with the current line number which is where
   the text literal will be.

Secondary functions as semi-merged
==================================

Secondary functions can also have semi-merged arguments. This works
for both single and dual operands. It also works to have the function
located in a secondary bank. Thus, the most complicated thing you can
put together is a dual argument secondary function in a secondary
bank.

As a secondary function uses a text literal to indicate which function
it is, a dual secondary function requires a text literal with three
bytes. The first byte is the secondary function number, the remaining
two are the two arguments. OS4 will merge all wrapped text literals
to a single three character text literal in this case.


Defining a function
===================

To make a semi-merged function you must start with a specific prelude:

.. code-block:: ca65

                 .name   "XRCL"
   XRCL:         nop
                 nop
                 gosub   argument
                 .con    00 + SEMI_MERGED_NO_STACK
                 ...

The first thing to observe is that there are no bits set in the name
header, this function is not marked as a prompting function.

The first two ``NOP`` instructions signal that this is a
non-programmable execute direct function.

When this function is entered in a program, it is actually executed
rather than just stored. This will cause the ``argument`` routine to
be executed and this one will detect if we are actually in program
mode and will set up the display properly and put the calculator in a
state where it can accept input with the expected display.

The execute direct feature is there to ensure that the function
executes immediately on key down. If you press and hold the ``RCL``
key, it will put up its name and prompt immediately before you release
the key. A function such as ``SIN`` will go through a timeout and
cause a ``NULL`` message if held for long enough.

Using execute direct means that we can mimic the behavior of ``RCL``,
it acts immediate and does not go through the ``NULL`` test.

.. note ::

   The execute direct feature is partially broken with XROM functions
   in the HP-41 mainframe and only works properly in program mode.
   Outside program mode it will actually go through the NULL test, but
   there is in practice not so much harm from this.

.. note ::
   If you have the 41CL, there is an updated mainframe firmware which
   corrects this bug.

The ``argument`` routine is what makes this function become
semi-merged, or at least half of it. As mentioned, the purpose of this
routine is to put the calculator in the proper state to prompt for an
argument for the semi-merged function. It is followed by a control
word which is the default postfix argument byte for this function and
the upper bits are used to signal if we accept direct stack arguments
or not.

In program mode this function does not return. In run-mode it will
appear as this function returns with the argument given by the user in
``ST``, ``G`` and ``C[1:0]``.

.. note::
   Technically, the whole function actually re-executes in run-mode
   and the state is set up so that the second time it picks up the
   entered argument (or takes it from program memory if you are
   running a program) and returns with it, by skipping the control
   word that follows the call.

The second half of the semi-merged feature is not seen at all in the
function prelude. It consists of a hook that is called in program mode
for each program line. This hook does two things. First, it detects
when we are entering a semi-merged argument and will ensure the
display looks right and the program memory is written to in the
correct way, forming the text literal and also prune it if the default
argument is entered. Second, it will display semi-merged program lines
in the decorated fashion, which happens when we are not entering an
argument.

Dual arguments
--------------

Defining a function with dual arguments is similar to the single
argument variant. A prelude looks something like this:

.. code-block:: ca65

                 .name   "<="
   LE:           nop
                 nop
                 gosub   dualArgument
                 .con    SEMI_MERGED_QMARK
                 ...

The routine changes to be ``dualArgument`` and there is no longer a
default postfix argument. This word now only holds flags as defined in
the ``OS4.h``. The function above is marked to have a trailing
question mark in the name to indicate that this function optionally
skips a step. There are also flag bits that allow for telling if stack
arguments are accepted or not, for each of the two arguments.

The argument bytes are returned in ``A[3:2]`` (first argument) and
``A[1:0]`` (second argument).


Rolling your own
================

The above postfix operands are simple to use, but what if you really
need something very different. One example is the Ladybug module which
stores integer literals as program steps.

In the Ladybug module this is implemented by special handling numeric
input which is stored gradually into a program step as it is
keyed. The actual display is done using the ``xargument`` form:

.. code-block:: ca65

                 .section Code, reorder
                 .name   "#LIT"
   Literal:      gosub   xargument     ; mark as special form
                 goto    20$           ; display it
                 ?s13=1                ; running?

The ``GOSUB`` to the ``xargument`` entry marks that this is a special
form. The address following the ``GOSUB`` is called when it should be
displayed in program memory. You need to implement the code to
actually display the program step, probably by fetching bytes from the
text literal that follows the ``#LIT`` function.
