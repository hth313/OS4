*************
System shells
*************

.. index:: shells, system, system shells

System shells are intended for tuning the default behavior of the
standard keyboard. Advanced modules from the past like the Zenrom and
CCD used various tricks with the partial key sequence mechanism to
wedge in alternative behavior. Such tricks may result in certain
incompatibilities. Using a system shell provides a cleaner way of
making such extensions.

One example would be to replace the assign (ASN) key to provide ways
to not only assign by name, but also by XROM numbers or two byte
synthetic assignments.

System shells are stored in the shell stack and are consulted in their
stacking order. This way the one higher up in the stack has priority
over one lower down. In contrast to application shells, where the
topmost shell is consulted and the rest are ignored, system shells are
consulted in order until a shell that handles the key press are
found. Thus, system shells merge their functionality while an
application shell shadows the all other applications.

Display handler
===============

.. index:: display handler; system shell

A system shell may also have a display routine, but only the top-most
one is ever consulted and that is only if there is no active
application.

.. note::
   The display mechanism with system shells is very much unchartered
   territory. It may be wise to regard it as somewhat preliminary.
