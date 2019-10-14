(define memories
  '((memory OS4 (bank 1) (address (#x4000 . #x4FFF))
            (section (Header4 #x4000) code
                     (fixedEntries #x4d00)
                     (keycode #x4a40)
                     (entry #x4f00)
                     (TailOS4 #x4fff))
            (checksum #x4FFF hp41)
            (fill 0))))
