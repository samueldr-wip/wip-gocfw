{ lib
, runCommandNoCC
, buildPackages
, writeScript
, squashfsTools
, busybox
}:

{ name
, entrypoint
, paths
# TODO: `cd` into `additionalContent` when present, and add everything from it as-is to the root
#       add its closure, but don't add `additionalContent` itself to the image...
#, additionalContent
}:

# TODO: attach metadata in /.metadata

let
  runner = writeScript "${name}-runner" ''
    #!${busybox}/bin/sh
    exec "${entrypoint}" "$@"
  '';
in
runCommandNoCC name {
  inherit name;
  blockSize = 1024 * 1024;
  nativeBuildInputs = [
    squashfsTools
  ];
  closureInfo = buildPackages.closureInfo { rootPaths = paths ++ [ runner ]; };
  compression = "xz";
  compressionParams = "-Xdict-size 100%";
} ''
  _mksquashfs() {
    mksquashfs \
    "$@" \
    -b "$blockSize" \
    -comp "$compression" $compressionParams \
    -no-hardlinks -keep-as-directory -all-root \
    -processors $NIX_BUILD_CORES \
    -no-recovery
  }

  mkdir -p $out
  tar c --files-from="$closureInfo/store-paths" | \
    _mksquashfs - "$out/$name.app" -tar -tarstyle

  (
  mkdir -p fs
  cd fs

  # The runner
  ln -s ${runner} .entrypoint

  # Required by POSIX
  mkdir bin
  ln -s ${busybox}/bin/sh bin/sh

  mkdir dev proc sys mnt var tmp

  # Activates dotglob, ignoring . and ..
  # This means hidden files are added too
  GLOBIGNORE=".:.."
  _mksquashfs * "$out/$name.app"
  )
''
