;;; -*- mode: gas;-*-

;;; **********************************************************************
;;;
;;; System buffer status flags. These flags are held in the buffer
;;; header.
;;;
;;; **********************************************************************

Flag_NoApps:  .equ    0             ; Set if all application shells are
                                    ; disabled, essentially meaning that
                                    ; we have default behavior (no active
                                    ; application). System shells still
                                    ; have priority and are active.
