*********
Functions
*********

The different classes and execution of functions is a rather vast
concept on the HP-41, enough to warrant a chapter of its own.

Execution tokens
================

Functions are internally represented by an execution token which is a
sequence of bytes. This is also how they are stored in programs.
There is a very convenient quick reference card that documents
them. You can find a copy of that in "A programmer's handbook" on page
37--38.

The execution token of the current function being keyed in is kept in
register 10 (chip 0) field ``[4:1]``.

Classes of functions
====================

There are three main classes of functions, ordinary functions,
prompting functions and execute direct functions.

In addition there is data entry keys (including backspace), which we
will not cover here.

Ordinary functions
------------------

An ordinary function is one that goes through the NULL check and does
not put up a prompt, e.g. ``SIN``. They can either be programmable or
non-programmable. This is controlled by whether the first instruction
address (internally called XADR) is a ``NOP`` instruction (opcode ``0x000``)
or not.

Execute direct functions
------------------------

.. index:: functions; XKD, functions; execute direct
.. index:: XKD functions, execute direct functions


Execute direct functions (XKD) are use for functions that act
immediately on key down, e.g. ``SHIFT``, ``SST`` and ``R/S``. A
function is marked as being XKD by starting with two ``NOP``
instructions (opcode ``0x000``).

Normally the default address of return to mainframe (``NFRPU``) is
pushed on the stack before execution, but this is not done for
execute direct functions, which must always jump back to some ``NFR``
routine when the function is done.

Prompting functions
-------------------

.. index:: functions; prompting, prompting functions

A prompting function has some upper bits set in its name header. This
specifies what class of prompting function it belongs to. A prompting function
does not go through any NULL check, instead its name is displayed
together with one or more prompt underscores.

The prompt is handled by the partial key sequence parser which goes
to light sleep while waiting for key presses. When the prompt is
completed, it is either combined with the execution token (in case it
is an internal function), or kept
separately in a register (in case it is an XROM function). This is
because there is no room for the operand to be combined together with
the execution token of an XROM. The internal state only have room for
two bytes and the execution token of an XROM uses those two bytes
without any operand attached to it.

Finding a function
==================

.. index:: functions; finding, functions; by name, functions; by identity
.. index:: finding functions, lookup functions

There are two ways a function can be found, by its name and by its
execution token.

The most common way to execute a function by name is to use the
``XEQ`` function and then enter the name (separated by pressing the
Alpha key).

Execution by token is done from inside a program or when bound to a
key on the keyboard.

It can be worth knowing that execution by name actually is a two-step
process. The first step locates the function by its name by scanning
the catalogs (more on this later) and the second step executes the
function by its execution token.

If the function found by name is an MCODE function is, it is first to
checked if it is "execute direct" (XKD). If it is, the function is
immediately invoked. The usual return address to mainframe  (``NFRPU``
at address ``0x00c0``) is not pushed onto the stack in this case. If
it is not XKD, the function name is displayed, which serves two
purposes. If it is a prompting function we want it together with the
prompt. If not, we want the name in the display becomes visible if the
user keeps the key pressed, which is the "talking key" feature. If the
key is kept down for 0.5 seconds, the function invocation is aborted
and ``NULL`` is displayed.

If the function passes the NULL check it is executed by its
execution token, not by its name. That might sound a bit confusing,
but what actually happens is that even though we know the execution
address (XADR in mainframe terminology), we only use that for showing
the name of the function and deciding what class it belongs to. The
actual XADR is only used for execution if the function is XKD. All
other functions are executed by its execution token, even when you
type it by name.

So what does it mean? We look up the function twice and in two different
ways, first by name and then by its execution token. As with every
situation of doing seemingly the same thing but in different ways, we
risk coming to different results and this is no exception to that
rule. What can happen is that you type a function by name, keep the
final Alpha key press down, the function name is properly shown in the
display (it comes from the XADR) which confirms we found it. When
the key is released the function is sent for execution by its
execution token, which results in another scan for the function based
on its token (not its name). This may find a completely different
function that happens to match the given token! Of course, this only
happens if you plug in two modules using the same XROM code, something
that is probably best avoided.


Search order
------------

.. index:: functions; search order, search order

Searching a function by name is done in catalog order. User programs
in catalog are searched first, followed by plug-in modules (XROMs) in
address order [#page3]_ and finally the built-in functions in
catalog 3.

OS4 extends the search by also searching for secondary functions. This
search is done for each XROM page after searching the ordinary FAT in
that page.


Lookup
------

Looking up an XROM by its execution token is done by scanning the
plug-in modules in the same page order as is done when searching by
name.



Semi-merged functions
=====================

.. index:: functions; semi-merged, semi-merged functions

Many operations in the HP-41 consist of a function and a postfix
argument, e.g. ``FIX 4`` or ``RCL IND Z``. When pressed, the operand will
output one or more underscores to be filled in with the argument. The
base operating system allows XROM instructions to be defined as
prompting too, but it cannot represent them in program memory. It is
mainly a side-effect of the flexibility of how the base operating
system was written and the main use of it was to provide an easy way
of doing alpha input to functions such as ``PRP`` in the printer
ROM. Later the Extended Functions module provided means of reading
such arguments from the alpha register.

The OS4 module provides a way for XROM to prompt for arguments and
represent them as program steps. It is not possible to fully
merge such program steps, but OS4 allows you to get partly there.
In program memory the XROM is followed by an alpha literal that
wraps the postfix operand. When shown in program memory, the postfix
operand is automatically taken from the alpha literal, allowing you to
see the instruction in its full glory. However, if you step ahead you
will see the alpha literal as a separate step.


Secondary functions
===================

.. index:: functions; secondary, secondary functions
.. index:: XXROM functions, functions; XXROM

The function address table, or FAT for short is the inventory of
functions that a plug-in module provides. It is located first in the
module. This table provides up to 64 functions, which may have seemed
a lot from the beginning, but with the arrival of banked modules you
may find that you wish you had more entries.

The OS4 module provides a mechanism for providing secondary
functions. Up to 4096 such functions are possible. These extra XROM
functions are called XXROM.

You can see such XXROM functions as having a numeric identity in the
same way as an XROM, though the function number has a wider range
0--4095, e.g. ``XXROM 7,689`` would be the 690th secondary function in a
module with XROM identifier 7 (the numbers start from 0).

.. note::
   The numeric series are separate, so you have up to 64 primary and
   4096 secondary functions in a module.

With the Boost module, you can key the name of the secondary
function from its ``XEQ'`` instruction which is available
as a replacement for the ordinary ``XEQ`` function. This means you can
access a secondary function in the same way as any other named
function. The normal search order rules are used, following the catalog
order. Primary XROM functions are searched before looking at secondary
XXROM functions in the same page.

A secondary function can also be assigned to a key. If you press
such key in user mode it will go through the normal behavior showing
its name and NULL if you keep the key pressed. If it is a prompting
function it will put up its prompt, just like any primary XROM or
built-in function would do.

The actual assignment information is kept inside the system buffer. If
you assign a secondary function to a key and remove the module, the
key will display as an XXROM, e.g. ``XXROM 7,45`` indicating which
function it is and that it is not present.

Secondary functions can also be entered in programs and they will be
correctly displayed in program memory. However, in order to represent
them in program memory they are actually stored as an XROM (acting as
a prefix) followed by a semi-merged alpha literal.

In summary, secondary functions provide a way of having essentially as
many functions as you can fit into the memory constraints rather than
being limited by as fixed maximum of 64. Using the Boost companion
module, you can access them the same way as ordinary functions and
they can also be assigned to keys and stored into program memory. In
addition, they are just as powerful when it comes to prompting as any
normal function.

.. note::
   You need the Boost module to obtain the ``XEQ'`` and ``ASN'``
   replacement functions to access secondary functions. The routines
   that look up secondary functions by name or its numeric identity
   are in OS4.

What is up
==========

.. index:: functions; what is up

In the book "HP-41 MCODE Programming for Beginners" appendix B
(page 132) lists what is up on function entry. Secondary functions
diverge a bit from what is listed there and the list is probably a bit
too detailed anyway. The following is what you can rely on:

#. CPU is set to hex mode.
#. Flags 48 to 55 of the user flag register is in ST.
#. RAM chip 0 is selected.


Internal representation
=======================

.. index:: functions; internal representation

Finally we will take a look at the ways that are used to represent the
function internally. This is probably not anything you normally need
to bother so much about, but in some situations it can be good to know.
It also gives an improved understanding for how it works.

By address
----------

We sometimes represent a function by its execution address (XADR),
which is the first execution address of a function. Here is an example
of how a function starts:

.. code-block:: ca65

                 .name   "RAMED"
   RAMED:        nop                   ; non-programmable
                 ?s3=1                 ; program mode?

In this case the execution address (XADR) corresponds to the ``RAMED``
label. From this we can look at previous locations to get the name of
the function and we can use the XADR to execute the function. We may
also inspect the first locations at the XADR to see whether this
function is non-programmable or XKD. The example above is an ordinary
non-programmable function.

For secondary functions the address of the XADR is not enough. We also
need to keep the bank it is located in, so the XADR for a secondary
function is actually two addresses. The bank is represented by a
pointer to the bank switcher routine associated with the secondary
FAT header which points the secondary FAT the function belongs
to. This allows for switching to the correct bank before accessing the
first locations.

By execution token
------------------

Ordinary XROM functions are represented by a two bytes execution
token. Secondary functions have a couple of different representations:

1. The XROM (1--31) identity and the secondary function number
   (0--4095). This is how key assignments are represented.

2. By the XROM prefix function associated with the secondary FAT
   header and an adjusted secondary function number (0--255).
   This is also how they are stored in program memory.

During keyboard execution the needed information, such as XADR,
bank switcher and secondary function number are stored in the M
register or other temporary places.

.. rubric:: Footnotes
.. [#page3]
   The HP-41CX extended the plug-in module range by adding things in
   page 3. The search is from page 5 to 15, but on an HP-41CX page 3
   is additionally searched after page 15.
