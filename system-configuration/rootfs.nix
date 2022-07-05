{ config, lib, pkgs, ... }:

let
  inherit (config.device) nameForDerivation;
  inherit (config.examples.hello-wip-games-os.output) extraUtils;
  inherit (lib)
    concatMapStringsSep
    mkOption
    types
  ;
  writeScriptDir = name: text: pkgs.writeTextFile {inherit name text; executable = true; destination = "${name}";};
in
{
  options = {
    examples.hello-wip-games-os = {
      # FIXME: use the upcoming submodule implementing the generic interface
      rootfs = {
        contents = mkOption {
          type = types.attrsOf types.unspecified; # XXX too lazy to use the correct type
          default = {};
        };
      };
    };
  };

  config = {
    # FIXME: provide similar semantics to the initramfs builder, but targeting
    #        any arbitrary filesystem/archive (e.g. squashfs).
    #        In other words, make a reusable submodule.
    wip.stage-1.enable = lib.mkForce true;
    # `xz` to hopefully cut ties with the whole closure.
    wip.stage-1.compression = lib.mkForce "xz";

    wip.stage-1.contents = config.examples.hello-wip-games-os.rootfs.contents;

    # Builds 
    build.TEMProotfs = pkgs.callPackage (
      { runCommandNoCC
      , squashfsTools
      , cpio
      }:

      runCommandNoCC "rootfs.squashfs-${nameForDerivation}" {
        nativeBuildInputs = [
          cpio
          squashfsTools
        ];
      } ''
        mkdir fs
        (
        cd fs
        PS4=" $ "; set -x
        xzcat ${config.wip.stage-1.output.initramfs} | cpio -idv
        )
        (PS4=" $ "; set -x
        mksquashfs fs \
          "$out" \
          -quiet \
          -comp xz \
          -b $(( 1024 * 1024 )) \
          -Xdict-size 100% \
          -all-root
        )
      ''
    ) { };

    # Co-opts the stage-1 infra to build a rootfs
    # FIXME: (read other FIXME) provide generic submodule
    examples.hello-wip-games-os.rootfs.contents = {
      "/etc/issue" = pkgs.writeTextDir "/etc/issue" ''

          +----------------------------------+
          | Tip of the day                   |
          | ==============                   |
          | Login with root and no password. |
          +----------------------------------+

      '';

      "/etc/splash.png" = pkgs.runCommandNoCC "splash" { } ''
        mkdir -p $out/etc
        cp ${../artwork/splash_640x480.png} $out/etc/splash.png
      '';

      # https://git.busybox.net/busybox/tree/examples/inittab
      # TODO: inittab submodule
      "/etc/inittab" = pkgs.writeTextDir "/etc/inittab" ''
        # Allow root login on the `console=` param.
        # (Or when missing, a default console may be launched on e.g. serial)
        # No console will be available on other valid consoles.
        ${concatMapStringsSep "\n" (
          console: "${console}::respawn:${extraUtils}/bin/getty -l ${extraUtils}/bin/login 0 ${console}"
        ) [
          # TODO: make default "console" opt-out
          "console"
          # TODO: make *extra* consoles configurable
          # "ttyS0"
          # "ttyGS0"
          # "tty2"
        ]}

        # Launch all setup tasks
        ::sysinit:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/mount-basic-mounts
        ::wait:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/network-setup
        ::wait:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/logging-setup
        ::wait:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/mount-sdcard

        # Splash text is shown when the system is ready.
        ::once:${extraUtils}/bin/ply-image --clear=0xffffff /etc/splash.png

        ::restart:/bin/init
        ::ctrlaltdel:/bin/poweroff
      '';

      "/etc/passwd" = pkgs.writeTextDir "/etc/passwd" ''
        root::0:0:root:/root:${extraUtils}/bin/sh
      '';

      "/etc/profile" = writeScriptDir "/etc/profile" ''
        export LD_LIBRARY_PATH="${extraUtils}/lib"
        export PATH="${extraUtils}/bin"
      '';

      # Place init under /etc/ to make / prettier
      init = writeScriptDir "/init" ''
        #!${extraUtils}/bin/sh

        echo
        echo "::"
        echo ":: Launching busybox linuxrc"
        echo "::"
        echo

        . /etc/profile

        exec linuxrc
      '';

      extraUtils = pkgs.runCommandNoCC "hello-wip-games-os--initramfs-extraUtils" {
        passthru = {
          inherit extraUtils;
        };
      } ''
        mkdir -p $out/${builtins.storeDir}
        cp -prv ${extraUtils} $out/${builtins.storeDir}
      '';

      # POSIX requires /bin/sh
      "/bin/sh" = pkgs.runCommandNoCC "hello-wip-games-os--initramfs-extraUtils-bin-sh" {} ''
        mkdir -p $out/bin
        ln -s ${extraUtils}/bin/sh $out/bin/sh
      '';

      # Under some conditions, the rootfs is actually read-only and mountpoints
      # need to be created beforehand
      "/" = pkgs.runCommandNoCC "hello-wip-games-os--initramfs-fhs" {} ''
        mkdir -p $out/{proc,sys,dev,mnt}
      '';
    };

    examples.hello-wip-games-os.extraUtils.packages = [
      {
        package = pkgs.busybox;
        extraCommand = ''
          (cd $out/bin/; ln -s busybox linuxrc)
        '';
      }
      {
        package = pkgs.ply-image;
        extraCommand = ''
          cp -f ${pkgs.glibc.out}/lib/libpthread.so.0 $out/lib/
        '';
      }

      # TODO: explore using fstab
      (pkgs.writeScriptBin "mount-basic-mounts" ''
        #!/bin/sh

        echo ":: Basic mounts"
        PS4=" $ "; set -x
        mkdir -p /proc /sys /dev
        mount -t proc proc /proc
        mount -t sysfs sys /sys
        mount -t devtmpfs devtmpfs /dev
        # Work around systems where the squashfs backed rootfs is deeply read-only.
        mount -t tmpfs tmpfs /mnt
        # TODO: make optional
        mount -t debugfs none /sys/kernel/debug/
      '')

      # This does not actually do *networking*, but sets-up some basic
      # things normally associated with networking like hostname and loopback.
      (pkgs.writeScriptBin "network-setup" ''
        #!/bin/sh

        echo ":: Network params setup"
        PS4=" $ "; set -x

        # Set a hostname, for vanity
        hostname 'games-os-${nameForDerivation}'

        # Ensure loopback is setup, if possible.
        ip link set lo up
      '')

      (pkgs.writeScriptBin "logging-setup" ''
        #!/bin/sh

        echo ":: Logging setup"
        if [ -e /proc/sys/kernel/printk ]; then
          (
            PS4=" $ "; set -x
            echo 5 > /proc/sys/kernel/printk
          )
        fi
      '')

      (pkgs.writeScriptBin "mount-sdcard" ''
        #!/bin/sh

        echo ":: SD card init"
        PS4=" $ "; set -x
        mkdir -p /mnt/SDCARD
        # XXX: configurable device?
        # XXX: using mdev?
        mount -t vfat -o dirsync /dev/sdb /mnt/SDCARD
      '')
    ];

    examples.hello-wip-games-os.output = {
      extraUtils = pkgs.callPackage (
        { mkExtraUtils, packages }:

        mkExtraUtils {
          name = "wip-games-os-hello--extra-utils";
          inherit packages;
        }
      ) {
        inherit (config.examples.hello-wip-games-os.extraUtils) packages;
      };
    };
  };
}
