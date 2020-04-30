************
Applications
************

An application is a replacement for behavior, which typically includes
modifications to the keyboard and the display behavior. You can see it
as an alternative mode or working environment.

The HP-41 already contains alternative modes, such as the catalogs
and the clock display.
Applications as defined here are more formalized compared to the
application like behavior that already exists in the HP-41, which
rely on flag settings and various ad-hoc tests.

Technically an application is described by a half register (28 bits)
descriptor that is stored on the shell stack kept inside the system
buffer. This descriptor identifies and points to a structure (a
sequence of words) in the application module. Activating an
application is done by pushing its descriptor onto the shell stack,
making it the active application.
This descriptor is used for finding keyboard and display handlers
related to the application, allowing it to control the behavior.

A properly defined application allows for overriding all relevant
functionality, while retaining existing behavior that is deemed useful
to complement the mode. Thus, you can replace the keyboard to allow
for working with complex numbers directly, while still being able to
edit and execute programs as usual.

In other words, applications allow you to alter fundamental behavior
while preserving the overall HP-41 experience.

Exiting
=======

It is recommended that exiting an application shell is done with an
``EXITAPP`` function implemented as follows:

.. code-block:: ca65

                 .name   "EXITAPP"
   EXITAPP:      golong   exitApp

It should be bound to the shifted USER key on an application
keyboard. This as the USER key is related to overall keyboard behavior
and it not previously unused for anything.

Default display
===============

Your application may have the notion of a "default display", which
replaces the normal display of the X register.

The application has a pointer to its display routine that is used to
display its corresponding default X value. You can decorate or render
the display in any way that is suitable.

All functions that are executed returns to mainframe to allow the
calculator do the next action. If you are not running a program,
displaying a message or entering a multi-key sequence, the default
display of X is done. As we cannot alter the built-in behavior, the
standard X value is displayed. OS4 will kick in shortly after it and
call the display handler of the current application, which replaces
the standard display. As this take a very short moment, the standard X
value is very briefly shown. The effect is basically a brief display
flicker.

Function return
---------------

It is possible to reduce the flicker by having your function exit via
OS4. This will cause the default application display to be shown and
the message flag is automatically set, blocking the default display
of X. The effect is no flicker at all.

However, there are many existing functions in the HP-41 that are not
aware of OS4, so flicker will sometimes occur, but the overall
experience is much better as it happens occasionally rather than all
the time.

Normally an MCODE function returns to mainframe with the ``RTN``
instruction. There are exceptions to this:

1. You used up all four stack levels so the return address to
   mainframe is no longer on the stack.
2. You want to return using an alternative way, typically ``NFRC``
   (when you do not want to set the push flag) or ``NRFKB`` (when the
   function is XKD or during digit entry).

When using an application the default X display is shown on return to
mainframe. If your application defines an alternative routine to show
X, it will be executed after the default X is shown. This causes some
brief flicker that you may want to avoid. This can be done by showing
the default display before really exiting back to mainframe. The
``shellDisplay`` routine does this, but you may prefer jumping to
either  ``XNFRPU`` or ``XNFRC`` which calls ``shellDisplay`` before
going to the corresponding return point in mainframe.

.. note::

   It is not a good idea to update the display of your own without the
   control of OS4. The ``shellDisplay`` routine takes the current
   active application in account, which may not be the same as the one
   the function just executed belongs to. Even if you are doing your
   own function, the user may just have executed that function from
   the keyboard while having another shell active!

If you exit back the usual way using ``RTN``, the X is briefly shown
before the display is replaced by the current desired look. It is
impossible to avoid this in every situation as many functions are not
written with applications in mind, they just exit the usual way, which
still works, but with some minor display flicker. Using the
``shellDisplay`` routine whenever possible provides a more pleasant
user experience as the amount of flicker is reduced.

Stack lift
==========

You may want to mimic the behavior of the push flag, or stack lift
disable (``ENTER`` and ``CLX`` functions) for your own environment.

The normal way this is implemented is to have functions to return to
``NFRPU`` which always enables stack lift. The few functions that does
not do this (``ENTER`` and ``CLX`` replacements) need to clear this
flag and exit to ``NFRC`` instead. Functions that want to leave this
flag untouched should also exit to ``NFRC`` and leave the push flag
untouched.

.. note::
   ``NFRPU`` is pushed on the stack before a function is given
   control, so you can often end your function with a ``RTN``
   instruction.

This way we set the push flag late and get a sensible default, it is
normally enabled. However, it is easy to forget about it and just do a
``RTN`` when leaving the push flag in the same state would have been
more appropriate.

While this is the recommended way, it is possible to revert the logic
and set the push flag early and always exit by not touching it. This
may make sense if you have support routines to bring up your internal
environment as well as more elaborate exits. Still, it can be a good
idea to consider doing the "normal" way as it makes the overall code
base more uniform with everything else.

In any case, it can be good to have tests of stack lift behavior for
your application. This is after all a much forgotten detail. The
Ladybug module contains test code that inspects the behavior of the
push flag for its functions.
