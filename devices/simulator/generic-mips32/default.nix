{ celunPath, config, lib, pkgs, ... }:

let
  inherit (lib)
    mkForce
    mkMerge
  ;
  inherit (config.device) nameForDerivation;
in
{
  imports = [
    (celunPath + "/devices/qemu/mips-32")
  ];

  device = {
    name = lib.mkForce "simulator/generic-mips32";
  };

  # Target device uses initramfs.
  wip.stage-1.enable = true;
  wip.stage-1.cpio = config.games-os.stub.filesystem.output;

  device.config.qemu = {
    memorySize = 512; # Appropriate default

    qemuOptions = [
      #''-smp 4'' # 4×A35 in RG351P
      ''-drive "file=${config.build.sdcard  },format=raw,snapshot=on,index=0"''
    ];
  };

  boot.cmdline = [
    "video=cirrusfb:320x240-16@60"
  ];

  wip.kernel.structuredConfig =
    with lib.kernel;
    let
      inherit (config.wip.kernel) features;
    in
    mkMerge [
      {
        # Breaks console output entirely without a manual chvt switch
        LOGO = mkForce no;
      }
    ]
  ;

  build.sdcard = (pkgs.celun.image-builder.evaluateDiskImage {
    config = {
      partitioningScheme = "gpt";
      partitions = [
        {
          name = "userdata";
          filesystem = {
            filesystem = "fat32";
            extraPadding = 1024 * 1024 * 32;
            populateCommands = ''
              mkdir -p system
              cp ${config.build.TEMProotfs} system/rootfs.img
            '';
          };
        }
      ];
    };
  }).config.output;

  games-os.stub.userdataPartition = "/dev/sda1";
}
