**********************
Transient applications
**********************

.. index:: shells; transient applications, transient applications

A transient application is a variant of an application that is meant
to be somewhat short lived. If you think about the original catalogs
(1--3) and the clock display, then you get an idea of what a transient
application is.

When a catalog or the clock is active, pressing a key that is not
handled by it terminates the mode and then the key press outside
the mode is interpreted.

If the shell mechanism would have been available at the time when the
catalog or clock was implemented, a transient application might
have been used. As the shell mechanism did not exist, various
other tricks were used instead.

A transient application may use various additional resources thanks to
its single and short-lived existence. There is a
scratch area that can be easily obtained from the system buffer for
temporary data storage. There is also support for borrowing the
interval timer from the Time module (if present). This timer is
normally used for the clock display, but as OS4 is in page
4 you can borrow it from the Time module and use it for periodic
updates or to implement a timeout.

Properties
==========

Transient applications have certain properties that set them apart
from other applications:

1. They are not sticky. Instead they are easy to get out of, typically
   by pressing the back-arrow key or just any key that is not defined by it.

2. They do not stay active if the power is cycled.

3. The ability to use additional resources, like the scratch area and
   timer, as mentioned above.

Creation
========

A transient application is defined mostly in the same way as an
application. Use the ``TransAppShell`` kind instead of ``AppShell``.

Termination
===========

Transient applications normally auto terminate when a key not handled
by it is pressed. For this to work with a defined keyboard you need to
set the ``KeyFlagTransientApp`` bit and also define the termination
slot, see :ref:`auto-terminate-transapps`.

If you are using your own custom keyboard handler (instead of
``keyKeyboard``), you need to remove
the shell yourself by calling ``exitTransientApp``.


Ideas
=====

To give a better idea about what you can do with the transient
application mechanism, we will look at some examples without going too
much into details.

Catalogs
--------

.. index:: catalogs

The catalog key can be replaced using a system shell. The catalog
itself can be implemented as a transient application when the catalog
is stopped and waiting for key input. This allows the calculator to go
to light sleep when the catalog is stopped (while staying active). It
also allows for terminating the catalog on a key press not defined by
it, very much like the built in original catalogs 1--3.

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

Waiting for key input in response to a menu and dispatching on
it on behalf of an RPN program could be another way to use for a transient
application. Think of it as a variant of the top row auto-assignments,
but with better control.

You could also use it for timed input, like ``GETKEY`` or ``GETKEYX``,
without having to busy wait. The timeout can be controlled by the
interval timer.

Scratch area
============

.. index:: scratch area

Application shells may need to keep a state. The normal way
of doing this is to allocate a buffer. The typical case is an
application which may need to store settings or keep some extension to
the RPN stack. As there can be multiple applications active in the
shell stack, it makes sense to use a buffer for this purpose.

A temporary application shell is typically a temporary mode and as
there can be only one such temporary application active at any time,
a buffer may be a bit overkill. For this situation the
OS4 module provides a temporary scratch area in the system buffer.

The scratch area can be up to 15 registers. If a catalog is
implemented using a temporary application shell, it starts by running
normally displaying the catalog entries. When stopped, the catalog can
push a transient shell and let the calculator go to sleep, thereby
saving power. However, all CPU registers may get clobbered and some
storage area is needed to preserve the state. This can be solved by
storing the state in the scratch area.
An alternative is to use the status area in the lower RAM address
area, but it is pretty much used up by the operating system and it
may be hard to tell what is safe to use. It is entirely possible
that some device may request the calculator to be waked up and
serviced, invoking poll vectors without being noticed, it may be
hard to tell what area is really safe. The scratch area provides a
solution to this problem.

The downside of the scratch area is that it needs to allocate
registers from the free area. This has a potential problem, as there
has to be enough registers free, causing it to fail.

If there are not enough registers available, you will need to take
some actions, which in the simplest case will be to bail out,
releasing any allocated resources (exiting the transient application)
and perhaps exit via ``noRoom`` to display an error message.
