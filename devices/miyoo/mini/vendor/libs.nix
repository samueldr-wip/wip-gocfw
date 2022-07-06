{ config, pkgs, ... }:

{
  examples.hello-wip-games-os.rootfs.contents = {
    # Files under `/vendor` allow use of existing software in a drop-in manner.
    # Note that we (sadly) don't have the sources either.
    # TODO: try replacing them all bit by bit with upstream equivalents.
    "/vendor" = pkgs.runCommandNoCC "miyoo-mini-vendor" {} ''
      mkdir -p $out/vendor/{lib,bin}
      cp -vt $out/vendor/lib/ ${config.device.config.miyoo-mini.vendorBlobs}/lib/*
    '';
  };
  examples.hello-wip-games-os.extraUtils.packages = [
    (pkgs.writeScriptBin "vendor-run" ''
      #!/bin/sh

      export LD_LIBRARY_PATH
      LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/vendor/lib:/mnt/SDCARD/.system/lib

      export PATH
      PATH=$PATH:/vendor/bin:/mnt/SDCARD/.system/bin

      export LOGS_PATH
      LOGS_PATH="/tmp"

      exec "$@"
    '')
  ];
}

