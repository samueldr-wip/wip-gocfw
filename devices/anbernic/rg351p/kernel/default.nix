{ stdenv }:

# Cheating here :/
stdenv.mkDerivation {
  version = "4.4.189";
  src = builtins.fetchGit /Users/samuel/tmp/linux/wip-rg351p;
}
