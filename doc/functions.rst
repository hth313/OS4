*********
Functions
*********

The different classes and execution of functions is a rather vast
concept on the HP-41, enough to warrant a chapter of its own.

Classes of functions
====================

There are three main classes of functions, ordinary functions,
prompting functions and execute direct functions.

In addition there is digit and alpha entry keys (including backspace),
but they not really normal functions, instead they are special handled
input.

Ordinary functions
------------------

An ordinary function is one that goes through the NULL check and does
not put up a prompt, i.e. ``SIN``. They can either be programmable or
non-programmable. This is controlled by whether the first instruction
(pointed to by its XADR) is a ``NOP`` instruction (opcode ``0x000``)
or not.

Prompting functions
-------------------

A prompting function has some upper bits set in its name header. This
indicates the class of prompting function it is. A prompting function
does not go through any NULL check, instead its name is immediately
displayed with some prompt underscores.

When handling the prompt (partial key sequence), the calculator goes
to sleep. When the prompt is completed, it is either combined with the
execution token (in case of not an XROM function), or kept aside (in
case it is an XROM function). This is because there is no room for the
operand together with execution token of the XROM. The execution
token is two bytes and the XROM uses up those two bytes.

Execute direct functions
------------------------

Execute direct functions (XKD) are use for functions that act
immediately on key down, i.e. ``SHIFT``, ``SST`` and ``R/S``. A
function is marked as being XKD by starting with two ``NOP``
instructions (opcode ``0x000``).

Normally the default address of return to mainframe (``NFRPU``) is
pushed on the stack before execution, but this does not happen here,
so you must always jump back to some ``NFR`` routine when the function
is done.


Finding a function
==================

There are two ways a function can be found, by name and by its
execution token.

The most common way to execute a function by name is to use the
``XEQ`` function by name (separated by pressing the Alpha key).

Execution by token is done from inside a program or when bound to a
key on the keyboard.

It can be worth knowing that execution by name actually is a two-step
process where there second step involves execution by token. The
process starts with a search for the function in the various function
name tables (more on this later).

Once found, the function is first to checked if it is "execute direct"
(XKD). If it is, the function is immediately invoked. The usual return
address to mainframe  (``NFRPU`` at address ``0x00c0``) is not pushed
onto the stack in this case. If it is not XKD, the function is
displayed, which serves two purposes. If it is a prompting function we
want it together with the prompt. If not, we want the name in the
display in case the user keeps the key pressed, which is the "talking
key" feature. If the key is kept down for 0.5 seconds, the function
invocation is aborted and ``NULL`` is displayed.

If the function passed the NULL check it is executed by its
execution token, not by its name. That might sound a bit confusing,
but what actually happens is that even though we know the execution
address (XADR in mainframe terminology), we use that for showing
the name of the function and deciding what class it belongs to. The
actual XADR is only used for execution if the function is XKD. All
other functions are executed by its execution token, even when you
type it by name.

So what does it mean? We look up the function twice and in different
ways, first by name and then by its execution token. As with every
situation of doing seemingly the same thing but in different ways, we
risk coming to different results and this is no exception to that
rule. What can happen is that you type a function by name, keep the
final Alpha key press down, the function name is properly shown in the
display (it comes from the XADR), to confirm we found it, then when
the key is released the function is sent for execution by its
execution token, which results in another scan for the function based
on its token (not its name) and we may find it matching a completely
different function matching that token!  Of course, this only happens
if you plug in two modules using the same XROM code, something that is
probably best avoided.


Search order
------------

Searching a function by name is done in catalog order. User programs
in catalog are searched first, followed by plug-in modules (XROMs) in
address order [#page3]_ and finally the built-in functions in
catalog 3.

OS4 extends the search by also searching for secondary functions, this
search is done for each XROM page after searching the ordinary FAT in
that page.


Lookup
------

Looking up an XROM by its execution token is done by scanning the
plug-in modules in the same page order as is done when searching by
name.



Semi-merged functions
=====================

Many operations in the HP-41 consists of a function and a postfix
argument, i.e. ``FIX 4`` or ``RCL IND Z``. When pressed, the operand will
output one or more underscores to be filled in with the argument. The
base operating system allows XROM instructions to be defined as
prompting too, but it cannot represent them in program memory. It is
mainly a side-effect of the flexibility of how the base operating
system was written and the main use of it was to provide an easy way
of doing alpha input to functions such as ``PRP`` in the printer
ROM. Later, the Extended Functions module provided means of reading
such arguments from the alpha register.

The OS4 module provides a way for XROM to prompt for arguments and
represent them as program steps. It is not possible to fully
merge such program steps, but OS4 allows you to get partly there.
In program memory the XROM is followed by an alpha literal that
wraps the postfix operand. When shown in program memory, the postfix
operand is automatically taken from the alpha literal, allowing you to
see the instruction in its full glory. However, if you step ahead you
will see the alpha literal as a separate step.

@@ Take stuff from the ladybug manual


Secondary functions
===================

The function address table, or FAT for short is the inventory of
functions that a plug-in module provides. It is located first in the
module. This table provides up to 64 functions, which may have seemed
a lot from the beginning, but with the arrival of banked modules you
may find that you wish you had more entries.

The OS4 module provides a mechanism for providing secondary
functions. Up to 4096 such functions are possible. These are
internally called eXtended XROM functions (XXROM).

You can see such XXROM functions as having a numeric identity in the
same way as an XROM, though the function number has a wider range
0--4095, i.e. ``XXROM 7,689`` would be the 690th secondary function in a
module with XROM identifier 7 (as the numbers start from 0).

.. note::
   The numeric series are separate, so you have up to 64 primary and
   4096 secondary functions in a module.

With the Boost module, you can key the name of the secondary
function from its ``XEQ'`` instruction which is automatically available
as a replacement for the ordinary ``XEQ`` function. This means you can
access a secondary function in the same way as any other named
function. The normal search order rules used, following the catalog
order. Primary XROM functions are searched before looking at secondary
XXROM functions in the same page.

A secondary function can also be assigned to a key. If you press
such key in user mode it will go through the normal behavior showing
its name and NULL if you keep the key pressed. If it is a prompting
function it will put up its prompt, just like any primary XROM or
built-in function would do.

The actual assignment information is kept inside the system buffer. If
you assign a secondary function to a key and remove the module, the
key will display as an XXROM, i.e. ``XXROM 7,45`` to show the function
that is not present, in the same way as is done for an XROM.

Secondary functions can also be stored into programs and they will be
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
   replacement functions that will search also for secondary
   functions.

What is up
==========

In the book "HP-41 MCODE Programming for Beginners" appendix B
(page 132) lists what is up on function entry. Secondary functions
diverge a bit from what is listed there and the list is probably a bit
too detailed anyway. The following list is what you can rely on:

#. CPU is set to hex mode.
#. Flags 48 to 55 of the user flag register is in ST.
#. RAM chip 0 is selected.


Internal representation
=======================

Finally we will take a look at the ways that are used to represent the
function internally. This is probably not anything you normally need
to bother so much about, but in some situation it can be good to know
and it gives an improved understanding for how it works.

By address
----------

We sometimes represent a function by its address, which is the first
execution address of a function.

Here is the start of a function:

.. code-block:: ca65

                 .name   "RAMED"
   RAMED:        nop                   ; non-programmable
                 ?s3=1                 ; program mode?

In this case the execution address (XADR) corresponds to the ``RAMED``
label. From this we can look up to get the name of the function and
use the XADR to execute the function. We may also inspect the first
locations of the functions to see whether this function is
non-programmable or XKD. The example above is an ordinary
non-programmable function.

When dealing with secondary functions the address of the XADR is not
enough. We also need to keep the bank it is located in, so the XADR is
really two addresses here. The bank is represented by a pointer to the
bank switcher routine associated with the secondary FAT. This allows
for switching to the correct bank to read the name and check the first
locations.

By token
--------

For ordinary XROM functions this is the two-byte XROM function code.
Secondary functions are identified by the XROM identity and as 12-bit
function index.


During execution the secondary function code is stored in the M
register.






.. rubric:: Footnotes
.. [#page3]
   The HP-41CX extended the plug-in module range by adding things in
   page 3. The search is from page 5 to 15, but on an HP-41CX page 3
   is additionally searched after page 15.
