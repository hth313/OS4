# OS4 API update log

## API version 1

API version 1 (an update from the initial version 0) corresponds to
OS4 version 2A.

### Flag updates

A flag bit that was not used in API version 0 is now called
`Flag_HideTopKeyAssign`. This bit toggles the top row key auto
assignments to allow the single letter RPN program labels to be
used. For this to work there must be at least one shell active. This
is always the case if you have the Boost module plugged in as it uses
a system shell for its catalog, execute and assign enhancements.

### New entries

The following a a list of added routines in API version 1:

`resetMyBank` reset to primary bank (routine in bank 1)

`postfix4095` convert postfix operand to a value 0--4095

`XBCDBIN` convert small BCD number to binary

`pausingReset` test and reset OS4 pausing flag

`CXtoX` convert small binary number to floating point in X

`CtoXRcl` binary integer to floating point number, use `RCL`

`CtoXDrop` binary integer to floating point number, use `DROPST`

`CtoXFill` binary integer to floating point number, use `FILLXL`

`ERRDE_resetMyBank` reset the bank of the caller and exit to `ERRDE`

`ERRNE_resetMyBank` reset the bank of the caller and exit to `ERRNE`

`ERRAD_resetMyBank` reset the bank of the caller and exit to `ERRAD`

`ERROF_resetMyBank` reset the bank of the caller and exit to `ERROF`

`errorExit_resetMyBank` reset the bank of the caller and exit to
`errorExit`

`CHK_NO_S_resetMyBank` test for alpha data

`SKP_resetMyBank` reset callers bank and then exit to `SKP`

`SKP_YESNO_resetMyBank` variant of `SKP_resetMyBank`

`NOSKP_resetMyBank` reset callers bank and then exit to `NOSKP`

`NOSKP_YESNO_resetMyBank` variant of `NOSKP_resetMyBank`

`ensureBufferWithTrailer` find or create an empty buffer

`getIndexX` get index from X in form `RRR.BBBEEE`

### Address range

Affected entry point addresses are in the `0x4d38`-`0x4d5f` and
`0x4f90`-`0x4fa4` ranges.
