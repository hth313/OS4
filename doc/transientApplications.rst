**********************
Transient applications
**********************

.. index:: shells; transient applications, transient applications

A transient application is a variant of an application that is meant
to be somewhat short lived. If you think about the original catalogs
(1--3) and the clock display, then you get an idea of what a transient
application is.

When a catalog or the clock is active, pressing a key that is not
handled by it terminates the mode and interprets the key press as if
you had not been in that mode.

If the shell mechanism would have been available at the time when the
catalog or clock was implemented, a transient application would most
likely have been used. As the shell mechanism did not exist, various
other tricks were used instead.

A transient application can thanks to its single and short-lived
existence use various additional resources. There is a
scratch area that can be easily obtained from the system buffer for
temporary data storage. There is also support for borrowing the
interval timer from the Time module (if present). This timer is
normally used for the clock display, but thanks to OS4 being in page
4 you can borrow it (when available) from the Time module and use it
for periodic updates or for implementing a timeout.

Properties
==========

Transient applications have certain properties that sets them apart
from applications:

1. They are not sticky, instead they are easy to to get out, typically
   by pressing the back-arrow key or just any key not defined by it.

2. They do not stay active if the power is cycled.

3. The ability to use special resources. As there can only be one that
   takes precedence over everything else, it is possible to use the
   shared scratch storage area (like an anonymous buffer) or the
   interval timer.

Ideas
=====

To give a better idea about what you can do with the transient
application mechanism, we will look at some examples without going too
much into details.

Catalog
-------

.. index:: catalogs

The catalog key can be replaced using a system shell. The catalog
itself can be implemented as a transient application when the catalog
is stopped and waiting for key input. This allows the calculator to go
to light sleep when the catalog is stopped while staying active. It
also allows for making a key pressed that is not defined by the
catalog, to terminate the catalog and have the handlers in the shell
stack handle it, very much like the built in original catalogs
(1--3).

Periodic display
----------------

.. index:: display; periodic update

The clock is a good example of this. We can show an updating time
display which is terminated whenever a key is pressed. Another way
would be to periodically show a changing value obtained from some
external hardware, like a GPS or a multi-meter.

Custom input
------------

.. index:: custom input, input; custom

Waiting for key input in response to a menu and perhaps dispatching on
it in an RPN program could be another way to use for a transient
application. Think of it as a variant of the top row auto-assignments,
but with better control.

You could also use it for timed input, like ``GETKEY`` or ``GETKEYX``,
without having to busy wait. The timeout can be controlled by the
interval timer.

Scratch area
============

.. index:: scratch area

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
