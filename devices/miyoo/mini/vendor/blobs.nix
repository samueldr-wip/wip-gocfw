{ lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options = {
    device.config.miyoo-mini = {
      vendorBlobs = mkOption {
        type = types.package;
        internal = true;
        description = ''
          Package containing all the relevant blobs from the vendor image.

          This package itself shouldn't be used in the final product, but instead
          files should be copied where relevant.

          This interface is assumed to be internal and unstable.
        '';
      };
    };
  };
  config = {
    device.config.miyoo-mini = {
      vendorBlobs = pkgs.callPackage (
        { lib
        , requireFile
        , runCommandNoCC
        , unzip
        , squashfsTools
        , ncdu
        , tree
        , fakeroot
        }:

        let
          inherit (lib) concatStringsSep;
        in
        runCommandNoCC "miyoomini-combined-rootfs" {
          zip = requireFile rec {
            name = "Miyoo-mini-upgrade20220419.zip";
            message = ''
              Download the file from here: https://lemiyoo.cn/upgrade/675.html

              Then use:

               $ nix-prefetch-url file://\$PWD/${name}
            '';
            sha256 = "1yjc1r44jfv36wiahb1cknj3xwazy1flk6d29pkgk23digq5svi0";
          };
          zip_firmware = "The firmware0419/miyoo283_fw.img";

          nativeBuildInputs = [
            squashfsTools
            unzip
            ncdu
            tree
            fakeroot
          ];
        } ''
          # Uses the updater script to create calls to the _extract function.
          parse_updater() {
            dd status=none if="$zip_firmware" bs=$((0x4000)) count=1 \
              | grep '^fatload\|mxp r.info' \
              | sed '/^mxp/N;s/\n/ /' \
              | grep 'rootfs\|miservice\|customer\|KERNEL' \
              | sed -e 's/mxp r.info/_extract/' -e 's/\s*fatload mmc 0 0x21000000\s*/ /' -e 's/\s*\$(SdUpgradeImage)\s*/ /'
          }

          _extract() {
            part="$1"; shift
            bytes=$1; shift
            pos=$1; shift

            (PS4=" $ "; set -x
            dd status=none if="$zip_firmware" bs=$(( bytes )) iflag=skip_bytes skip=$(( pos )) count=$(( 1 )) of="$part.img"
            )
          }

          # Extract only the SPI flash updater
          unzip "$zip" "$zip_firmware"

          # Extract the discrete partitions
          eval "$(parse_updater)"

          for f in {rootfs,miservice,customer}.img; do
            (PS4=" $ "; set -x
            fakeroot unsquashfs -quiet -dest ''${f/.img/} "$f"
            )
          done

          rmdir rootfs/customer
          mv customer rootfs/customer

          rmdir rootfs/config
          mv miservice rootfs/config

          echo ":: Copying wanted blobs"

          mkdir -p $out/blobs/
          cp -vt $out/blobs/ KERNEL.img

          mkdir -p $out/modules/
          cp -vr rootfs/config/modules/4.9.84 $out/modules/4.9.84
          cp -vr rootfs/config/lib $out/lib

          mkdir -p $out/config/
          cp -vt $out/config rootfs/config/{fbdev.ini,mmap.ini,riu_r,config_tool}
          cp -vr rootfs/config/vdec_fw $out/config/
        ''
      ) {};
    };
  };
}
