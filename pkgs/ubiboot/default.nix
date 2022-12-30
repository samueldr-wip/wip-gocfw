{ stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "ubiboot";
  version = "2022-12-06";

  src = fetchFromGitHub {
    owner = "pcercuei";
    repo = "UBIBoot";
    rev = "93f93289d1b37d147b58c2ac9efdda3281c05685";
    sha256 = "sha256-ulfqHQDZujxLYyPtpl2/g2YyHaY8OP1DW41J3+6NBZU=";
  };

  makeFlags = [
    "CONFIG=gcw0"
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ];

  hardeningDisable = [ "all" ];

  installPhase = ''
    mkdir -p $out
    cp -t $out output/*/*.bin
  '';

  fixupPhase = "";
}
