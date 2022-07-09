{ lib
, runCommandNoCC
, writeText

, rootfs
, bootargs
, version
}:

let
  payloadOffset = "0x4000";  # The vendor U-Boot will read 0x4000 bytes for the script.
  rootfsOffset = "0x290000"; # Partition offset
  rootfsPartSize = "0xd70000"; # Partition size (subsuming following partitions)
  updateScript = writeText "update-script" ''
    build:${version}

    # Enable the SPI Flash
    sf probe 0

    # Read all of the payload
    fatload mmc 0 0x21000000 $(SdUpgradeImage) 0 ${payloadOffset}

    # Write the rootfs
    sf update 0x21000000 ${rootfsOffset} ${rootfsPartSize}

    # Update boot args
    env set bootargs '${bootargs}'

    # the next `env set` command needs to be less than 64 words long.
    # So let's use `run` for buzzing about
    env set buzz 'gpio out 48 0; sleepms 100; gpio out 48 1; sleepms 150'

    # Update boot command
    env set bootcmd '${
      lib.concatStringsSep "; " [

        # > force the mosfet that connects the battery to the system on.
        #  — https://github.com/linux-chenxing/linux-chenxing.org/discussions/41#discussioncomment-3024610
        #  — https://github.com/linux-chenxing/linux/blob/65c255cdc9e1e758558dd3ab7e39d565f9863e02/arch/arm/boot/dts/mstar-infinity2m-ssd202d-miyoo-mini.dts#L178
        "gpio out 85 1"

        # Run the custom boot command (if present)
        "run mybootcmd"

        # Vibrate to tell the user it's attempting the default boot sequence.
        "run buzz"
        "run buzz"

        # Vendor boot commands
        "bootlogo 0 0 0 0 0"

        # (Unclear what this does, present in vendor startup sequence)
        "mw 1f001cc0 11"

        # (Unclear what this does, present in vendor startup sequence)
        "gpio out 8 0"

        # Read the kernel from SPI Flash
        "sf probe 0"
        "sf read 0x22000000 \${sf_kernel_start} \${sf_kernel_size}"

        # (Unclear what this does, present in vendor startup sequence)
        "gpio out 8 1"

        # Powers the backlight
        "gpio out 4 1"

        # Boots previously loaded kernel
        "bootm 0x22000000"
      ]
    }'

    # Just in case, those are used by the vendor command
    env set sf_kernel_size 200000
    env set sf_kernel_start 60000

    # Version for the OS
    env set miyoo_version ${version}

    env save

    reset

    % # End of script
  '';
in
runCommandNoCC "firmware-upgrade-${version}" {
  inherit rootfs;
  inherit rootfsPartSize;
} ''
  size=$(stat -c %s "$rootfs")
  if (( size > rootfsPartSize )); then
    printf "error: rootfs size (%d bytes) larger than max (%d bytes)" "$size" "$rootfsPartSize"
    exit 1
  fi

  (PS4=" $ "; set -x
  mkdir -p $out
  # Start the firmware image with the update script
  cat "${updateScript}" > "$out/miyoo283_fw.img"

  # Pad the rootfs payload to the size of the SPI flash, makes the script easier to write.
  dd if="/dev/zero"   of="payload.img"          bs=$(( rootfsPartSize )) count=$(( 1 )) conv=notrunc
  # Write the rootfs in the NULL padded file
  dd if="$rootfs"     of="payload.img"          bs=1024 conv=notrunc

  # Append the whole payload starting at payloadOffset to the firmware image
  dd if="payload.img" of="$out/miyoo283_fw.img" bs=$((${payloadOffset})) seek=1 conv=notrunc
  )
''
