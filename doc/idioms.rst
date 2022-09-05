****************
Idioms and ideas
****************

Programming idioms are ideas and snippets of code on how to solve
typical problems. Knowing and following idioms will help you in
writing good code by levering existing experience. Idioms will help
you understand how to approach typical problems, and by using them it
makes your code easier to read by other people. However, you should not take
idioms presented here as the whole truth. Feel free to invent your own
and explore MCODE with an open mind. They are just some good ideas on
which you can base your own code on. If you feel that you  want to do
it in different ways, by all means do so.


Error returns
=============

.. index:: error returns

Often we want to tell whether a routine succeeded or if there was an
error. When we want to report an error we can use one of the error
exit routines provided by mainframe. Such exits are ``ERRDE`` for
showing ``DATA ERROR``, and some other routines for the other standard
error messages. OS4 also provides some additional error handler
routines with additional messages.

A routine typically becomes more flexible if it does not exit with an
error message, but rather returns in a way to signal an error,
delegating the error handling to the caller. This makes the routine
more flexible as a caller can take other actions on the error
condition than just exiting with an error message.

We can return an error value, like zero which is easy to
test for by the caller. On the Nut CPU there is an alternative idiom by
returning to a different location depending on whether there was an
error or success (or even different classes of results). This is
somewhat unusual, but works exceptionally well on the Nut instruction
set for two reasons. First, almost all instructions are of the same size (one
word). Second, it is is very easy to handle returns to different
locations. A simple return is just the ``RTN`` instruction, or one of the
conditional ``RTNC`` or ``RTNNC`` instructions. Returning to an incremented
location is also very simple as shown below.

If we want to return back that we failed, we return to something
called ``(P+1)``. This is fancy for doing a normal return to the
instruction following the call instruction. If we
succeed, we return to ``(P+2)``, which means that we skip past the
normal return address by one.

What it means is that a caller may look as follows

.. code-block:: ca65

   locateBuffer: ldi   2         ; buffer number
                 gosub findBuffer
                 goto  noBuf     ; (P+1) deal with that no such buffer exists
                 ...             ; (P+2) success, we found buffer 2 (we probably also
                                 ;       got some pointer back and the header selected)


In the actual ``findBuffer`` routine, we test for various error
conditions, such as if running out of the buffer area or finding the
permanent ``.END.``. In such cases we can do a test and conditionally
return, which will take us to ``(P+1)`` of the caller:

.. code-block:: ca65

   findBuffer:   ...
                 ?a<c    x             ; have we reached chain head (.END.)?
                 rtnnc                 ; yes, not found
                 ...
                 ?c#0                  ; empty register?
                 rtnnc                 ; yes, not found


When we find what we are looking for, we want to return to ``(P+2)``,
which is done by incrementing the return address.
This is done in the following way:

.. code-block:: ca65

   RTNP2:        stk=c                 ; C[6:3]= return address
                 c=c+1   m             ; advance to (P+2)
                 gotoc                 ; return

The ``GOTOC`` instruction is very useful here as it simply loads the
program counter with ``C[6:3]``, meaning we take the address field of
C and load it to PC, which is exactly what we want to do here.

As can be seen, a single conditional ``RTN`` instruction can handle errors,
and a short three word sequence will allow us to return to ``(P+2)``. On the
caller side, a short branch (``GOTO``) will take us somewhere to
deal with the error condition. There are no error value or flags
passed back, nor any tests needed at the call site. It gets very small
and simple.

It is not known who came up with this trick first, but it is used
extensively in the Time module. You will find code in the mainframe
that does not employ this technique, but rather returning 0 or setting
a flag (as in the HP-IL module).

The main advantage of the return to different locations idiom is that
it saves an instruction on each call site. It often simplifies the
routine returning the error result as well.

A disadvantage is that you need to act on the condition immediately.
Another problem is that you cannot use the ``C[6:3]`` field to carry
any return value.

Call backs
==========

.. index:: call backs

A similar technique can be used for implementing call backs. We can
make a call and keep a call back pointer at ``(P+1)``. In fact, we
can easily have multiple call backs by just adding additional return
locations.

.. code-block:: ca65

                 gosub routine
                 goto  handler1 ; (P+1) first call back
                 goto  handler2 ; (P+2) second call back
                 ...
                 xxx             ; (P+N) normal return


                 ...

    handler1:    do-stuff ...
                 rtn


The called ``routine`` can then pop the return address and keep it
handy in for example ``M``.

.. code-block:: ca65

   routine:      c=stk
                 m=c        ; M[6:3]= points to callBack1

Later we can call a routine using:

.. code-block:: ca65

                 ...
                 gosub  callBack2


   callBack2:    c=m
                 c=c+1  m
                 gotoc

Here we make use of having the base call back pointer in
``M[6:3]``. Note that it trashes part of the C register. However,
making a page relative call (3-word pseudo call) also destroys most of
the C register.

The final return from ``routine`` is made by jumping back to its
``callBackN`` routine.


Code pointers
==============

.. index:: packed pointers, pointers; packed

As a ROM word is only 10 bits long and we lack a few bits to make
a full 16-bit code pointer. Instead of using two words, we can get
away with only using 10 bits by observing two things.

First, the code that are providing the code pointer is in a page
relocatable module. Normally, we do not know which page we will be
executing from. This can be found at run-time using the ``PCTOC`` in
the operating system. In practice, it is often easier to leave it to
the called routine to figure the page address out (as it has the
return address pointing to it on the stack).

Second, with the page sort of taken care of, we have 12 bits to represent
using 10 bits. We can do this by aligning the code so that the
address we want to pass on is aligned to an even 4-word address.

To summarize, we can represent a 4K page local pointer using 10 bits
(a single ROM word) and have it page relocatable. The only thing the
caller need to do is to ensure it is alignment on an even 4-word
address which is easy to do with an assembler directive. For a caller
it would look as follows:

.. code-block:: ca65

                 ldi  .low12 label
                 gosub routine

                 ...
                 .section code
                 .align   4
   label:

On the receiver side we need to construct the full address from the 10
bit data in ``C[2:0]``. We can get the page from the return address
and we need to scale ``C[2:0]`` as follows:

.. code-block:: ca65

   unpack:       c=c+c   x
                 c=c+c   x      ; C.X * 4
                 c=stk          ; C[6]= page
                 stk=c
                 csr     m
                 csr     m
                 csr     m      ; C[3:0]= full address
                 rcr     -3     ; C[6:3]= full address

The only minor issue is how to combine the page with the lower 12
bits. This depends a little bit on how we are given the lower part and
what we want to do with the result. The above code can serve as an
example, but there may be other ways depending on the circumstances.


Call backs with code pointers
=============================

.. index:: call backs

The call backs presented above used ordinary ``GOTO`` instructions in
a similar fashion as what was done with error returns. As the ``GOTO``
instruction only reaches 63--64 words distance, having a couple of
routines may result in that some ``GOTO`` may be out of range.

There is nothing that says that the ``(P+N)`` words need to be
``GOTO`` instructions. We could actually use 10-bit code pointers
instead and have reachability anywhere in the 4k page (given that we
align our call backs).

Our invocation of routine would then become:

.. code-block:: ca65

                 gosub routine
                 .con  .low12 handler1 ; (P+1) first call back
                 .con  .low12 handler2 ; (P+2) second call back
                 ...
                 xxx                   ; (P+N) normal return

                 ...

   handler1:     do-stuff ...
                 rtn

The start of the routine looks as before, as we still want to keep
track of the ``(P+1)`` pointer, it is just what is stored at those
addresses that changed, not the ``(P+1)`` itself.

.. code-block:: ca65

   routine:      c=stk             ; get (P+1)
                 m=c               ; M[6:3]= pointer to (P+1)

                 ...
                 gosub callBackAdr2

What is different is the actual call back helper. Here it is named
differently to distinguish it from the previous, as we may want to
have both variants around.


.. code-block:: ca65

   callBackAdr2: c=m
                 c=c+1  m
                 cxisa
                 c=c+c  x
                 c=c+c  x
                 csr    m
                 csr    m
                 csr    m
                 rcr    -3
                 gotoc


Optional call backs
--------------------

.. index:: call backs

We may want to have optional code pointers. That is, the caller may not
need to provide a call back at all. This can be done in a couple of
ways. We can either read the word and test it for 0. Such value is
easy to test for and cannot be legal anyway as it would take us to the
first address of the page where there is data (XROM identity and FAT):

.. code-block:: ca65

   callBackAdr2: c=m
                 c=c+1  m
                 cxisa
                 ?c#0   x    ; does it exist?
                 rtnnc       ; no
                 ...         ; yes


The alternative would be to store a real pointer that points to a
``RTN`` instruction. We can then omit the 2 words to test above, but
on the other hand we would need to provide a ``RTN`` instruction that
is aligned, so the savings are neglectable. In this case it is a
matter of taste, and having 0 as empty value is easier for the user
and is perhaps somewhat more natural.


Combined call backs
-------------------

.. index:: call backs

While the call back routine is not large, it is not trivial either. We
want to avoid code duplication so it may be a good idea to arrange
these routines together so that they can share code:

.. code-block:: ca65

   callBackAdr1: c=m
                 goto   callBackAdr0
   callBackAdr2: c=m
                 goto   callBackAdr1
   callBackAdr3: c=m
                 goto   callBackAdr2
   callBackAdr4: c=m
                 c=c+1  m
   callBackAdr2: c=c+1  m
   callBackAdr1: c=c+1  m
   callBackAdr0: cxisa
                 ?c#0   x
                 rtnnc
                 c=c+c  x
                 c=c+c  x
                 csr    m
                 csr    m
                 csr    m
                 rcr    -3
                 gotoc

As can be seen, the cost for an additional ``(P+N)`` routine is three
words. One word to add one more to the address and two words to
create the ``(P+N-1)`` entry point.
