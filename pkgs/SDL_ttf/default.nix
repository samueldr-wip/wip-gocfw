{ lib
, stdenv
, fetchFromGitHub
, SDL
, freetype
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "SDL_ttf";
  version = "unstable-2022-05-25";

  src = fetchFromGitHub {
    owner = "libsdl-org";
    repo = "SDL_ttf";
    rev = "2648c22c4f9e32d05a11b32f636b1c225a1502ac"; # SDL-1.2
    sha256 = "sha256-DKfDoon1xCDlMkSNzXSrd7yk9shkRRQvRLWpDVmNCng=";
  };

  patches = [
    ./0001-Backport-Fixed-bug-3762-Can-t-render-characters-with.patch
  ];

  buildInputs = [ SDL freetype ];

  nativeBuildInputs = [
    pkg-config
  ];

  configureFlags = lib.optional stdenv.isDarwin "--disable-sdltest";

  meta = with lib; {
    description = "SDL TrueType library";
    license = licenses.zlib;
    platforms = platforms.all;
    homepage = "https://github.com/libsdl-org/SDL_ttf";
  };
}
