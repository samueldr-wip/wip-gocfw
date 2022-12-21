{ stdenv
, libdrm
, meson
, ninja
, pkg-config
, fetchFromGitHub
}:

stdenv.mkDerivation {
  pname = "librga";
  version = "2021-01-28";

  src = fetchFromGitHub {
    owner = "Caesar-github";
    repo = "linux-rga";
    rev = "274b345f976a7b6b05bf74dcf8faf7b2e28b813d";
    sha256 = "sha256-h1Fn2vNaSZMi6wEJaAP1QYFDnWzuMU3kZpu+FBaFaHk=";
  };

  buildInputs = [
    libdrm
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];
}
