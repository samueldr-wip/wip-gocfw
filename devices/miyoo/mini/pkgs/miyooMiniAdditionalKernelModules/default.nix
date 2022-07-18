{ gcc8Stdenv, linux_4_9, fetchurl, fetchFromGitHub }:

let
  linux = linux_4_9;
in
gcc8Stdenv.mkDerivation {
  name = "linux-miyoo-mini-modules";
  src = fetchFromGitHub {
    owner = "linux-chenxing";
    repo = "linux-ssc325";
    rev = "979122be45d470e959c2245c996fa93dea10069b"; # takoyaki_dls00v050
    sha256 = "sha256-BvY/fuk4ltZa1mP5XLZjBZWxESNfI31S6SPNtZ5tMrc=";
  };

  buildInputs = linux.buildInputs;
  nativeBuildInputs = linux.nativeBuildInputs;
  depsBuildBuild = linux.depsBuildBuild;
  makeFlags = linux.makeFlags;

  patches = [
    ./0001-Makefile-Remove-unneeded-vendor-crap.patch
  ];

  buildPhase = ''
    # Wrapper around make for readability
    _make() {
      (set -x
      make -j$NIX_BUILD_CORES $makeFlags "''${makeFlagsArray[@]}" "$@"
      )
    }

    # ¯\_(ツ)_/¯
    rm makefile
    # ¯\_(ツ)_/¯
    cat > .sstar_chip.txt <<EOF
    infinity2m
    EOF

    # Arbitrary defconfig for a close enough SoC
    _make infinity2m_ssc010a_s01a_defconfig

    # Config options required to:
    #  (1) build loop.ko
    #  (2) have the proper data structure sizes
    cat >> .config <<EOF
    CONFIG_BLK_DEV=y
    CONFIG_BLK_DEV_LOOP=m
    CONFIG_PM=y
    EOF
    substituteInPlace .config \
      --replace 'CONFIG_LBDAF=y' '# CONFIG_LBDAF is not set'

    # Refresh .config
    _make oldconfig

    # Prepare for build
    _make prepare
    _make scripts
    cp -v ${./Module.symvers} ./Module.symvers
    _make modules_prepare
    _make SUBDIRS=scripts/mod

    # Then build the module
    _make SUBDIRS=drivers/block modules
  '';

  installPhase = ''
    (set -x
    _make INSTALL_PATH='$(out)' INSTALL_MOD_PATH='$(out)' \
      SUBDIRS=drivers/block modules_install
    mkdir -p $out
    cp .config $out/config
    )
  '';
}
