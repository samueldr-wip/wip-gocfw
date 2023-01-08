{ stdenv
, SDL

# For DRM/KMS
, libdrm
, udev
, pkg-config

# To refresh the configure script
, autoconf
}:

(SDL.overrideAttrs(
  { configureFlags
  , patches ? []
  , buildInputs ? []
  , nativeBuildInputs ? []
  , ... }: {

  buildInputs = buildInputs ++ [
    libdrm
    udev
  ];

  PKG_CONFIG = "${stdenv.cc.targetPrefix}pkg-config";

  nativeBuildInputs = nativeBuildInputs ++ [
    pkg-config
    autoconf
  ];

  # Downstream SDL may ship with an outdated configure script.
  # Remove it so it's not used.
  prePatch = ''
    substituteInPlace configure.ac \
      --replace pkg-config "$PKG_CONFIG"
    rm configure
  '';

  # Not using the autoreconf hook, it doesn't play well with this old setup.
  preConfigure = ''
    sh autogen.sh
  '';

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
    "--enable-video-opengl=no"

    # NOTE: video driver is also the input driver...
    #       the kmsdrm driver wants to use udev for input, which isn't necessarily initialized.
    "--enable-video-dummy=yes"
    "--enable-video-fbcon=yes"
    # XXX opendingux / rg280
    "--enable-video-kmsdrm=yes"
    #"--enable-video-kmsdrm=no"
  ];

  NIX_CFLAGS_COMPILE = [
    #"-DFBCON_DEBUG"
    "-Wall"
    "-Werror"
    "-Wno-error=unused-function"
    "-Wno-error=unused-but-set-variable"
  ];

  patches = /*patches ++*/ [
    ./0001-fbcon-Implement-SDL_VIDEO_FBCON_ROTATION-for-32-bpp.patch
  ];

  # XXX gocfw/wip--opendingux
  src = builtins.fetchGit /Users/samuel/tmp/tmp/SDL/SDL;
}))
.override {
  pulseaudioSupport = false;
  libGLSupported = false;
  openglSupport = false;
  x11Support = false;
}
