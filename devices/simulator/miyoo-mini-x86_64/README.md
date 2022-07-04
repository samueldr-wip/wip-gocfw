Miyoo Mini (simulator)
======================

This is **not** a complete simulator for the target device.

This system is meant to reproduce only *some* of the intricacies of the target
device, namely:

 - No initramfs support (with vendor kernel)
 - Limited filesystem support (squashfs, FAT32)
 - rootfs on discrete block device (mimicking mtd flash, but not actually mtd)
 - "SD card" disk for "target runtime" data (e.g. CFW "apps")

This does **not** reproduce these details of the target system

 - Actual SD/MTD block devices
 - GPU setup
 - Audio setup
 - USB setup
 - GPIO setup

* * *

Why is this useful?
-------------------

Dealing with the rootfs and "target runtime" is somewhat inconvenient when
hacking on early boot. With this setup, we can be somewhat assured that the
boot process will work up to and including executing the "target runtime".
