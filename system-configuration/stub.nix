/*

What's the stub?
================

The stub is a minimal system that will do just enough system initialization
to launch the next system. This can be compared to the initrd/initramfs of
other distros, but is different in that it is not tightly coupled to the
next stage it will load.

The gocfw stub is written with the express intent to continue booting into
any other operating systems.


Technical details
-----------------

This is either a "true" initramfs, or a tiny system, usually packed with
squashfs, which will `switch_root` or `pivot_root` into a target system,
which itself is expected to live on the user storage (SD card), as a
squashfs archive.


But why?
--------

This is meant to give the ability for alternative gocfw compatible CFWs to
take full control of the root filesystem, while sharing the workload of
managing the kernel.

This also provides a much more robust upgrade path for alternative CFWs, as
they don't have to rely on hijacking the normal boot flow of an "adversarial"
operating system, but instead rely on a solution tailor-made to load their
systens.

With some systems, where the boot stages live on the same medium as the user
storage, this may seem less useful. It is still useful when considering that
the upgrade of the systems can be handled in more compartmentalized ways, and
easier to understand ways.

Finally, since this will enable a form of "multiboot" for the userspace, this
allows end-users to better take advantage of the different CFWs without the
usual headaches. In addition, testing WIP updates of CFWs will be easier as
they can be provided as an additional image to boot from.

 */

{ config, lib, pkgs, ... }:

let
  inherit (config.games-os.stub.output) extraUtils;
  inherit (lib)
    mkOption
    types
  ;
  writeScriptDir = name: text: pkgs.writeTextFile {
    inherit name text;
    executable = true;
    destination = "${name}";
  };
in
{
  options = {
    games-os = {
      stub = {
        # TODO: See if there's a better approach (auto-detection?)
        # Detecting with partlabel/filesystem label might not be the best idea, as it
        # would prevent users from changing the label, or "just" using any FAT32 sd cards.
        # Peeking at partitions and finding the first with a compatible system would be feasible I guess.
        userdataPartition = mkOption {
          type = types.str;
          description = ''
            Device name for the userdata partition.
          '';
        };
        userdataPartitionOptions = mkOption {
          type = types.str;
          default = "";
          description = ''
            Mount options for the userdata storage.

            Note that the target system must use the same options if it
            wants to re-mount the sd card by itself.
          '';
        };
        extraUtils = {
          packages = mkOption {
            type = with types; listOf (oneOf [
              package
              attrs # TODO: extraUtils submodule
            ]);
            description = ''
              Packages to be included in the stub closure.

              This is different from the `filesystem` option in that
              this option intrinsically knows about the Nix closure and
              minimizes it as much as possible.
            '';
          };
        };
        filesystem = config.wip.cpio.lib.mkOption {
          description = ''
            Filesystem eval for the stub system.
          '';
        };
        output = {
          extraUtils = mkOption {
            type = types.package;
            internal = true;
            description = ''
              Stripped-down closure for the stub.
            '';
          };
          squashfs = mkOption {
            type = types.package;
            internal = true;
            description = ''
              Squashfs output.
            '';
          };
        };
      };
    };
  };
  config = {
    # This is the default, with hopes that we get more targets
    # with dedicated storage compared to targets without.
    wip.stage-1.enable = lib.mkDefault false;

    games-os.stub.filesystem.contents = {
      # POSIX requires /bin/sh
      "/bin/sh" = pkgs.runCommandNoCC "games-os-stub-bin-sh" {} ''
        mkdir -p $out/bin
        ln -s ${extraUtils}/bin/sh $out/bin/sh
      '';

      # Under some conditions, the rootfs is actually read-only and mountpoints
      # need to be created beforehand
      "/" = pkgs.runCommandNoCC "games-os-stub-rootfs" {} ''
        mkdir -p $out/{proc,sys,dev,mnt,run,tmp}
      '';

      "/etc/profile" = writeScriptDir "/etc/profile" ''
        export LD_LIBRARY_PATH="${extraUtils}/lib"
        export PATH="${extraUtils}/bin"
      '';

      init = writeScriptDir "/init" ''
        #!${extraUtils}/bin/sh
        . /etc/profile

        echo ":: System early init..."

        for f in /etc/init.d/*; do
          printf ":: %s\n" "$f"
          "$f"
        done

        echo
        echo ":: Switching into selected system..."
        echo

        (
        PS4=" $ "; set -x

        mkdir -p /mnt/rootfs/proc
        mount --move /proc /mnt/rootfs/proc
        mkdir -p /mnt/rootfs/sys
        mount --move /sys /mnt/rootfs/sys  
        mkdir -p /mnt/rootfs/dev
        mount --move /dev /mnt/rootfs/dev  
        mkdir -p /mnt/rootfs/run
        mount --move /run /mnt/rootfs/run  
        )

        ${if (!config.wip.stage-1.enable) then ''
          exec chroot /mnt/rootfs /init
        '' else ''
          exec switch_root /mnt/rootfs /init
        ''}
      '';

      "/etc/init.d/01-basic-mounts" = writeScriptDir "/etc/init.d/01-basic-mounts" ''
        #!${extraUtils}/bin/sh
        PS4=" $ "; set -x

        mkdir -p /proc
        mount -t proc proc /proc

        mkdir -p /sys
        mount -t sysfs sys /sys

        mkdir -p /dev
        mount -t devtmpfs devtmpfs /dev

        mkdir -p /mnt
        mount -t tmpfs tmpfs /mnt

        mkdir -p /run
        mount -t tmpfs tmpfs /run

        mkdir -p /tmp
        mount -t tmpfs tmpfs /tmp

        # Assumed to be available/present.
        # Not an issue if it doesn't mount.
        mount -t debugfs none /sys/kernel/debug/
      '';

      "/etc/init.d/20-sd-mount" = writeScriptDir "/etc/init.d/20-sd-mount" ''
        #!${extraUtils}/bin/sh

        count=600
        echo "Waiting for device '${config.games-os.stub.userdataPartition}' to show-up..."
        until [ -e ${config.games-os.stub.userdataPartition} ]; do
          echo -n "."
          sleep 0.1
          count=$(( count - 1 ))
          if [[ $count -eq 0 ]]; then
            echo ":: ERROR: target '${config.games-os.stub.userdataPartition}' partition never showed up."
            echo "   Candidates:"
            for f in /dev/*; do
              test -b "$f" && printf '    - %s\n' "$f"
            done
            echo "... about to abort!"
            sleep 10
            echo 1 > /proc/sys/kernel/sysrq
            echo c > /proc/sysrq-trigger
            exit 1
          fi
        done

        PS4=" $ "; set -x

        mkdir -p /run/gocfw/userdata
        mount -o "${config.games-os.stub.userdataPartitionOptions}" \
          ${config.games-os.stub.userdataPartition} /run/gocfw/userdata
      '';

      # TODO: consume data left by the rootfs chooser applet
      "/etc/init.d/25-rootfs-mount" = writeScriptDir "/etc/init.d/25-rootfs-mount" ''
        #!${extraUtils}/bin/sh
        PS4=" $ "; set -x

        mkdir -p /mnt/rootfs
        mount /run/gocfw/userdata/system/rootfs.img /mnt/rootfs
      '';

      /*
      "/etc/init.d/70-debug" = writeScriptDir "/etc/init.d/70-debug" ''
        #!${extraUtils}/bin/sh
        
        while true; do
          /bin/sh -l
        done
      '';
      /* */

      "/etc/init.d/99-boot" = writeScriptDir "/etc/init.d/99-boot" ''
        #!${extraUtils}/bin/sh
      '';

      extraUtils = pkgs.runCommandNoCC "games-os-stub-extra-utils" {
        passthru = { inherit extraUtils; };
      } ''
        mkdir -p $out/${builtins.storeDir}
        cp -prv ${extraUtils} $out/${builtins.storeDir}
      '';
    };

    games-os.stub.extraUtils.packages = [
      { package = pkgs.busybox; }
    ];

    games-os.stub.output = {
      extraUtils = pkgs.callPackage (
        { mkExtraUtils, packages }:

        mkExtraUtils {
          name = "games-os-stub-extra-utils";
          inherit packages;
        }
      ) {
        inherit (config.games-os.stub.extraUtils) packages;
      };
      squashfs = (pkgs.celun.image-builder.evaluateFilesystemImage {
        config = {
          filesystem = "squashfs";
          # Borrow the cpio semantics to populate the rootfs
          populateCommands = ''
            cat ${config.games-os.stub.filesystem.output} | "${pkgs.buildPackages.cpio}/bin/cpio" -idv
          '';
        };
      }).config.output;
    };
  };
}
