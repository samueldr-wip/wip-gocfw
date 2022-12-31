{ config, pkgs, ... }:

let
  inherit (config.wip.stage-1.output) initramfs;
  inherit (config.device) nameForDerivation;
  kernel = config.wip.kernel.output;
  rootfs = config.build.TEMProotfs;
in
{
  build.disk-image = (pkgs.celun.image-builder.evaluateDiskImage {
    config =
      { config, ... }:

      let inherit (config) helpers; in
      {
        name = "${nameForDerivation}-disk-image";
        partitioningScheme = "mbr";
        alignment = 512;

        mbr.diskID = "12ABCDEF";

        partitions = [
          {
            name = "ubiboot";
            isGap = true;
            # bs=512 seek=1 count=16
            offset = 1 * 512;
            length = 16 * 512;
            raw = "${pkgs.games-os.ubiboot}/ubiboot-rg350.bin";
          }

          {
            name = "userdata";
            offset = helpers.size.MiB 1;
            filesystem = {
              filesystem = "fat32";
              label = "userdata";
              extraPadding = helpers.size.MiB 32;
              populateCommands = ''
                echo ":: Copying kernel"
                cp ${kernel}/uzImage.bin uzImage.bin

                echo ":: Appending DTB"
                chmod +w uzImage.bin

                # The YLM RG-280M v1.1 is a RG-280V with a clickable analog stick. The
                # v1.0 additionally has a ITE66121 chip.
                #  - https://github.com/OpenDingux/linux/commit/8003086698456b3ec60496c912727b770939abce
                # So my interpretation is that since it's a superset, it's safe to target v1.1 only.
                cat ${kernel}/dtbs/ingenic/rg280m-v1.1.dtb >> uzImage.bin

                echo ":: Copying stage-1"
                cp ${initramfs} initramfs.img

                echo ":: Copying system image"
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
