******
Shells
******

.. index:: shells

A new concept provided is a shell which provides a way of installing
new keyboard and display behaviors.

The shell keyboard replaces the standard keyboard layout and allows
for complete redefinition of keys. You can use standard functions,
XROMs and even XXROMs. The display routine can be used to always show
the X register in a different way.

Both the keyboard replacement and display routines are optional and
allows for overriding one of them, while using the default behavior
of the other.

By providing several MCODE functions and a custom keyboard, perhaps a
new default display, you have an application. This can be a new mode
to make the HP-41 behave like an HP-16C in integer mode, the HP-12C
by providing suitable financial functionality, or even a mode for
working with complex numbers.

It is worth pointing out that the new keyboard definition is done in a
similar way as the built-in keyboard, but with additional capabilities
to accept both XROM and XXROM functions on it. No user key assignments
are used. In fact, the user can redefine keys on top of it in the
usual way, to customize the calculator further.

.. note::
   Even if shells allow for making radical different behaviors, it is
   often a good idea to adhere to the basic behaviors, allowing the
   calculator to feel like it normally does. Thus, many keys should
   probably behave more or less like they usually do. The top mode
   changing keys should allow for entering program mode or work with
   the alpha register. Keys to control program execution should
   probably still do that.

.. note::
   If desired, you can experiment with making the calculator
   completely customized for a particular purpose, like a military
   combat computer. In such cases you probably want to disable certain
   things that may distract the operator. Back in the days, OS4 would
   probably have been a great asset for such purposes. However, today
   we are probably more inclined to broaden rather than restrict the
   capabilities of the HP-41.


Shell stack
===========

.. index:: shells; stack

The shells are stored in a shell stack. If you activate an
application shell it pushed on top of the stack, shadowing all
applications below it. When you exit an application, the one
immediately below becomes active again, all the way down to the
standard behavior.

There are four kind of entities stored in the shell stack, described
below. Even though they are pushed on the stack, they are kept
together based on its kind. Pushing a shell means it is stored on top
of other shells of the same kind.

You can think of a shell as defining a keyboard layout. Such keyboard
layout does not need to have a meaning for every key. If a key that is
not handled is pressed, the next shell on the stack is inspected.
However, only the top application is given the chance to handle a key,
any shadowed application is not consulted.

.. figure:: _static/shells.*

   The shell stack


Shell kinds
===========

.. index:: shells; kind

There are four kinds of shells and they have different purposes and
follow somewhat different rules.

Application shells
------------------

.. index:: shells; applications, applications

The most fundamental shell type is the *application shell*. They live
near the top of the shell stack. Only the topmost application shell on
the stack is consulted for interpreting the keyboard and the display
behavior. Any application shell below the top one are ignored, but are
kept to preserve the ordering to allow the user go "back" to a
previous application, by leaving the currently active one.


Transient applications shells
-----------------------------

.. index:: shells; transient application, transient applications

A variant of an application is a *transient application shell*. This is
a specialized version of an application that always are at the top of
the stack and there can be only one transient application shell in the
stack. A transient application is meant to be used for some
temporary mode that is normally exited when a key not handled by it is
pressed. This is similar to how the original catalog 1--3 works. If
you press a key that is not used by the catalog when it is stopped,
the catalog exits and the key performs its usual behavior.

This means that if you press a key that is not handled by the
transient application, it is removed from the shell stack and the top
most ordinary application will get a chance to handle the key.

.. figure:: _static/transient-shell.*

   The shell stack with transient application


System shells
-------------

.. index:: shells; system, system shells

The next shell variant is a *system shell*. System shells are always
located below all application shells in the shell stack. All system shells
are always active in their stacking order. They are typically used for
replacing single (or a few) keys, providing alternative or additional
functionality. One example is a replacement for the assign (ASN)
function that could be implemented using a system shell.

Extension handlers
------------------

.. index:: extension handlers

The final thing that lives in the shell stack are *extension
handlers*. They are very different from the shells as they
implement a generic message system. There are no keyboard or display
behavior associated with them. Events are routed to message handlers
which act on a given message.

Shell structure
===============

..index shells; structure

A shell is defined using a structure with several elements as follows:

.. code-block:: ca65

                 .align 4
   myShell:      .con    kind
                 .con    .low12 displayRoutine
                 .con    .low12 standardKeys
                 .con    .low12 userKeys
                 .con    .low12 alphaKeys
                 .con    .low12 appendName

The structure must start on an address aligned by 4. The pointers it
uses to other elements also must be aligned by 4 (which can be seen by
the use of the ``.low12`` relocation operator).


Kind field
----------

..index shells; kind

The kind field tells what kind of shell this entry represents. The
values are defined in ``OS4.h`` and are either
``SysShell``, ``AppShell`` and ``TransAppShell``. The
``GenericExtension`` also exists, but the structure following it
differs radically from the application and system shells.

Display handler
---------------

.. index:: display handler

This points to the custom display handler that overrides the default
display of the stack X register. This is called to replace the
built-in provided display of X when appropriate. To get a steadier
display it is recommended that functions you implement in your
application also ends by updating the display on their own, by calling
the ``shellDisplay`` routine, which this takes care of all possible
situations. For example, if a user program is running, we do
not want to alter the display. Furthermore, the application which your
function belongs to may not be the active one, as the user are free to
execute any function by name regardless of the state of the shell
application stack.

Calling ``shellDisplay`` at the end of your functions reduces the
flicker that occurs by first having an incorrect default display of X
being replaced by the desired view.

A custom display routine can be used to visualize the floating point
value in a different way, i.e. attaching some unit, display as ratio,
change the number of display digits in certain situations, or just
anything in your imagination. It can also be used for visualizing
numbers that are stored on a custom stack, i.e. integers (Ladybug
module) or complex numbers.

In fact, the display routine is rather free to take whatever actions
it desires. It is expected to put a value in the display that
corresponds to the application it belongs to. However, if the
application is something completely non-standard, it may show whatever
is appropriate as the default view depending on the state of the
application.

If not used, set it to 0. In this case nothing happens with the
display and you will see the normal X display.

Standard keys
-------------

This field points to another structure that defines the keyboard
layout. This keyboard definition is the replaced standard keyboard.

User keys
---------

This field points to another structure that defines the keyboard
layout. This keyboard definition is the replaced user keyboard.
Normally you will set this to the same value as standard keys.

Alpha keys
----------

This field points to another structure that defines the alpha keyboard
layout. If using the default alpha keyboard, set this field to 0.

Name
----

This fields points to a routine that appends the name of the shell
to the display. This should be a short name, typically 3-7 characters.

The intended use is for user friendly text representation of the
shell. A shell catalog that visualizes the shell stack could make use
of it.

Examples
--------

A Time-Value-Money style shell provides a keyboard with some keys
replaced. Its shell definition could look as follows:

.. code-block:: ca65

                 .align  4
   tvmShell:     .con    AppShell
                 .con    0             ; no display handler defined
                 .con    .low12 keyHandler ; standard keys
                 .con    .low12 keyHandler ; user keys
                 .con    0                 ; alpha keys, use default
                 .con    .low12 myName

                 .align  4
   myName:       .messl  "TVM"

This is an application shell and we only provide an alternative
keyboard in both standard and user mode. There is no display override
as we use the standard display of X.


Internal representation
=======================

To better understand shells it can be worth looking at how they are
represented. A shell consists of seven digits which means that two
shells are stored in one register. The seven digit sequence can be
broken up in three parts.

Address
-------

The first 4 digits is the address of the shell structure. This means
that a shell in theory can be located at any address in the 64K memory
space.

Not every address is actually possible. First of all it must be
aligned to an even 4-bit word address. This limitation is imposed by
the API, not the shell descriptor which could actually handle
unaligned addresses. Second, modules can be plugged in and removed,
they can also be moved to a different page while the calculator is
off. To handle this, the page numbers 0 and 1 (which points to the
mainframe OS firmware) have special meaning in the reconfiguration
process when the calculator is turned on, see further below.

Kind field
----------

A single digit kind is stored in the descriptor. This is to make it
quicker to categorize shells in the stack without looking it up in the
descriptor structure.

XROM number
-----------

The last two digits are the XROM number of the owning module. They
exist to make the descriptor number (quite) unique and for
identification of the owning module. As modules can be moved, the page
may change and only the 12-bit page offset is fixed. Adding the XROM
ensures that we both can identify the owning module in case two modules
happen to use the same page address for different shells.

Activation
==========

.. index:: shells; activation, activation; of shells

Once you have created a shell structure, activating the shell is done
by calling ``activateShell``. This routine takes a packed pointer to
the shell structure (which is why it needs to be aligned on an even
address by 4).

Activation means that a shell descriptor is stored on the shell stack
at the topmost location among existing shells of the same kind. It
essentially means it becomes the first shell to be consulted of its
kind.

You can activate a shell multiple times. Doing so means that it will
get moved to become the topmost shell of its kind. In other words, if
you activate an application A and then activate other applications to
shadow application A, activating application A again means it is moved
up ahead of the applications that shadows it, making A the active
application.

Deactivation
============

.. index:: shells; deactivation, deactivation; of shells

You can exit a shell using the ``exitShell`` routine. This will
deactivate the shell, bringing any previously shadowed shell in focus
again.

Reclaim at power on
===================

.. index:: shells; reclaim, reclaim; shells

Shells go through a process similar to buffers in the HP-41. At power
on they are all marked for removal and it is expected that any plug-in
module that wants its shell to survive a power cycle will reclaim
it. This is done using the power on poll vector. The ``reclaimShell``
routine is used.
