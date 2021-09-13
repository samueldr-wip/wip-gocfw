{ buildUBoot, fetchFromGitHub }:

buildUBoot {
  version = "2021.10";
  src = fetchFromGitHub {
    owner = "samueldr";
    repo = "u-boot";
    rev = "c9f9c1e20ed56f46a7fdcbf8c128872dad51b7a3"; #  wip/powkiddy-v90-mainline
    sha256 = "0lj4hbbg7h6lqmjk285mcmwfm9y1dv07imym5ar4h8xjm6bgn4gy";
  };
  defconfig = "powkiddy_v90_defconfig"; 
  extraMeta.platforms = ["armv5tel-linux"];         
  filesToInstall = ["u-boot-sunxi-with-spl.bin"];  
}
