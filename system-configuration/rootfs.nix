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
    wip.stage-1.compression = "xz";

    wip.stage-1.contents = config.examples.hello-wip-games-os.rootfs.contents;

    build.TEMProotfs = (pkgs.celun.image-builder.evaluateFilesystemImage {
      config = {
        filesystem = "squashfs";
        # Borrow the initramfs semantics to populate the rootfs
        populateCommands = ''
          xzcat ${config.wip.stage-1.output.initramfs} | "${pkgs.buildPackages.cpio}/bin/cpio" -idv
        '';
      };
    }).config.output;

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

      # https://git.busybox.net/busybox/tree/examples/inittab
      # TODO: inittab submodule
      "/etc/inittab" = pkgs.writeTextDir "/etc/inittab" ''
        # Allow login
        # Note that unless the console is listed here, no login facilities will
        # be provided on them.
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
        # XXX
        ::wait:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/vendor-kernel-modules
        # Needs to happen after hardware init
        ::wait:${extraUtils}/bin/sh -l -c ${extraUtils}/bin/mount-sdcard

        # Hello app
        console::respawn:${extraUtils}/bin/hello

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

      # FHS compat
      "lib/ld-linux" = pkgs.runCommandNoCC "hello-wip-games-os--initramfs-fhs-ld-linux" {} ''
        mkdir -p $out/lib
        for f in ${extraUtils}/lib/ld-linux*.so*; do
          ln -s "$f" $out/lib/
        done
      '';

      # Under some conditions, the rootfs is actually read-only and mountpoints
      # need to be created beforehand
      "/" = pkgs.runCommandNoCC "hello-wip-games-os--initramfs-fhs" {} ''
        mkdir -p $out/{proc,sys,dev,mnt,tmp}
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

      { package = pkgs.luajit; }
      {
        package = pkgs.SDL;
        extraCommand = ''cp -fr -t $out/lib/ ${pkgs.SDL}/lib/*.so*'';
      }
      {
        package = pkgs.SDL_ttf;
        extraCommand = ''cp -fr -t $out/lib/ ${pkgs.SDL_ttf}/lib/*.so*'';
      }
      {
        package = pkgs.SDL_image;
        extraCommand = ''cp -fr -t $out/lib/ ${pkgs.SDL_image}/lib/*.so*'';
      }
      {
        package = pkgs.games-os.hello;
        extraCommand = ''
          mkdir -p $out/share/
          cp -fr -t $out/share/ ${pkgs.games-os.hello}/share/*
          (
          cd $out/bin
          chmod -R +w .
          cat <<EOF > hello
          #!/bin/sh
          export APP_PATH
          APP_PATH="$out/share/games-os-hello/"
          export SDL_NOMOUSE
          SDL_NOMOUSE=1 # XXX
          $out/bin/luajit "\$APP_PATH/hello.lua" "\$@"
          EOF
          )
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
        mount -t tmpfs tmpfs /tmp
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
        mount -t vfat -o iocharset=utf8,dirsync /dev/mmcblk0p1 /mnt/SDCARD
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
