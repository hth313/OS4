************
Applications
************

.. index:: shells; applications

An application is a replacement for behavior, which typically includes
modifications to the keyboard and the display behavior. You can see it
as an alternative mode or working environment.

The HP-41 already contains alternative modes, such as the catalogs
and the clock display.
Applications as defined here are more formalized compared to the
application like behaviors that already exist in the HP-41, which
rely on flag settings and various ad-hoc tests.

Technically an application is described by a half register (28 bits)
descriptor that is stored on the shell stack kept inside the system
buffer. This descriptor identifies and points to a structure (a
sequence of words) in the application module. Activating an
application is done by pushing its descriptor onto the shell stack,
making it the active application.
This descriptor is used for finding keyboard and display handlers
related to the application, allowing it to define the behavior.

A properly defined application allows for overriding all relevant
functionality, while retaining existing behavior that is deemed useful
to complement the mode. Thus, you can replace the keyboard to allow
for working with complex numbers directly, while still being able to
edit and execute programs as usual.

In other words, applications allow you to alter fundamental behavior
while preserving the overall HP-41 experience.

Exiting
=======

.. index:: shells; exiting

It is recommended that exiting an application shell is done with an
``EXITAPP`` function implemented as follows:

.. code-block:: ca65

                 .name   "EXITAPP"
   EXITAPP:      golong   exitApp

It should be bound to the shifted USER key on an application
keyboard. The idea is that the USER key is related to keyboard behavior
and it not previously bit used for anything.

Default display
===============

.. index:: shells; default display, display; default

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
the standard display. As this takes a short moment, the standard X
value is shown briefly. The effect is display flicker.

Reducing flicker
----------------

.. index:: reducing flicker, display; reducing flicker

It is possible to reduce the flicker by having your function exit via
OS4. This will cause the default application display to be shown and
the message flag is automatically set, blocking the default display
of X, the result is no flicker.
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
   function is XKD or during data entry).

To reduce flicker you want to call the ``shellDisplay`` routine before
exiting back to mainframe. There are also a couple of useful entry
points ``XNFRPU`` or ``XNFRC`` which calls ``shellDisplay`` before
going to the corresponding return point in mainframe.

.. note::

   It is not a good idea to update the display of your own without the
   control of OS4. The ``shellDisplay`` routine takes the current
   active application in account, which may not be the same as the one
   the function just executed belongs to. This is possible as the user
   may just have executed your function from the keyboard while
   having another shell active.

More about the message flag
---------------------------

.. index:: message flag

The message flag is actually given a somewhat new meaning when used
this way to reduce flicker. It is actually set when showing an
alternative default display for the application and not a message.
This is in most situations not a problem, but it matters with the
backarrow key. Pressing the backarrow key have different meanings
depending on the state of the calculator. If a message is shown
backarrow removes the message and reverts back to the default
display. If a message is not shown, it acts as clear the X register
and disable stack lift.

We can get this behavior in the application, but it requires that we
actually know if a message is being shown or the message flag is
borrowed for altering the default display of X. Looking at the message flag
alone is not enough to tell this. OS4 provides a routine
``displayingMessage`` for this purpose which answers the question.

In your own ``CLX`` style routine (bound to the backarrow key) you can
use it as follows:

.. code-block:: ca65

                 .name   "CLX'"
   CLX':         gosub   displayingMessage
                 goto    showX         ; (P+1) clear shown message
                 s11=0                 ; disable stack lift
                 ....                  ; clear X


Stack lift
==========

.. index:: stack lift

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

This way we set the push flag late and get a sensible default, which is
to enable stack lft. However, it is easy to forget about it and just do a
``RTN`` when leaving the push flag in the same state would have been
more appropriate.

While this is the recommended way, it is possible to revert the logic
and set the push flag early and always exit by not touching it. This
may make sense if you have support routines to bring up your internal
environment as well as an elaborate exit. Still, it can be a good
idea to consider doing the "normal" way as it makes the overall code
base more uniform with everything else.

In any case, it can be a good idea to actually test the stack lift
behavior of your functions. This is after all a much forgotten detail. The
Ladybug module contains test code that inspects the behavior of the
push flag for its functions. The HP-41 manuals also specifies in great
detail how functions affect (or not) the stack lift flag.

Data entry
==========

.. index:: flag; data entry, data entry flag

If you application handles numeric data entry in a non-standard way,
you need a flag for telling if such data entry is active. The system
defines flag 45 for this. You need to share this flag with the system
as the Time module may reset this flag due to an alarm.

It is not entirely unlikely that your own environment has its own set
of flag and accessing system flag 45 may be awkward. In such case it
can be a good idea to copy this particular flag to the CPU flag
register together with your own mode flags. The Ladybug does it this
way by copying the system data entry to a local flag when entering its
data entry code. The internal flag is then written to the system flag
before giving control back.
