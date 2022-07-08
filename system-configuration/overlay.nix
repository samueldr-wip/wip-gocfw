{ ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      SDL_ttf = super.SDL_ttf.overrideAttrs({ patches ? [], ... }: {
        patches = patches ++ [
          ../pkgs/SDL_ttf/0001-Backport-Fixed-bug-3762-Can-t-render-characters-with.patch
        ];
      });
    })
  ];
}
