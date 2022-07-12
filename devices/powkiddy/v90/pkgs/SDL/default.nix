{ SDL
, fetchpatch }:

let
  rev = "8ed1bdf53580a200ffde3a55aa83ed9a885f71fc";
  miyooCFW = patch: sha256: fetchpatch {
    url = "https://github.com/MiyooCFW/toolchain/raw/${rev}/package/sdl/${patch}";
    inherit sha256;
  };
in
SDL.overrideAttrs({ patches, ... }: {
  patches = patches ++ [
    (miyooCFW "sdl-clear-fb-on-startup.patch" "sha256-/iQwn0joplpr1Jg5y8MW/Qd8GvmoDbI/hB0PGSKOIgE=")
    (miyooCFW "sdl-clear-whole-fb-on-exit.patch" "sha256-uKLKrVp8iCdnj3FJzlJOOSDk0HmBIZqLyBtZOSO+Nrk=")
    (miyooCFW "sdl-dont-restore-fb-on-exit.patch" "sha256-j4iEORD/6hgljV9+duXVuZ/9ajqFppz3usSAy6vwvjc=")
    (miyooCFW "sdl-dontclear-singlebuffer.patch" "sha256-NshdBJUGu0TvxsvFxCEB4FH7zUYCEb20QFnLcjkks0k=")
    (miyooCFW "sdl-fbcon-flip-yoffset.patch" "sha256-cW8G9fqwdCYQpuiL1vixdV/KEYbdno0feuUwZQiFQe8=")
    (miyooCFW "sdl-fbcon-waitforvsync.patch" "sha256-7VkEzth5efwFnw0rQJfSzCWMRQYxcZsFSlpBi4lWgCU=")
    (miyooCFW "sdl-fbcon-waitingpan.patch" "sha256-TI1C9YWDxhEki7LCpFpUgvGBXCNn1r4cwB/AaZ0dQJE=")
    (miyooCFW "sdl-od-002-triplebuffer.patch" "sha256-Uvn0JmYxFbWyOObLMZxkDnCUXuObWJgpbG8t7PoCMb0=")
  ];
})
