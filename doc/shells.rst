******
Shells
******

.. index:: shells

A new concept provided is a shell which provides a way of installing
new keyboard and display behaviors.

The shell keyboard replaces the standard keyboard layout and allows
for complete redefinition of keys. You can use standard functions,
XROMs and even XXROMs. The display routine can be used to change the
default view of the X register to something that suits the current
shell better.

Both the keyboard replacement and display routines are optional and
allows for overriding one of them, while using the default behavior
of the other.

By providing several MCODE functions, bind them on a custom keyboard
and perhaps a new default display, you have an application. This can
be a new mode to make the HP-41 behave like an HP-16C in integer mode,
the HP-12C by providing suitable financial functionality, or even a
mode for working with complex numbers.

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
   combat computer. In such cases you may want to disable certain
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

There are four kind of entities stored in the shell stack. Even though
they are pushed on the stack, they are kept
together based on its kind. Pushing a shell means it is stored on top
of other shells of the same kind.

You can think of a shell as defining a keyboard layout. Such keyboard
layout does not need to have a meaning for every key. If a key that is
not handled is pressed, the next shell on the stack is inspected.
However, among the applications, only the topmost one is given the
chance to handle a key press, shadowed applications are ignored.

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
previous application when leaving the currently active one.


Transient applications shells
-----------------------------

.. index:: shells; transient application, transient applications

A variant of an application is a *transient application shell*. This is
a specialized version of an application that always is at the top of
the stack and there can be only one transient application shell in the
stack. A transient application is meant to be used for some
temporary mode that is normally exited when a key not handled by it is
pressed. This is similar to how the original catalog 1--3 works. If
you press a key that does not have a defined by the catalog when it is stopped,
the catalog exits and the key performs its underlying behavior.

This means that if you press a key that is not handled by the
transient application, it is removed from the shell stack and the
topmost ordinary application will get a chance to handle the key.

.. figure:: _static/transient-shell.*

   The shell stack with transient application


System shells
-------------

.. index:: shells; system, system shells

The third shell variant is a *system shell*. System shells are located
below all application shells in the shell stack. All system shells
are active and each one is always consulted in the stacking order
until a handler is found. They are typically used for
replacing single (or a few) keys, providing alternative or additional
functionality. One example is a replacement for the assign (``ASN``)
function that could be implemented using a system shell.

Extension handlers
------------------

.. index:: extension handlers

The final entity that lives in the shell stack is *extension
handlers*. They are very different from the shells as they
implement a generic message system. There are no keyboard or display
behavior associated with them. Events are routed to message handlers
which act on a given message.

Shell structure
===============

.. index:: shells; structure

A shell is defined by a structure that consists of several elements.
It is defined as follows:

.. code-block:: ca65

                 .align 4
   myShell:      .con    kind
                 .con    .low12 displayRoutine
                 .con    .low12 standardKeys
                 .con    .low12 userKeys
                 .con    .low12 alphaKeys
                 .con    .low12 appendName

The structure must start on an address aligned by 4. It contains
several pointers that also must be aligned by 4 (which can be seen by
the use of the ``.low12`` relocation operator in the example above).


Kind field
----------

.. index:: shells; kind

The kind field tells what kind of shell this entry represents. The
values are defined in ``OS4.h`` and are either
``SysShell``, ``AppShell`` and ``TransAppShell``. The
``GenericExtension`` also exists, but the structure following it
is very differs compared to application and system shells.

Display handler
---------------

.. index:: display handler

This points to the custom display handler that overrides the default
display of the stack X register. This is called to replace the
built-in provided display of X when appropriate. To get a steadier
display it is recommended that functions you implement in your
application also ends by updating the display on their own. This is
done by calling the ``shellDisplay`` routine, which this takes care of
all possible situations. For example, if a user program is running we do
not want to alter the display. Furthermore, the application which your
function belongs to may not be the active one, as the user are free to
execute any function by name regardless of the state of the shell
application stack.

Calling ``shellDisplay`` at the end of your functions reduces the
flicker that results by first having the standard default display of X
being replaced by the desired view.

A custom display routine can be used to visualize the floating point
value in a different way, i.e. attaching some unit, display as ratio,
change the number of display digits in certain situations, or just
anything in your imagination. It can also be used for visualizing
numbers that are stored on a custom stack, i.e. integers (Ladybug
module) or complex numbers. You could even make an application that
shows Roman numerals.

In fact, the display routine is rather free to take whatever actions
it desires. It is expected to put a value in the display that
corresponds to the application it belongs to. However, if the
application is something completely non-standard, it may show whatever
is appropriate as the default view depending on the state of the
application.

Set this field to 0 if a display handler is not defined. In this case
nothing happens with the display and you will see the normal display
of the X register.

Standard keys
-------------

This field points to structure that defines the keyboard
layout. This keyboard definition is the replaced standard keyboard.

User keys
---------

This field points to structure that defines the keyboard
layout. This keyboard definition is the replaced user keyboard.
Normally you will set this to the same value as standard keys.

Alpha keys
----------

This field points to another structure that defines the alpha keyboard
layout. If using the default alpha keyboard, set this field to 0.

Name
----

This fields points to a name of the shell stored in the same way as
would do with a text literal with the ``MESSL`` routine. This should
be a short name, typically 3--7 characters.

The intended use is to have a user friendly text representation of the
shell. A shell catalog that visualizes the shell stack could make use
of it.

Timeout handler
---------------

This fields points to a handler which is called when there is a
timeout event. This field is only valid for application shells.

Set this field to 0 if no timeout handler is provided.

An example
----------

A Time-Value-Money style shell provides a keyboard with some keys
replaced. Its shell definition could look as follows:

.. code-block:: ca65

                 .align  4
   tvmShell:     .con    AppShell
                 .con    0                 ; no display handler defined
                 .con    .low12 keyHandler ; standard keys
                 .con    .low12 keyHandler ; user keys
                 .con    0                 ; alpha keys, use default
                 .con    .low12 myName
                 .con    0                 ; no timeout handler

                 .align  4
   myName:       .messl  "TVM"

This is an application shell and it provides an alternative
keyboard that is used in both standard and user mode. There is no
display override as it relies on the standard display of X.

.. _auto-terminate-transapps:

Key handlers
============

.. index:: keyboards; structure

A shell descriptor has pointers to keyboard handlers which is another
structure. It is defined as follows:

.. code-block:: ca65

                 .align  4
   keyHandler:   gosub   keyKeyboard   ; does not return
                 .con    (1 << KeyFlagSparseTable) | (1 << KeyFlagTransientApp) ; flags
                 .con    .low12 doDataEntry
                 .con    .low12 clearDataEntry ; end data entry
                 .con    .low12 keyTable
                 .con    .low12 transientTermination

This record normally starts with a call to the ``keyKeyboard`` routine
that expects the fields that follows.

The flag field describes certain properties of the keyboard, such as
if it allows top rows (A--J) auto assignment, if the keyboard table is
sparse and whether this (transient application) should auto terminate
on a key that is not handled by it. See ``OS4.h`` for more details.

The field with ``doDataEntry`` is the routine that handles data
entry. If the keyboard table does not define any data entry keys, you
can set this field to zero.

The field with ``clearDataEntry`` is called whenever data entry is
ended. Certain keys end data entry and the routine pointed to by this
field is called when that happens. This field should be defined if
your application needs to be informed when this happens.

The field with ``keyTable`` is the actual keyboard table. Refer to
:ref:`defining-keyboards` for more information about how this is done.

.. index:: transient applications; auto termination

The field ``transientTermination`` is used when the
``KeyFlagTransientApp`` bit is set. This field shall be set to either
0 or a valid packed pointer to a routine that does additional things
needed on auto termination. The default behavior removes the transient
application and the scratch area, which should suffice in most cases.
This routine is called before the transient application and scratch
area are removed.

Custom key handler
------------------

.. index:: keyboards; custom key handler

While ``keyKeyboard`` is very convenient when handling keyboard
layouts and reassignments, you are not bound to use it.
A simple key input routine could use a custom key handler instead:

.. code-block:: ca65

                 .align  4
   keyHandler:   gosub   clearTimeout
                 gosub   exitTransientApp
                 c=keys
                 rcr     3
                 c=0     xs            ; C.X= key code
                 gosub   assignKeycode
                 bcex                  ; B= floating point key code
                 gosub   RSTKB         ; reset key board
                 s13=1                 ; continue executing
                 golong  RCL           ; push keycode on stack

This example is from the ``KEY`` function in the Boost module. It has
already set up a timeout and a transient application, so these are
first removed. Then the key code is fetched and the ``assignKeycode``
routine to convert it to a user friendly key code, the same as used in
assignments. Finally, it resets the keyboard (wait until key is
released) and push the key code on stack and continue execution.

.. note::
   As can be seen the key handler is really a routine. The structure
   used with ``keyKeyboard`` is picked up from the return address left
   on the stack after the call to it.

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
the API, not the shell descriptor itself as it can actually handle
unaligned addresses. Second, modules can be removed or moved to a
different page while the calculator is off. To handle this the page
numbers 0 and 1 (which actually points to the mainframe OS pages)
have special meanings in the reconfiguration process. No shell can
point to these pages. The reconfiguration is executed when the
calculator is turned on, see further below.

Kind field
----------

A single digit kind is stored in the descriptor. This is to make it
quicker to categorize shells in the stack without having to look it up
in the descriptor structure.

XROM number
-----------

The last two digits are the XROM number of the owning module. They
exist to make the descriptor number unique and for
identification of the owning module. As modules can be moved, the page
may change and only the 12-bit page offset is fixed. Including the XROM
in the descriptor ensures that we both can identify the owning module
in case two modules happen to use the same page address for different
shells.

An example descriptor is ``AC00410`` (hex number). The ``AC00`` is
the actual address of the shell descriptor. ``4`` says it is an
application. Finally ``10`` is 16 decimal, which means it belong to a
module with XROM 16, which is currently plugged into page address
``A000``.

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
you activate an application A and then activate other applications
they will shadow application A. Activating application A again at this
point means it is moved up ahead of the applications that shadows it,
making A the active application.

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
it. This is done by calling the ``reclaimShell`` routine from the
power on poll vector.
