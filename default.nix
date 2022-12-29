{ device ? null
, celun ? import ./celun.nix
}:

if device == null
then builtins.throw "Please provide a device with `--argstr device name`"
else

let
  device' =
    if builtins.isPath device
    then device
    else ./. + "/devices/${device}"
  ;
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
