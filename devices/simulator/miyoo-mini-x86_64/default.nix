{ celunPath, config, lib, pkgs, ... }:

let
  inherit (config.device) nameForDerivation;
in
{
  imports = [
    (celunPath + "/devices/qemu/pc-x86_64")
  ];

  device = {
    name = lib.mkForce "simulator/miyoo-mini";
  };

  # Target device can't use an initramfs (currently)
  # Let's boot directly to rootfs then.
  wip.stage-1.enable = false;

  device.config.qemu = {
    memorySize = 128;
    qemuOptions = [
      # Resolution of the target device
      ''-device VGA,edid=on,xres=640,yres=480''

      ''-drive "file=${config.build.spiflash},format=raw,snapshot=on,index=0"''
      ''-drive "file=${config.build.sdcard  },format=raw,snapshot=on,index=1"''
    ];
  };

  boot.cmdline = [
    "root=/dev/sda" # ugh
    "rootfstype=squashfs"
    "ro"
  ];

  build.sdcard = pkgs.callPackage (
    { runCommandNoCC, nameForDerivation }:

    # XXX temp
    runCommandNoCC "qemu-${nameForDerivation}" {} ''
      dd if=/dev/zero of=$out bs=1M count=$(( 32 ))
    ''
  ) { inherit nameForDerivation; };

  build.spiflash = pkgs.callPackage (
    { runCommandNoCC, nameForDerivation }:

    # XXX temp
    runCommandNoCC "qemu-${nameForDerivation}" {} ''
      dd if=/dev/zero of=$out bs=1024 count=$(( 0xd70000 / 1024 ))
    ''
  ) { inherit nameForDerivation; };
}