{ stdenv

, meson
, ninja
, pkg-config
, vala

, SDL
, cairo
, glib
}:

stdenv.mkDerivation {
  pname = "games-os-hello";
  version = "2022-11-09";

  # XXX
  src = builtins.fetchGit /Users/samuel/Network/dashdingo.local/tmp/launcher/vala/hello-sdl;

  buildInputs = [
    SDL
    cairo
    glib
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    vala
  ];
}
