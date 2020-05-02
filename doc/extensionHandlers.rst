******************
Extension handlers
******************

Extension handlers implement a generic message system and can be seen
as a more flexible variant of poll vectors. They are descriptors like
shells and are stored in the shell stack. Their structure is however
very different from the shells and they do not participate in key
handling or display the way they other entities do.

Some event is propagated to defined handlers that act on
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

Extension structure
===================

The data structure used by extension points is very different from the
various shells. Only the first identifier word is "shared" with
them. The rest is just a list of the message numbers it will handle
coupled with a pointer to the handler itself.

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
