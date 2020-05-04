.. _defining-keyboards:

******************
Defining keyboards
******************

In this chapter we will look at how to define keyboards. A keyboard is
essentially a mapping of a key-code to a function. The key-code is in
0--79 form, which means that we transform a key press to an index
starting with 0 and ending with 79. There are no gaps in this
sequence, so it can become a simple array lookup.

OS4 allows for two ways to define a keyboard, by using a full
definition of all 80 keys or a linear search table.

Defining a key
==============

The function that is bound to a key is described by a single ROM word.

The built-in keyboards only need to access functions that are
built-in, there are no XROM or XXROM functions on these keyboards. For
our purposes we want to be able to also use such functions on out
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

The ``offsetFAT1`` value is the function number of the first secondary
function in that secondary FAT. Using a couple of labels, one at the
entry (``myEntryFAT1``) and one at the start (``FAT1Start``) we can
use the assembler to calculate the correct index of the function.

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

Sparse keyboard tables are useful when only a few keys are
defined. They are just a simple linear search table where each entry
is a key code (0--79 form) followed by its function definition.

You will need to align the table as it will be pointed to from another
record using a packed pointer. It also need an end marker where
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
