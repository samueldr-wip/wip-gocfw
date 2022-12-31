{ stdenv
, fetchFromGitHub
}:

# Cheating here :/
stdenv.mkDerivation {
  version = "5.15.0-rc6";
  src = builtins.fetchGit /Users/samuel/tmp/linux/opendingux;
  #src = fetchFromGitHub {
  #  owner = "OpenDingux";
  #  repo = "linux";
  #  rev = "b7922167fdca1ab4b9846fef9253b22de93fb45f"; # jz-6.1
  #  sha256 = "sha256-WpSxWIIh2EnXH8cFpyxP5ATLIjguWHIiAnTh6bKvM08=";
  #};

  postInstall = ''
    (
      cd $buildRoot
      cp -v -t $out/ arch/mips/boot/uzImage.bin
      cp -v -t $out/dtbs/ingenic arch/mips/boot/dts/ingenic/*.dtb
    )
  '';
}
