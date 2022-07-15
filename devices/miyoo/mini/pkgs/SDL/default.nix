{ SDL
, miyooMiniSDK
, fetchFromGitHub
, fetchpatch }:

SDL.overrideAttrs({ buildInputs, configureFlags, ... }: {
  src = fetchFromGitHub {
    owner = "shauninman";
    repo = "SDL-1.2";
    rev = "608ebfc1ffbd9d8644dea5e51345cbe978d969b1"; # miniui-miyoomini
    sha256 = "sha256-SCqFEX9lzXNr60XjvgZcBGmD3FCSLnlR/eeF+vxST1I=";
  };
  buildInputs = buildInputs ++ [
    miyooMiniSDK
  ];
  patches = [
    # Strip any patches from the build
  ];
  configureFlags = configureFlags ++ [
    # Fix upstream code using <SDL/SDL.h>
    # XXX "--enable-miao"
    "--disable-miao"
  ];
  # By providing these LDFLAGS here, they are propagated by sdl-config.
  # https://github.com/shauninman/SDL-1.2/blob/608ebfc1ffbd9d8644dea5e51345cbe978d969b1/config.sh#L7
  LDFLAGS = [
    "-lmi_sys"
    "-lmi_ao"
    "-lmi_gfx"
    "-lcam_os_wrapper"
    #"-lmsettings"
    "-Wl,--gc-sections"
  ];
  # Ensure the SDL is propagated too...
  # This is hacky, since anyway this is a hack.
  propagatedBuildInputs = [
    miyooMiniSDK
  ];
})
