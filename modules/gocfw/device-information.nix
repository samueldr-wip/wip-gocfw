{ config, lib, ... }:

let
  inherit (config.wip.gocfw) device-information;
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
in
{
  options = {
    wip.gocfw = {
      device-information = {
        display = {
          width = mkOption {
            description = ''
              Display width in useful pixels.

              Use as-seen orientation. In other words, if the display is used
              as landscape, width the the longer value, even if the display
              physically is portrait and rotated.
            '';
            type = types.int;
          };
          height = mkOption {
            description = ''
              Display height in useful pixels.

              Use as-seen orientation. In other words, if the display is used
              as landscape, width the the longer value, even if the display
              physically is portrait and rotated.
            '';
            type = types.int;
          };
          orientation = mkOption {
            description = "Natural orientation of the display";
            type = types.enum [ "normal" "upside-down" "clockwise" "counter-clockwise" ];
            default = "normal";
          };
          # TODO: Add option for e.g. RG280 where two "physical pixels" in width are one useful pixels
          #       -> 240 useful pixels high, but addressable as 480 pixels with "weird" arrangement
        };
        storage = {
          built-in = {
            type = mkOption {
              description = ''
                Built-in storage, if any.

                Use `sd` only when there is a removable SD card inside the
                device, but it cannot be removed externally.
              '';
              type = types.enum [ "none" "nand" "nor" "emmc" "sd" ];
            };
            size = mkOption {
              description = "Size, in bytes, of the internal storage.";
              type = types.int;
            };
          };
          external = {
            available = mkOption {
              description = ''When a "main" external storage SD card slot is available.'';
              type = types.bool;
            };
            bootable = mkOption {
              description = ''
                When the SoC can use the main storage as a bootable source

                Even though the real operating system may be stored on an
                external storage device, only enable if the SoC **can** boot
                from the external storage without involvement of an
                intermediary boot stage stored on internal storage.

                > **Tip**: For SoCs like Rockchip where the internal storage
                > is preferred, and comes with vendor-provided firmware, do
                > enable this option anyway.
                >
                > Another set of option is used to control whether the
                > intermediary boot stages are expected on external media.
              '';
              type = types.bool;
            };
          };
          additional = {
            available = mkOption {
              description = "When an additional (secondary) SD card is available.";
              type = types.bool;
              default = false;
            };
          };
        };
        input = {
          buttons = {
            power = {
              type = mkOption {
                description = ''
                  Power type, hard switch means `poweroff` will not poweroff
                  the device, and require toggling a switch.

                  > `soft-not-usable` is used when a soft power button is not
                  > usable by the userspace to trigger actions.
                  >
                  > For example, the *Funkey S* technically has its power
                  > switch in the hinge, which is used for powering off the
                  > device when closing the lid. In that instance, the power
                  > button cannot be used as neither a menu button
                  > replacement nor could it be used to do the usual suspend
                  > and poweroff routines. It also cannot be held for forcing
                  > poweroff.
                  >
                  > In this previous example, it is not `hard` since with
                  > `hard` it is assumed calling `poweroff` will not work.
                  > Calling `poweroff` works, and the system does not require
                  > an *It is safe to poweroff the device* screen at poweroff.
                '';
                type = types.enum [ "hard" "soft" "soft-not-usable" ];
              };
              held-action = mkOption {
                description = ''
                  The behaviour when the power key is held.

                  This generally should be a hardware-defined behaviour, and
                  this is not to configure what happens.

                  The `userspace` type is when nothing happens when being held,
                  but being held can be detected.

                  The `none` type is when nothing happens when being held, but
                  cannot be distinguished from a short press.
                '';
                type = types.enum [ "hard-poweroff" "reset" "userspace" "none" ];
              };
            };
            reset = {
              available = mkOption {
                description = ''
                  A `reset` button is available.

                  The button should reset the system state outright without
                  involvement from the OS or userspace.

                  If it does not, it is not considered a reset button.

                  This is used mainly to document the present of a reset
                  button, which can be used in generated documentation as a

                '';
                type = types.bool;
              };
            };
            menu = {
              available = mkOption {
                description = ''
                  A `menu` button is available.

                  This represents a button that is not meant to be used for
                  gameplay usage. This button is to be used to bring up the
                  application-specific "menu" up front.
                '';
                type = types.bool;
              };
            };
            volume = {
              type = mkOption {
                description = ''
                  Presence of volume control.

                  > `wheel-hard` represents a wheel that is not available to
                  > read from the userspace. With this volume style, volume
                  > at the OS level is always set to 100% and controlled by
                  > the assumed-to-be-sufficient volume wheel.

                  > `buttons` represents a pair of volume up and down buttons.
                  > Whether they can be read when pressed together or not is
                  > not relevant here. Due to a common design decision, it is
                  > assumed it is never possible to read both at once.

                  > `none` is used on devices where there is no user-facing
                  > volume control input.
                '';
                # NOTE: `wheel-soft` will be added if it ever is needed.
                type = types.enum [ "none" "buttons" "wheel-hard" ];
              };
            };
          };
        };
      };
    };
  };
  config = mkMerge [
    (mkIf (device-information.storage.built-in.type == "none") {
      wip.gocfw.device-information.storage.built-in.size = 0;
    })
    (mkIf (device-information.input.buttons.power.type == "hard") {
      wip.gocfw.device-information.input.buttons.power.held-action = "none";
    })
  ];
}
