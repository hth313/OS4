(define memories
  '((memory OS4 (bank 1) (address (#x4000 . #x4FFF))
            (section (Header4 #x4000) code
                     (errorHandlers #x4e00)
                     (entry #x4f00))
            (checksum #x4FFF hp41)
            (fill 0))))
