(define memories
  '((memory Play1 (position independent)
            (bank 1) (address (#x0 . #xFFF))
            (section (PlayFAT #x0) PlayCode PlayCode1 Lib41Code
                     PlayTable PlaySecondary1
                     (ExtensionHandlers #xF00)
                     (CountShell #xF04)
                     (PlayBankSwitchers1 #xFC3)
                     RPN (PlayFC2 #xFC2) (PlayPoll #xFF4))
            (checksum #xFFF hp41)
            (fill 0))
    (memory Play2 (position independent)
            (bank 2) (address (#x0 . #xFFF))
            (section (PlayHeader2 #x0) PlayCode2
                     PlaySecondary2
                     (PlayBankSwitchers2 #xFC3)
                     (PlayTail2 #xFF4))
            (checksum #xFFF hp41)
            (fill 0))))
