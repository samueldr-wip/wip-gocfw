{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkMerge
  ;
  inherit (config.wip.stage-1) buildInKernel;
in
{
  imports = [
    ./disk-image.nix
  ];

  config = mkMerge [
    {
      device = {
        name = "anbernic/rg280m";
        dtbFiles = [
          "ingenic/gcw0.dtb"
          "ingenic/gcw0_proto.dtb"
          "ingenic/pocketgo2.dtb"
          "ingenic/pocketgo2v2.dtb"
          "ingenic/rg350.dtb"
          "ingenic/rg350m.dtb"
          "ingenic/rg280m-v1.0.dtb"
          "ingenic/rg280m-v1.1.dtb"
          "ingenic/rg280v.dtb"
          "ingenic/rg300x.dtb"
        ];
      };

      hardware = {
        cpu = "ingenic-jz4770";
      };

      # Target device uses initramfs.
      wip.stage-1.enable = true;
      wip.stage-1.cpio = config.games-os.stub.filesystem.output;

      # The bootloader can't provide an initramfs image.
      # Upstream relies on mininit, a static binary that loads a squashfs image
      #  - https://github.com/OpenDingux/buildroot/blob/4d23381101e15cd53d9e1cb37e2a488d99d5b6e1/board/opendingux/gcw0/linux_defconfig#LL4C23-L4C27
      # We probably want to add support for such a scheme at some point.
      # For now it's easier not to make the choice, though it will incurr
      # longer rebuilds when working on the stub for now.
      wip.stage-1.buildInKernel = true;

      wip.kernel.package = pkgs.callPackage ./kernel { };
      wip.kernel.defconfig = pkgs.fetchurl {
        url = "https://github.com/OpenDingux/buildroot/raw/d6304599c47519d3492bc2d5a3bef7d2e80f8501/board/opendingux/gcw0/linux_defconfig";
        sha256 = "sha256-KPOlQPmqhMebF2kzwrceDVmQDawoM5Ce8vhsrlSAIWg=";
      };
      wip.kernel.installTargets = [
        "dtbs"
        "dtbs_install"
        "INSTALL_DTBS_PATH=$(out)/dtbs"
        "uzImage.bin"
        "ingenic/rg280m.dtb"
      ];

      wip.kernel.isModular = true;
      wip.kernel.structuredConfig =
        with lib.kernel;
        let
          inherit (config.wip.kernel) features;
        in
        mkMerge [
          {
            LOCALVERSION = freeform ''""'';
          }
        ]
      ;

      games-os.stub.userdataPartition = "/dev/mmcblk0p1";
    }

    {
      assertions = [
        {
          # TODO: add support for mininit and rootfs == userdata.
          #  -> add support globally, since it should work without an
          #     initramfs on most systems in a generic manner.
          assertion = buildInKernel;
          message = ''
            Building jz47** currently requires building the stub in the kernel image.
          '';
        }
      ];
    }
  ];
}
