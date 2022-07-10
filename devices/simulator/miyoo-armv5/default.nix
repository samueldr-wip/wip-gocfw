{ celunPath, config, lib, pkgs, ... }:

let
  inherit (config.device) nameForDerivation;
in
{
  imports = [
    (celunPath + "/devices/qemu/versatile-ARM9")
  ];

  device = {
    name = lib.mkForce "simulator/miyoo-armv5";
  };

  device.config.qemu = {
    # With only 32, or even 64, scsi fails, so "SD card" block device doesn't show up.
    memorySize = 32 * 3;

    qemuOptions = [
      # XXX no SPI (but provide SPI option for trimui compat?)
      # XXX should be sdcard
      #''-drive "if=scsi,file=${config.build.spiflash},format=raw,snapshot=on,index=0"''
      ''-drive "file=${config.build.spiflash},format=raw,snapshot=on"''
    ];
  };

  boot.cmdline = [
    "root=/dev/mtdblock0"
    "rootfstype=squashfs"
    "ro"
  ];

  build.sdcard = pkgs.callPackage (
    { runCommandNoCC, nameForDerivation, dosfstools }:

    # XXX temp
    runCommandNoCC "qemu-${nameForDerivation}" {
      nativeBuildInputs = [
        dosfstools
      ];
    } ''
      dd if=/dev/zero of=$out bs=1M count=$(( 32 ))
      mkfs.fat -v -n "untitled" $out
    ''
  ) { inherit nameForDerivation; };

  build.spiflash = config.build.TEMProotfs;
}
