{ SDL_ttf }:

SDL_ttf.overrideAttrs({ patches ? [], ... }: {
  patches = patches ++ [
    ./0001-Backport-Fixed-bug-3762-Can-t-render-characters-with.patch
  ];
})
