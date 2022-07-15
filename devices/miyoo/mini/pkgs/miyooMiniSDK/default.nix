{ runCommandNoCC, fetchurl }:


let
  rev = "c7aa5f91d7f954a8a59c3d501ecdd83b63ad8567";
  archive = fetchurl {
    url = "https://github.com/shauninman/miyoomini-toolchain-buildroot/raw/${rev}/support/my283.tar.xz";
    sha256 = "sha256-Z8Lcx6rBg8Hj3Yk9uzwvE471muj8c4t6JmyY5n8ywDg=";
  };
in
runCommandNoCC "miyooMiniSDK" {
  inherit archive;

} ''
  libs=(
    libcam_os_wrapper.a
    libcam_os_wrapper.so
    libmi_ai.a
    libmi_ai.so
    libmi_ao.a
    libmi_ao.so
    libmi_common.a
    libmi_common.so
    libmi_disp.a
    libmi_disp.so
    libmi_divp.a
    libmi_divp.so
    libmi_gfx.a
    libmi_gfx.so
    libmi_ipu.a
    libmi_ipu.so
    libmi_panel.a
    libmi_panel.so
    libmi_sed.a
    libmi_sed.so
    libmi_sys.a
    libmi_sys.so
    libmi_vdec.a
    libmi_vdec.so
    libmi_venc.a
    libmi_venc.so
    libmi_wlan.a
    libmi_wlan.so

    # Unneeded, prefer upstream
    #libSDL-1.2.so.0.11.4
    #libSDL_image-1.2.so.0.8.4
    #libSDL_mixer-1.2.so.0.12.0
    #libSDL_ttf-2.0.so.0.10.1
    #libbz2.so.1.0.6
    #libcjson.a
    #libcjson.so
    #libfreetype.so.6.17.1
    #libg711.a
    #libg711.so
    #libg726.a
    #libg726.so
    #libmad.so.0.2.1
    #libpng.so.3.56.0
    #libpng12.so.0.56.0
    #librsautil.so
    #libshmvar.so
    #libz.so.1.2.11
    #libz.so.1.2.8

    # Unneeded bloat from vendor
    #libAEC_LINUX.a
    #libAEC_LINUX.so
    #libAED_LINUX.a
    #libAED_LINUX.so
    #libAPC_LINUX.a
    #libAPC_LINUX.so
    #libBF_LINUX.a
    #libBF_LINUX.so
    #libSRC_LINUX.a
    #libSRC_LINUX.so
    #libSSL_LINUX.a
    #libSSL_LINUX.so
    #libcam_fs_wrapper.a
    #libcam_fs_wrapper.so
    #libgamename.so
    #libssgfx.so
    #libtmenu.so
    #libwifi_api.so
  )

  tar xf $archive
  cd my283/usr
  mkdir -vp $out
  cp -vr include $out/include
  mkdir -vp $out/lib
  cd lib
  for lib in ''${libs[@]}; do
    cp "$lib" $out/lib/
  done
''
