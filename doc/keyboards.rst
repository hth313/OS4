.. _defining-keyboards:

******************
Defining keyboards
******************

.. index:: keyboards; defining

In this chapter we will look at how to define keyboards. A keyboard is
essentially a mapping of a key code to a function. The key code is in
0--79 form, which means that we transform a key press to an index
starting from 0 and ending with 79. There are no gaps in this
sequence, so it can become a simple array lookup.

OS4 allows for two ways to define a keyboard. By using a full
definition of all 80 keys or a linear search table.

Defining a key
==============

The function that is bound to a key is described by a single ROM word.

The built-in keyboards only need to access functions that are
built-in, there are no XROM or XXROM functions on these keyboards. For
our purposes we want to be able to also use such functions on our
keyboards.

As with the built-in keyboards, a single ROM word is used to describe
the function bound to a key. In order to cover XXROM function an
extension record is also used.

The function value 0 means that the key is not defined by this
keyboard. Scanning to the end of a linear table without find the key
definition also means it is not defined. An undefined function means
that we should keep searching through remaining system shells in the
shell stack, eventually reaching the internal base definition.

As with the built-in keyboards, we use the upper two bits in the
10-bit word to classify the key as follows:

0. XROM function (1--63), XXROM if 64--255
1. Digit entry
2. Built-in function, ending data entry
3. Built-in function, not ending data entry

As the value 0 means the key is not defined, the XROM function with
identity 0 is not possible to bind to a key. This is normally the XROM
header, which you may use for special purposes but it cannot be bound
to a custom keyboard.

For XXROM functions the stored value (64--255) describes the XXROM
function. As this range is way too short (there can be 4096 XXROM
identities), it points to an extension word:

.. code-block:: ca65

   keyTable:     ...
                 .con    64 + keySecondary - .
                 ...

   keySecondary: .con    0            ; secondary (range 0-1023)
                 .con    offsetFAT1 + (myEntryFAT1 - FAT1Start) >> 1

The value stored is 64 plus the forward offset to the extension record
which consists of two words.

The first word is normally 0 for a secondary function. The second word
is the function number of the secondary function (0--1023).

The calculation above uses various labels where the ``offsetFAT1``
value is the first function number in a specific secondary FAT table
while ``myEntryFAT1`` and ``FAT1Start`` are labels inside that FAT
that instructs the assembler to calculate the desired function number.

.. note::

   If you wonder about the offset calculation, the dot is just the
   current location counter. This makes it easy to calculate the
   distance to the extension record and by adding 64 we tell OS4 it is
   an extension record.

If you actually need to use secondary functions above 1023 you need to
store the upper two bits in bit 7 and 6 of the first word:

.. code-block:: ca65

   keySecondary: .con    ((offsetFAT1 + ((myEntryFAT1 - FAT1Start) >> 1)) & 0xc00) >> 4
                 .con    (offsetFAT1 + ((myEntryFAT1 - FAT1Start) >> 1)) & 0x3ff


The extension record can also describe an arbitrary two byte function,
which makes it possible to bind an XROM function of another module or
a synthetic function such as ``RCL M`` to a key. In this case the
upper two bits in the first extension word must be non-zero to mark
that it is a two byte function:

.. code-block:: ca65

   rcl_M:        .con    0x300 + 0x90  ; RCL
                 .con    0x75          ; postfix M
   XROM_20_01:   .con    0x300 + 0xa5  ; XROM 20-23
                 .con    0x01          ; function 1 in XROM 20

Sparse keyboard tables
======================

.. index:: keyboards; sparse

Sparse keyboard tables are useful when only a few keys are
defined. They are just a simple linear search table where each entry
is a key code (0--79 form) followed by its function definition.

As usual you need to align the table as it will be pointed to from another
record using a packed pointer. The table also needs an end marker where
the upper bits in the word is set:

.. code-block:: ca65

                 .section table, rodata
                 .align  4
   sysKeyTable:  .con    11            ; CAT key
                 KeyEntry myCAT
                 .con    18            ; XEQ key
                 .con    64 + xeqSecondary - .
                 .con    26            ; ASN key
                 KeyEntry myASN
                 .con    0x100         ; end of table


Full keyboard tables
====================

.. index:: keyboards; full

A full keyboard defines all 80 keys using an array. This is done very
similar to how the built-in keyboard are defined, but we use OS4 style
function definitions:

.. code-block:: ca65

                 .section KeyTable, rodata
                 .align  4
   keyTable:
                 ;; Logical column 0
                 .con    0x10a         ; SIGMA+  (A digit)
                 .con    0x10f         ; X<>Y    (F digit here)
                 .con    BuiltinKeyKeepDigitEntry(0x0e) ; SHIFT
                 KeyEntry ENTERI       ; ENTER^
                 KeyEntry SUB          ; -
                 KeyEntry ADD          ; +
                 KeyEntry MUL          ; *
                 KeyEntry DIV          ; /

                 ;; Logical column 0, shifted
                 KeyEntry SL           ; SIGMA+
                 KeyEntry SWAPI        ; X<>Y
                 .con    BuiltinKeyKeepDigitEntry(0x0e) ; SHIFT
                 .con    0             ; CATALOG
                 KeyEntry CMP          ; -
                 KeyEntry TST          ; +
                 KeyEntry DMUL         ; *
                 KeyEntry DDIV         ; /

                 ;; Logical column 1
                 .con    0x10b         ; 1/X  (B digit)
                 KeyEntry Hex          ; RDN
                 .con    0             ; XEQ
                 .con    0             ; right half of enter key
                 .con    0x107         ; 7
                 .con    0x104         ; 4
                 .con    0x101         ; 1
                 .con    0x100         ; 0
                 ...

Anonymous keys
==============

.. index:: keyboard; anonymous XKD

For catalogs and other transient applications you may want to have
special functions only available in that mode. Typical examples are
single step, start running the catalog and perhaps some special
functions available only inside that transient application.

Naming that function and allocating an XROM or XXROM for it may seem
like a lot of overhead. OS4 provides a way of creating anonymous
execute direct functions that are only present inside that mode.

From the user point of view, it works like any execute direct
function, or special key press, e.g. pressing the "C" key to clear the
current entry in a busy waiting catalog. In both cases, there is no
preview of the function and it is not programmable.

.. note::

   In the built in catalogs 1--3 this is handled by execute direct
   functions like ``SST``. For busy waiting catalogs 4-6 it is a
   simple key dispatch loop without any real function. The user
   experience of them are essentially identical even though they are
   implemented in very different ways.

OS4 provides a way to generate a special execute direct function form
that are well suited for this purpose. They only work with sparse keyboards,
which is not a huge limitation as such transient applications
typically only binds perhaps 5-10 functions. Here is an example of how
a catalog keyboard can look like:

.. code-block:: ca65

                 .section table, rodata
                 .align  4
                 .public keyTableCAT7
   keyTableCAT7: .con    40            ; SQRT
                 .con    KeyXKD
                 .con    66            ; SST
                 .con    KeyXKD
                 .con    74            ; BST
                 .con    KeyXKD
                 .con    67            ; <-
                 .con    KeyXKD
                 .con    55            ; R/S
                 .con    KeyXKD
                 .con    2             ; Shift
                 .con    0x30e
                 .con    10            ; Shifted shift
                 .con    0x30e
                 .con    70            ; User
                 .con    0x30c
                 .con    78            ; Shifted user
                 .con    0x30c
                 .con    0x100         ; end of table

                 ;; The XKD pointers
                 .extern CAT7_Clear, CAT7_SST, CAT7_BST, CAT7_BACKARROW, CAT7_RUN
                 .con    .low12 CAT7_Clear
                 .con    .low12 CAT7_SST
                 .con    .low12 CAT7_BST
                 .con    .low12 CAT7_BACKARROW
                 .con    .low12 CAT7_RUN

All such functions have the special value ``KeyXKD`` and the key table
is immediately followed by a table of packed pointers to the key
handler routines. The OS4 key table scanner simply counts the number
of ``KeyXKD`` values seen while scanning the table. If the key pressed
is ``KeyXKD``, the accumulated count is added to the start of the
execute direct pointer table to determine the correct handler.
Thus, there are no padding or gaps in the execute direct table in case
there are "real" functions intermixed in the sparse key table.

.. note::

   The reason why this only works for sparse key tables are
   twofold. First, the ``KeyXKD`` value is 0, which is already taken
   for meaning an empty key in a full keyboard. Second, the following
   table relies on that we have visited all entries before it. Doing
   something similar on a full keyboard would either means that we
   would need to scan the up to 80 entries long table, or have a
   second table of the same size, which would be rather wasteful. It
   is also typical that transient applications where this is useful
   only defines a small number of keys.
