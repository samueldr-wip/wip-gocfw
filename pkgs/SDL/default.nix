{ SDL }:

(SDL.overrideAttrs({ configureFlags, patches ? [], ... }: {
  # Ensures nothing unneeded is built
  configureFlags = [
    "--enable-cdrom=no"

    "--enable-oss=no"
    "--enable-esd=no"
    "--enable-arts=no"
    "--enable-nas=no"
    "--enable-diskaudio=no"
    #"--enable-dummyaudio=no"

    "--enable-video-x11=no"
    "--enable-dga=no"
    "--enable-video-dga=no"
    "--enable-video-directfb=no"
    "--enable-video-svga=no"
    "--enable-video-vgl=no"
    "--enable-video-wscons=no"
    "--enable-video-aalib=no"
    "--enable-video-caca=no"
    "--enable-video-qtopia=no"
    "--enable-video-picogui=no"
    #"--enable-video-dummy=no"
    "--enable-video-opengl=no"
  ];

  NIX_CFLAGS_COMPILE = [
    #"-DFBCON_DEBUG"
    "-Wall"
    "-Werror"
    "-Wno-error=unused-function"
    "-Wno-error=unused-but-set-variable"
  ];

  patches = patches ++ [
    ./0001-fbcon-Implement-SDL_VIDEO_FBCON_ROTATION-for-32-bpp.patch
  ];
}))
.override {
  pulseaudioSupport = false;
  libGLSupported = false;
  openglSupport = false;
  x11Support = false;
}
