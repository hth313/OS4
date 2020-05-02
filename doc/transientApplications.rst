**********************
Transient applications
**********************

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
temporary state storage. There is also support for borrowing the
interval timer from the Time module (if present). This timer is
normally used for the clock display, but thanks to OS4 being in page
4, you can borrow it (when available) from the Time module and use it
for periodic updates or for implementing a timeout.
