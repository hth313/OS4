Shells
======

One of the key concepts in OS4 is that of a Shell. A shell is
essentially an extension mechanism for new basic behavior. A behavior
is a new keyboard layout coupled with an alternative display routine.
The keyboard layout replaces the standard keyboard layout and allows
for complete redefinition of keys, using standard functions, XROMs and
even XXROMs. The display routine is what decided to show indstead of
the default, which shows the X register.

Both the keyboard replacement and display routines are optional and
allows for overriding one of them, but keeping the default behavior
for the other.

In some way you can see coupling a new keyboard together with an
alternative display routine as an MCODE application, a replacement
behavior or complete customization.

It is worth pointing out that the keyboard layout is changed much in
the same way as the built-in standard keyboard is defined. It does not
use any user key assignments at all. In fact, you can still put user
key assignments on top of the replaced basic behavior.

Shell stack
-----------

The shells form a stack, so that if you activate a given application
shell it goes on top of the previous behavior. If you activate another
application shell, it will shadow the prior shell. If you exit an
application, the one below (previously active) becomes active again,
all the way down to the standard behavior at the bottom.

Shells kinds
------------

There are four kinds of shells and they have different purposes and
follow somewhat different rules.

Application shells
^^^^^^^^^^^^^^^^^^

The most fundamental shell type is the application shell. They live
near the top of the shell stack. Only one application is consulted for
interpreting the keyboard and using the display routine and that is
the top one. Once an application is at top, it shadows all other
applications, meanaing the applications below the active one are
ignored. They reside in the stack in their activation order to make it
possible to exit a shell and fall back to the previous one.

Transient applications shells
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A variant of an application is a transient application shell. This is
a specialized version of an application that always are at the top of
the stack. A transient application is meant to be used for some
temporary mode that is normally exited when a key not handled by it is
pressed. This is similar to have the original catalog 1-3 act, once
stopped and if you press a key that is not interpreted by the catalog,
the catalog is exited and the key performs its usual behavior. In the
HP-41 the original catalogs and the clock display roughly corresponds
to a transient application. In fact, if the shell mechanism would have
been available at the time, a transient application would most likely
have been used to implement them. As the shell mechanism did not
exist, various tricks were used instead.

A transient application can due to its single and short-lived
existence can easier use various provided resources. There is a
scratch area that can be easily obtained from the system buffer for
temporary state storage. There are also support for borrowing the
interval timer of the Time module. This timer is normally used for the
clock display, but thanks to OS4 being in page 4, we can borrow it
(when available) from the Time module.

System shells
^^^^^^^^^^^^^

The next shell variant is a /system shell/. System shells are always
located below all application shells in the stack. All system shells
are always active in their stack order. They are typically used for
replacing single (or a few) keys, providing alternative or additional
functionality. One example is a replacement for the assign (ASN)
function that could be implemented using a system shell. If the active
application shell pass through the ASN key, the system shells are
consulted in order (after skipping any other application shells in the
stack). The first system shell found that defines the key gets to
handle it. This provides a flexible and extensible mechanism for
redefining keyboard behavior where different handlers do not get into
the way of each other.

Extension handlers
^^^^^^^^^^^^^^^^^^

The final entity that lives in the shell stack are extension
handlers. There are not keyboard handlers as the others, but rather a
message system. Specific events can be routed to listeners and they
may choose to act on given messages. It can prevent further
propagation of a message, or allow it to be also seen by other message
handlers.

You can see extension handlers as a more flexible variant of poll
vectors. Some event is propagated to defined handlers that act on
it. The extension handler mechanism is more flexible in that it can
pass a message specific state in the N register. This can be used for
parameters, some kind of accumulator that is updated by the handlers
and the final state could be a result. A handler can choose to act on
the message so that it is not seen by other handlers, or it may allow
other handlers to also see the message.

This mechanism is a lot more flexible than the poll vectors, but it
comes with a somewhat higher overhead as it needs to scan the stack
and then scan lists for appropriate handlers to call. Compare this to
poll vectors that simple scan a fixed offset on each of the 11 or 12
ROM pages.

This mechanism is used by the extensible catalog mechanism which
allows the same `CAT'` function to pass the catalog number to
handlers. It may provide basic catalog functionality by itself, but a
fictive HP-IL extension mechanism can provide additional catalogs by
listening to the catalog even and see if the catalog number matches
the ones it provides. This would make HP-IL related catalogs available
on the same `CAT'` function, but only when that HP-IL extension module
is plugged in.
Other evens can inform that the shell stack is altered, that `XEQ` is
starting RPN execution in a new location so that any pending returns
addresses on the stack should be cleared. This is done today
internally by the firmware, but there is no way for a module to get
informed about it, as HP never defined a poll vector for such
seemingly specialized event. However, with the more advanced
programming we do today, it may be entirely useful to get such
notifications and the extension handler mechanism makes it possible.

Shell structure
---------------

A shell is defined using a structure with several elements as follows:

.. code-block:: ca65

            .align 4
   myShell: .con    kind
            .con    .low12 displayRoutine
            .con    .low12 standardKeys
            .con    .low12 userKeys
            .con    .low12 alphaKeys
            .con    .low12 appendName

The structure must start on an address aligned by 4. Most of the
elements are also aligned by 4. This is because we are representing a
12-bit page address using a 10-bit ROM word.

Kind field
^^^^^^^^^^

The kind field tells what kind of shell this entry represents. The
values are defined in `OS4.h` and are either `SysShell`,`AppShell` and
`TransAppShell`. The `GenericExtension` also exists, but the fields
following it differs from the application and system shells.

Display routine
^^^^^^^^^^^^^^^

This points to the custom display routine that overrides the default
display of the stack X register. This is called to replace the
built-in provided display of X when appropriate. To get a steadier
display it is recommended that functions you implement in your
application ends by updating the display on their own. To update the
display call the `shellDisplay` routine. This takes care of all
possible situations. For example, if a user program is running, we do
not want to alter the display. The application which your function
belongs to may not be the active one, the user are free to execute any
function regardless of the state of the shell application stack.
may not be the a

Calling `shellDisplay` at the end of your function avoids the flicker
that occurs by first having an incorrect default display of X being
replaced by the desired view. 

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
^^^^^^^^^^^^^

This field points to another structure that defines the keyboard
layout. This keyboard definition is the replaced standard keyboard.

User keys
^^^^^^^^^

This field points to another structure that defines the keyboard
layout. This keyboard definition is the replaced user keyboard.
Normally you will set this to the same value as standard keys.

Alpha keys
^^^^^^^^^^

This field points to another structure that defines the alpha keyboard
layout. If using the default alpha keyboard, set this field to 0.

Name
^^^^

This fields points to a routine that is the the name of the shell
to the display. This is intended to be a short name, usually 3-7
characters.

The intended use of the name field is for being a user friendly text
representation of the shell. A typical use can be in a catalog that
visualizes the shell stack.

Examples
^^^^^^^^

A Time-Value-Money style shell mainly provide a keyboard with some
keys replaced. Its shell definition could look as follows:

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
keyboard in both standard and user mode.


Internal representation
-----------------------

To better understand shells stored in the stack it can be good to
understand how it is represented. A shell consists of seven digits which
means that two shells are stored into a register. The seven digit sequence
can be broken up in three parts.

Address
^^^^^^^

The first 4 digits are the address of the shell structure. This means
that a shell in theory can be located at any address in the 64K memory
space.

Not every address are actually possible. First of all it must be
aligned to an even 4-bit word address. This limitation is imposed by
the API, not the shell descriptor which could actually handle
unaligned addresses. Second, modules can be plugged in and removed,
they may also be moved to a different page while the calculator is
off. To handle this, the page numbers 0 and 1 (which are in the
mainframe OS firmware) have special meaning in the reconfiguration
process when the calculator is turned on, see further below.

Kind field
^^^^^^^^^^

A single digit kind is stored in the descriptor. This is to make it
quicker to categorize shells in the stack without digging into the
actual descriptor structure.

XROM number
^^^^^^^^^^^

The last two digits are the XROM number of the owning module. They
exist to make the descriptor number (more) unique. As modules may be
moved, only the 12-bit page offset is significant to describe a
module, the actual page may change. Adding the XROM ensures that we
can tell two 12-bit page offset in different modules that happen to be
same apart. While in theory you may plug in more than one module with
the same XROM number, doing so results in various problems as is often
avoided. As two such modules also need to define shells that happen to
be in the same offset is highly unlikely. Should it actually happen,
the only consequence is that the order of shells may be affected when
the calculator is turned off, then on.


Activation
----------

Once you have created a shell structure, activating the shell is done
by the `activateShell`. This take a packed pointer to the shell
structure, which is why it needs to be aligned on an even address by
4.

Activation means that it is store on the shell stack at the top
location among existing shells of the same kind. It essentially means
it becomes the first shell to be consulted of its kind.

You can activating a shell multiple times. Doing so means that it will
get moved to become the topmost shell of its kind. In other words, if
you activate an application A and then activate other applications to
shadow application A, activating application A again means it is moved
up ahead of the applications that shadows it, making A the active
applications.

Deactivation
------------

You can exit a shell using the `exitShell` routine. This will
deactivate the shell, bringin any previously shadowed shell in focus
again.

Reclaim at power on
-------------------

Shells go through a process similar to buffers in the HP-41. At power
on they are all marked for removal and it is expected that any plug-in
module that wants its shell to survive a power cycle need to reclaim
it. This is done using the power on poll vector. The `reclaimShell`
routine is used for this purpose.

Application shells
-------------------




Temporary application shells
-----------------------------




Scratch area
------------

Application shells typically need to store some kind of state. The
typical way of doing this is to allocate a buffer. The typical case is
an application which may need to store settings or some extension to
the RPN stack. As there can be multiple applications active in the
shell stack, it makes sense to use a buffer for this purpose.

A temporary application shell is typically a temporary mode, to
display a catalog, some custom input routine or a periodically
updating display mode like a clock. As there can be only one temporary
application active at any time and no stacking behavior is allowed,
using a buffer may feel a but heavy weight. For this situation the
OS4 module provide a temporary scratch area which is held in the
system buffer.

The scratch area can be up to 15 registers large. If a catalog is
implemented using a temporary application shell, it start by running
normally to display the catalog entries. If stopped, the catalog can
return and let the calculator sleep, saving power. However, all CPU
registers may get clobbered and some storage area is needed. This can
be solved using the scratch area and saving the catalog state in it.
An alternative is to use the status area in the lower RAM address
area, but it is pretty much used up by the operating system and it
may be hard to tell what may be safe to use. It is entirely possible
that some device may request the calculator to be waked up and
serviced, invoking poll vectors and it may be hard to tell what area
is safe. The scratch area provides a solution to this with greater
safety.

The downsides of the scratch area are that it needs to allocate
registers from the free area. This has two potential problems, first
there has to be enough registers free, second it will need to shuffle
registers around to open up and later close the scratch area.

If there are not enough registers available, you will need to take
some actions, which in the simplest case will be to bail out, which
typically will be releasing any allocated resources (exiting the
transient application) and exiting via `noRoom`.


System shells
-------------

System shells are intended for tuning the default behavior of the
standard keyboard. Advanced modules from the past like the Zenrom and
CCD used various tricks with the partial key sequence mechanism to
wedge in alternative behavior. Such tricks may result in certain
incompatibilities. Using a system shell provides a cleaner way of
accomplishing some of these extensions. You can for example provide a
new alternative `ASN` or `CAT` functions. It is also possible to add
functionality to "unused" keys, such as shifted USER, PRGM and ALPHA
keys. Functionality such as an alternative CAT may via the extension
point mechanism provide an extensible catalog, allowing other modules
to provide additional catalog functionality.

System shells are stored in the shell stack and are consulted in their
stacking order. This way the one highest up have the highest priority
in case two system shells add functionality to the same key. In
contrast to application shells where the topmost shell is consulted
and the rest are ignored, for system shells are consulted in order
until a shell that handles the key press are found. Thus, system
shells merge their functionality while an application shell shadows
the other applications.



Extension points
----------------

Extension points differ from the other shells in that it does not have
anything to do with providing functionality to keys or a display
routine. Instead it is an event or message system that can be seen as
a very flexible extension of the poll vector mechanism. Compared to
a poll vector, it uses more overhead but is also more flexible.

When a message is passed around the N register may carry a parameter,
a state or be treated as an accumulator (changing value) as it is
passed through the handlers. A handler may optionally continue the
passing or decide it is the endpoint and bypass further message
propagation. 

The data structure used by extension points is very different from the
various shells, only the first identifier word is "shared", the rest
is just a list of the message numbers it will handle coupled with a
pointer to the handler itself.

Extension structure
^^^^^^^^^^^^^^^^^^^

The extension structure is fairly simple:

.. code-block:: ca65
                 .align  4
   extensionHandlers:
                 .con    GenericExtension
                 .con    ExtensionCAT
                 .con    .low12 catHandler
                 .con    ExtensionListEnd

As usual it needs to be aligned. The first word must be
`GenericExtension` to separate it from being some kind of shell.
After this follows pairs of the message identity (number) and its
handler. The table must end with `ExtensionListEnd`.

Using a list means it is only needed for a module to define a single
extension record to save precious RAM space.

Activation of the extension handlers can be done from the deep wake up
poll vector.

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


The routine that sends the message does so using `sendMessage` which
takes the message number and optionally some message specific data in
the `N` register.

Any called routine can inspect, update or return a value in `N`. Each
message defines on its own how `N` is used. The called routine can
prevent further propagation of the message by popping the return
stack. If further message propagation is desired, then do not pop the
return stack and preserve the `M` register as it contains the shell
stack traversal state which is needed to properly pass it the next
handler. In both cases, use `RTN` when done, or exit in some message
specific way.

How many subroutine levels you can use depends on the context in which
the message was sent. It is recommended to use as few as possible and
to test it. Basically, if you do not want further message processing,
you know that you gained one level on the stack when the return
address was dropped. 

Here is how the `catHandler` could look:

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

This takes the catalog number from `N.X` which is where the `CAT'`
command places it. If the passed number is not one handled, we return
to the caller which is the dispatch loop. It will continue scanning
for other catalog handlers and as it keeps its state in `M`, we must
not touch it.

The actual catalog implementation should use `SPOPND`, but it may not
be strictly needed if we never return from the catalog handler code.
That one will likely show the catalog and in the end exit via `QUTCAT`
(quit catalog) which ends by jumping to `NFRKB` which is one of the
entry points for function return. The return address will never be
used and is going to pushed off the top of the 4-level return stack
at some point.




