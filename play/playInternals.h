#ifndef __PLAY_INTERNALS_H__
#define __PLAY_INTERNALS_H__

// Macro to switch to given bank on the fly.
switchBank:   .macro  n
              enrom\n
10$:
              .section PlayCode\n
              .shadow 10$
              .endm

#endif // __PLAY_INTERNALS_H__
