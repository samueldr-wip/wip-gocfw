{ stdenv
, runtimeShell
, luajit
, SDL
, SDL_ttf
, SDL_image
}:

stdenv.mkDerivation {
  pname = "games-os-hello";
  version = "20220707";

  # XXX
  src = builtins.fetchGit /Users/samuel/Network/dashdingo.local/tmp/launcher/sdl-luajit-launcher;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin

    cat >> $out/bin/hello <<EOF
    #!${runtimeShell}
    export LD_LIBRARY_PATH
    LD_LIBRARY_PATH+=:${SDL.out}/lib:${SDL_ttf.out}/lib:${SDL_image.out}/lib
    export APP_PATH
    APP_PATH="\''${BASH_SOURCE[0]%/*}/../share/games-os-hello"
    exec ${luajit}/bin/luajit "\$APP_PATH/hello.lua" "\$@"
    EOF
    chmod +x $out/bin/hello

    mkdir -p $out/share/games-os-hello
    cp -vt $out/share/games-os-hello/ *.lua
    cp -vr resources $out/share/games-os-hello/resources

    runHook postInstall
  '';

}
