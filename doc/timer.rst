**************
Interval timer
**************

.. index:: timer

The interval timer in the Time module can be borrowed by applications
to provide timeouts or recurring timed events, e.g. a clock.

It is primarily intended for transient applications, e.g. waiting for
a fixed amount of time for a key press. Another use is for animating
the display, e.g. to show a blinking cursor. It can also be used to
display periodic updates of some external hardware readouts, like GPS
coordinates or other external measurements.

Starting
========

Use ``setTimeout`` to set the timeout which is a 5 digit BCD
number. The interval timer starts and you will get periodic
notifications with the specified time interval.

Stopping
========

Once you have called ``setTimeout`` it is your responsibility to also
call ``clearTimeout`` to stop the timer.

If you only want a single timeout, you need to call ``clearTimeout``
in your timeout handler which is pointed to from the shell descriptor.

If you have a transient application you also also need to stop the
interval timer when the shell exits. The normal keyboard definition
has a field for this, see see :ref:`auto-terminate-transapps`.
If you are doing your own custom key handling, simply call it from
your key handler.

Timeout
=======

For an application this is an entry in the shell descriptor. As
mentioned, you need to stop the timer when you decide you do not want
any further timeouts with ``clearTimeout``.

Partial key sequence
--------------------

.. index:: timer; partial keys

It is also possible to use a timeout when doing partial key sequence
parsing. A timeout is notified using the backarrow vector. You
can distinguish between a backarrow key press and a timeout by looking
at the sign field of the ``A`` register. This field is set to zero if
the entry was called due to a backarrow key press and is non-zero
if there was a timeout:

.. code-block:: ca65

   entry:        gosub   NEXT2
                 goto    cancel
                 gosub   clearTimeout  ; normal key press, give timer back
                 ...                   ; handle key

   cancel:       ?a#0    s             ; timeout?
                 gonc    abort         ; no
                 ...                   ; timeout specific handling
   abort:        gosub   clearTimeout  ; give timer back
                 golong  XABTSEQ

If you only want a timeout that cancels the key sequence parser you
do not need look for whether it was a timeout. However, you should
call ``clearTimeout`` in both cases.
