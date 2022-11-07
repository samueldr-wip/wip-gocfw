{ config, pkgs, lib, ... }:

let
  inherit (config.device) dtbFiles nameForDerivation;
  kernel = config.wip.kernel.output;
  inherit (kernel) target;
  inherit (config.wip.stage-1.output) initramfs;
  rootfs = config.build.TEMProotfs;

  # TODO: see if our built U-Boot will be able to do FDTDIR (probably not)
  # dtbName = "rk3566-rg353v-linux.dtb";
  # FDT    /.boot/dtbs/${dtbName}
  extlinuxconf = pkgs.writeText "${nameForDerivation}-extlinux.conf" ''
    LABEL gocfw
      LINUX  /.boot/kernel.img
      FDTDIR /.boot/dtbs
      INITRD /.boot/initramfs.img
      APPEND ${lib.concatStringsSep " " config.boot.cmdline}
  '';

  firmwareMaxSize = 4 * 1024 * 1024; # MiB in bytes
  partitionOffset = 64; # in sectors
  secondOffset = 16384; # in sectors
  sectorSize = 512;
in
{
  build.disk-image = (pkgs.celun.image-builder.evaluateDiskImage {
    config =
      { config, ... }:

      let inherit (config) helpers; in
      {
        name = "${nameForDerivation}-disk-image";
        partitioningScheme = "gpt";
        gpt.partitionEntriesCount = 48;
        # Or else partitions are forcibly aligned and this breaks.
        alignment = 512;

        # This weird partition layout is necessary for boot to work
        # with the pre-built U-Boot from the vendor.
        # This is in part because they force use of partition three.
        # We could also make a bogus partition and a single binary.
        # But for now let's use their layout.
        # TODO: our own U-Boot build.
        partitions = [
          {
            name = "gap";
            isGap = true;
            offset = partitionOffset * 512;
            length = (secondOffset - 64) * 512;
            # Not really needed when the eMMC U-Boot inits the system...
            # ... but we probably want it anyway.
            raw = ./u-boot-preamble.img;
          }
          {
            # *With the vendor U-Boot flow*
            # This needs to be a partition, but...
            # ... partition name matters
            name = "uboot";
            # ... partition type is unimportant
            partitionType = "A60B0000-0000-4C7E-8000-015E00004DB7";
            offset = secondOffset * 512;
            length = 8192 * 512;
            raw = ./u-boot-proper.img;
          }
          {
            # *With the vendor U-Boot flow*
            # This needs to be a partition, but...
            # ... partition name is uimportant
            name = "uboot-resource";
            # ... partition type unimportant
            partitionType = "D46E0000-0000-457F-8000-220D000030DB";
            offset = 24576 * 512;
            length = 8192 * 512;
            raw = ./u-boot-resource.img;
          }
          {
            name = "userdata";
            partitionLabel = "userdata";
            partitionType = "4F4C0000-0000-4049-8000-36C40000603B";
            bootable = true;
            filesystem = {
              filesystem = "fat32";
              label = "userdata";
              extraPadding = helpers.size.MiB 32;
              populateCommands = ''
                mkdir -p extlinux
                cp ${extlinuxconf} extlinux/extlinux.conf

                mkdir -p .boot
                cp ${initramfs}        .boot/initramfs.img
                cp ${kernel}/${target} .boot/kernel.img

                # There might not be any DTBs to install; on ARM the DTB files
                # are built only if the proper ARCH_VENDOR config is set.
                if [ -e ${kernel}/dtbs ]; then
                  (
                  shopt -s globstar
                  mkdir .boot/dtbs/
                  cp -v ${kernel}/dtbs/rockchip/rk3566-rg353p-linux.dtb .boot/dtbs/rk3566-rg353p.dtb
                  cp -v ${kernel}/dtbs/rockchip/rk3566-rg353v-linux.dtb .boot/dtbs/rk3566-rg353v.dtb
                  )
                else
                  echo "Warning: no dtbs built on hostPlatform with DTB"
                fi

                mkdir -p system
                cp ${rootfs} system/rootfs.img
              '';
            };
          }
        ];
      }
    ;
  }).config.output;
}
