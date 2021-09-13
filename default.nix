{ device ? null
, celun ? import ./celun.nix
}:

if device == null
then builtins.throw "Please provide a device with `--arg device name`"
else

let
  device' = ./. + "/devices/${device}";
in

import (celun + /lib/eval-with-configuration.nix) {
  device = device';
  verbose = true;
  configuration = {
    imports = [
      ./system-configuration/configuration.nix
    ];
  };
}
