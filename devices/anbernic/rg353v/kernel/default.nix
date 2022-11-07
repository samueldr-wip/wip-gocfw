{ stdenv }:

# Cheating here :/
stdenv.mkDerivation {
  version = "4.19.172";
  src = builtins.fetchGit /Users/samuel/tmp/linux/anbernic-rg353v-wip;
}
