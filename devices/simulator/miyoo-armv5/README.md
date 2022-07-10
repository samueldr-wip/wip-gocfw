Miyoo (simulator)
=================

Simulator aimed at reproducing some details about the f1cX00s "miyoo" class
hardware.

This simulator runs armv5 code as the target device does. Use this simulator
to exercise the built binaries.

* * *

This is **not** a complete simulator for the target device.

This system is meant to reproduce only *some* of the intricacies of the target
device, namely:

This does **not** reproduce these details of the target system

 - Boot flow (No U-Boot)
 - Actual SD block device
 - GPU setup
 - Audio setup
 - USB setup
 - GPIO setup
