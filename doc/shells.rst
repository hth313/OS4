******
Shells
******

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

The shells are stored in a shell stack, so that if you activate an
application shell it stored on top and shadows the previous
behavior. If you activate yet another application shell, it will
shadow all prior shells. When you exit an application, the one
immediately below becomes active again, all the way down to the
standard behavior.

Shell kinds
===========

There are four kinds of shells and they have different purposes and
follow somewhat different rules.

Application shells
------------------

The most fundamental shell type is the *application shell*. They live
near the top of the shell stack. Only the topmost application shell on
the stack is consulted for interpreting the keyboard and the display
behavior. Any application shell below the top one are ignored, but are
kept to preserve the ordering to allow the user go "back" to a
previous application, by leaving the currently active one.


Transient applications shells
-----------------------------

A variant of an application is a *transient application shell*. This is
a specialized version of an application that always are at the top of
the stack and there can be only one transient application shell in the
stack. A transient application is meant to be used for some
temporary mode that is normally exited when a key not handled by it is
pressed. This is similar to how the original catalog 1--3 works. If
you press a key that is not used by the catalog when it is stopped,
the catalog exits and the key performs its usual behavior.

In the HP-41, the original catalogs and the clock display would
roughly correspond to transient applications. In fact, if the shell
mechanism would have been available at the time, a transient
application would most likely have been used to implement them. As the
shell mechanism did not exist, various other tricks were used instead.

A transient application can thanks to its single and short-lived
existence use various additional resources. There is a
scratch area that can be easily obtained from the system buffer for
temporary state storage. There is also support for borrowing the
interval timer from the Time module (if present). This timer is
normally used for the clock display, but thanks to OS4 being in page
4, you can borrow it (when available) from the Time module and use it
for periodic updates or for implementing a timeout.

System shells
-------------

The next shell variant is a *system shell*. System shells are always
located below all application shells in the shell stack. All system shells
are always active in their stacking order. They are typically used for
replacing single (or a few) keys, providing alternative or additional
functionality. One example is a replacement for the assign (ASN)
function that could be implemented using a system shell.

If the active application shell (if it exists) does not define a key,
it passes through to the system shells which are consulted in the
order they appear on the shell stack. The first system shell found
that defines the key is the one that handles it. This provides a
flexible and extensible mechanism for redefining keyboard behavior
partially. The mechanism allows different handlers to be considered
one at a time in a consistent and controlled way. They will not
interact in ways that gives unpredictable behavior.

Extension handlers
------------------

The final thing that lives in the shell stack are *extension
handlers*. They are very different from the shells as they
implement a generic message system. There are no keyboard or display
behavior associated with them. Events are routed to message handlers
which act on a given message.

You can see extension handlers as a more flexible variant of poll
vectors. Some event is propagated to defined handlers that act on
it. The extension handler mechanism is more flexible in that it can
pass a message specific state in the ``N`` register. This can be used for
parameters, or some kind of accumulator that is updated by the message
handlers where the final state may be passed back as a result. A
message handler can choose to act on the message on its own and
prevent further propagation of the message to other message handlers,
or it may allow other handlers to also see the message.

This mechanism is a lot more flexible than poll vectors, but it
comes with a somewhat higher overhead as it needs to scan the stack
and then scan lists for appropriate handlers to call. Compare this to
poll vectors that simply scan a fixed offset on each of the ROM pages.

The extensible catalog mechanism in the Boost module (``CAT'``
function) sends a message to extension handlers that a given catalog
is desired. Here each extension handler in turn checks if this catalog
number is something it implements and in that cases it prevents
further propagation of the message and the requested catalog is
shown. If no message handler implement the catalog, the message will
return to the originator (``CAT'`` function) which then performs some
suitable default action.

Other events can inform that the shell stack is altered or that ``XEQ``
is starting RPN execution in a new location so that any pending
returns addresses on the stack should be cleared. This is done
today internally by the firmware, but there is no way for a module to
get informed about it, as HP never defined a poll vector for such
seemingly specialized event. However, today the extension handler
makes it possible for an alternative ``XEQ'`` function to send out
such notification by using the extension handler mechanism.

Shell structure
---------------

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

The kind field tells what kind of shell this entry represents. The
values are defined in ``OS4.h`` and are either
``SysShell``, ``AppShell`` and ``TransAppShell``. The
``GenericExtension`` also exists, but the structure following it
differs radically from the application and system shells.

Display routine
---------------

This points to the custom display routine that overrides the default
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

You can exit a shell using the ``exitShell`` routine. This will
deactivate the shell, bringing any previously shadowed shell in focus
again.

Reclaim at power on
===================

Shells go through a process similar to buffers in the HP-41. At power
on they are all marked for removal and it is expected that any plug-in
module that wants its shell to survive a power cycle will reclaim
it. This is done using the power on poll vector. The ``reclaimShell``
routine is used.



Temporary application shells
============================




Scratch area
============

Application shells may need to keep some kind of state. The normal way
of doing this is to allocate a buffer. The typical case is an
application which may need to store settings or keep some extension to
the RPN stack. As there can be multiple applications active in the
shell stack, it makes sense to use a buffer for this purpose.

A temporary application shell is typically a temporary mode, to
display a catalog, some custom input routine or a periodically
updating display mode like a clock. As there can be only one temporary
application active at any time and no stacking behavior is allowed,
using a buffer may feel a bit overkill. For this situation the
OS4 module provides a temporary scratch area which is held in the
system buffer.

The scratch area can be up to 15 registers large. If a catalog is
implemented using a temporary application shell, it start by running
normally to display the catalog entries. If stopped, the catalog can
return and let the calculator sleep, thereby saving power. However,
all CPU registers may get clobbered and some storage area is needed to
preserve state. This can be solved using the scratch area and saving
the catalog state in it.
An alternative is to use the status area in the lower RAM address
area, but it is pretty much used up by the operating system and it
may be hard to tell what may be safe to use. It is entirely possible
that some device may request the calculator to be waked up and
serviced, invoking poll vectors and it may be hard to tell what area
is really safe. The scratch area provides a solution to this problem.

The downside of the scratch area is that it needs to allocate
registers from the free area. This has a potential problem, as there
has to be enough registers free, otherwise it will fail.

If there are not enough registers available, you will need to take
some actions, which in the simplest case will be to bail out, which
typically will be releasing any allocated resources (exiting the
transient application) and exiting via `noRoom`.


System shells
=============

System shells are intended for tuning the default behavior of the
standard keyboard. Advanced modules from the past like the Zenrom and
CCD used various tricks with the partial key sequence mechanism to
wedge in alternative behavior. Such tricks may result in certain
incompatibilities. Using a system shell provides a cleaner way of
accomplishing some of these extensions. You can for example provide a
new alternative ``ASN`` or ``CAT`` functions. It is also possible to add
functionality to "unused" keys, such as shifted USER, PRGM and ALPHA
keys. An alternative CAT may via the extension point mechanism provide
an extensible catalog, allowing other modules to provide additional
catalog functionality.

System shells are stored in the shell stack and are consulted in their
stacking order. This way the one higher up in the stack has priority
over one lower down, if they replace the the same key. In
contrast to application shells, where the topmost shell is consulted
and the rest are ignored, system shells are consulted in order
until a shell that handles the key press are found. Thus, system
shells merge their functionality while an application shell shadows
the all other applications.


Extension points
================

Extension points differ from shells in that it does not have
anything to do with providing alternative functionality to keys or a
different display routine.

The data structure used by extension points is very different from the
various shells. Only the first identifier word is "shared" with
them. The rest is just a list of the message numbers it will handle
coupled with a pointer to the handler itself.

Extension structure
-------------------

The extension structure is fairly simple:

.. code-block:: ca65

                 .align  4
   extensionHandlers:
                 .con    GenericExtension
                 .con    ExtensionCAT
                 .con    .low12 catHandler
                 ...
                 .con    ExtensionListEnd

As usual it needs to be aligned. The first word must be
``GenericExtension`` to separate it from being some kind of shell.
After this follows pairs of the message identity (number) and its
handler. The table must end with ``ExtensionListEnd``.

Using a list means that a module only needs to define one extension
structure, which saves precious RAM space.

.. note::
   Of course, if you want to use more than one record in order to
   provide optional functionality in groups that are independently
   activated, it can make sense to do that using multiple records.

Activation of the extension handlers can be done from the deep wake up
poll vector:

.. code-block:: ca65

   #include "mainframe.h"
   #include "OS4.h"

                 ...

                 .section pollVectorArea
   deepWake:     n=c
                 ldi     .low12 extensionHandlers
                 gosub   activateShell
                 goto    pollReturn    ; (P+1) failed, not enough memory
                                       ; (P+2) success
   pollReturn:   gosub   LDSST0
                 c=n
                 golong  RMCK10

   ;;; **********************************************************************
   ;;;
   ;;; Poll vectors, module identifier and checksum
   ;;;
   ;;; **********************************************************************

                 .con    0             ; Pause
                 .con    0             ; Running
                 .con    0             ; Wake w/o key
                 .con    0             ; Powoff
                 .con    0             ; I/O
                 goto    deepWake      ; Deep wake-up
                 goto    deepWake      ; Memory lost
                 .con    ...           ; module identifier
                 .con    ...
                 .con    ...
                 .con    ...
                 .con    0             ; checksum position


The routine that sends the message does so using ``sendMessage``, which
takes the message number and optionally some message specific data in
the ``N`` register.

Any called routine can inspect, update or return a value in ``N``. Each
message defines on its own how ``N`` is used. A message handler can
prevent further propagation of the message by popping the return
stack. If further message propagation is desired, then it should not
pop the return stack and also preserve the ``M`` register, as it
contains the shell stack traversal state which is needed to properly
pass it the next handler. In both cases, use ``RTN`` when done, or
exit in some message specific way.

How many subroutine levels you can use depends on the context in which
the message was sent. It is recommended to use as few as possible and
to test it. Basically, if you do not want further message processing,
you know that you gained one level on the stack when the return
address was dropped.

Here is how a ``catHandler`` could look:

.. code-block:: ca65

                 .public catHandler
                 .align  4
   catHandler:   c=n
                 a=c     x
                 ldi     16
                 ?a#c    x             ; cat 16?
                 gonc    doCat16       ; yes
                 c=c+1   x
                 ?a#c                  ; cat 17?
                 rtnc                  ; not one of mine
   doCat17:      ...

   doCat16:      ...

This takes the catalog number from ``N.X`` which is where the ``CAT'``
function places it. If the passed number is not one of mine, we return
to the caller which is the dispatch loop. It will continue scanning
for other catalog handlers. As the scan state is kept in ``M``, we must
not touch it.

The actual catalog implementation should use ``SPOPND``, but it may not
be strictly needed if we never return from the catalog handler code.
A catalog exits via ``QUTCAT`` (quit catalog) which jumps to
``NFRKB`` which is one of the entry points for function return. The
return address will never be used and is going to pushed off the top
of the 4-level return stack at some point in the future.
