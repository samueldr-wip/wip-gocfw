{ stdenv
, SDL
, SDL_image
, SDL_ttf
}:

stdenv.mkDerivation {
  pname = "dingux-commander";
  version = "2022-12-16";
  src = builtins.fetchGit {
    url = ../../../../../../projects/dingux-commander;
    ref = "refs/heads/wip/gocfw-miyoo-mini";
  };

  buildInputs = [
    SDL
    SDL_image
    SDL_ttf
  ];

  NIX_CFLAGS_COMPILE = [
    "-I${SDL_image}/include/SDL"
    "-I${SDL_ttf}/include/SDL"
    "-Wall"
    "-Wno-error=sign-compare"
  ];

  makeFlags = [
    "PLATFORM=miyoomini"
  ];

  preConfigure = ''
    export PATH
    PATH+=":${SDL.dev}/bin"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt
    cp output/DinguxCommander $out/opt/
    cp -r res $out/opt/res

    mkdir -p $out/bin
    cat <<EOF > $out/bin/dingux-commander
    #!/bin/sh
    cd $out/opt/
    exec ./DinguxCommander "$@"
    EOF
    chmod a+x $out/bin/dingux-commander

    runHook postInstall
  '';
}
