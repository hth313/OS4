(define memories
  '((memory OS4 (bank 1) (address (#x4000 . #x4FFF))
            (section (Header4 #x4000) code code1
                     (fixedEntries #x4d00)
                     (keycode #x4a40)
                     (OS4BankSwitchers1 #x4fc3)
                     (entry #x4f00)
                     (TailOS4 #x4ffb))
            (checksum #x4FFF hp41)
            (fill 0))
    (memory OS4-2 (bank 2) (address (#x4000 . #x4FFF))
            (section (Header4_2 #x4000)
                     code2
                     (OS4BankSwitchers2 #x4fc3)
                     (TailOS4_2 #x4ffb))
            (checksum #x4FFF hp41)
            (fill 0))
    ))
