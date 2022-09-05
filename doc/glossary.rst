********
Glossary
********

.. index:: glossary

.. glossary:: Application

A new environment or mode to make the calculator behave differently.

.. glossary:: Auto assignment

The assignments that are automatically bound to the upper two key
rows. Corresponds to single letter local alpha labels in the current
RPN program.

.. glossary:: Execution token

The byte code(s) that defines a function.

.. glossary:: Extension handler

A message system provided by OS4. Has some resemblance to poll
vectors, but can be defined by application modules.

.. glossary:: FAT

Function address table. Contains pointers to functions. Each entry
uses two words.

.. glossary:: Hosted buffer

A buffer that is contained inside the system buffer.

.. glossary:: ID area

A four word sequence at the end of a module that contains a short
identification of the module. Some bits are used to mark if the module
is banked and if it has secondary functions.

.. glossary:: Mainframe

The name HP used internally for the HP-41 firmware. Normally it means
a very large (and at the time it was modern) powerful computer.

.. glossary:: MCODE

The machine language used on the HP-41. HP originally called it
microcode,  which is misleading as it usually means something
else. The term M-Code was coined in the user community (where the "M"
could refer to either), and later it became MCODE.

.. glossary:: Primary bank

Bank 1 in a banked module.

.. glossary:: Primary function

An ordinary XROM function or a built in function.

.. glossary:: Packed pointer

A single word (10-bit value) that can refer to a location in a 4K
module page. Address alignment (on 4) and a page address value from
some outer context is used to construct a full 16-bit address from
it.

.. glossary:: Poll vectors

A fixed set of locations near the end of a module that are called
(if defined) during certain key system events.

.. glossary:: RPN

Reverse Polish Notation, also called postfix notation. Arguments are
specified before the operation. In this manual also used as the name
for user code program language of the HP-41. Some prefer to call it
FOCAL.

..  glossary:: Secondary bank

Any bank that is not the primary. This is bank 2, 3 or 4 in a banked
module.

.. glossary:: Secondary FAT

A function address table that goes together with a secondary FAT
header. This table may be in any bank.

.. glossary:: Secondary FAT header

A structure that defines a sequence of secondary functions. Multiple
secondary FAT headers can exist as a linked list. Must be in the
primary bank.

.. glossary:: Secondary function

A function that is member of a secondary FAT.

.. glossary:: Semi-merged

A program step that is actually two. The first is an XROM function and
the second is a text literal that gives extra information to the
previous step. The first step is displayed fully decorated based on
the extra information in the text literal. The full decoration is the
"semi" part.

.. glossary:: System buffer

The buffer OS4 uses to store its state. Uses buffer identity 15.

.. glossary:: System shell

Typically used for add-on keyboard modifications that can update
keyboard behavior and be active at all time.

.. glossary:: Transient application

A temporary mode similar to a catalog or updating clock display.

.. glossary:: XADR

The first execution address in a function.

.. glossary:: XKD

Execute direction function. If bound or assigned to a key, it executes
on key press down (without NULL test).

.. glossary:: XXROM function

A secondary function. The XXROM is similar to XROM and is displayed
when it belongs to a module that is not plugged in.
