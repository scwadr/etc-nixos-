{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.powertop-tune.enable = lib.mkEnableOption "Tuning commands from powertop(1)";
  options.powertop-tune.path = lib.mkOption {
    type = lib.types.path;
    description = "path to the script that powertop told you to run";
  };

  config = lib.mkIf config.powertop-tune.enable {
    systemd.services.powertop-tune =
      let
        usbhidPowerControl = pkgs.writeShellScript "powertop-usbhid-power-control" ''
          set -u

          usb_devs=$(
            for hid in /sys/bus/usb/drivers/usbhid/*; do
              [ -e "$hid" ] || continue
              target=$(readlink -f "$hid" 2>/dev/null || true)
              [ -n "$target" ] || continue

              p="$target"
              while [ "$p" != "/" ] && [ "$p" != "/sys" ]; do
                b=$(basename "$p")
                if [ -e "/sys/bus/usb/devices/$b/power/control" ]; then
                  echo "$b"
                  break
                fi
                p=$(dirname "$p")
              done
            done | sort -u
          )

          for dev in $usb_devs; do
            echo on >| "/sys/bus/usb/devices/$dev/power/control" 2>/dev/null || true
          done
        '';
      in
      {
        description = "run powertop tunings";
        serviceConfig.ExecStart = "${pkgs.bash}/bin/sh ${config.powertop-tune.path}";
        serviceConfig.ExecStartPost = "${usbhidPowerControl}";
        serviceConfig.Type = "oneshot";
        wantedBy = [
          "multi-user.target"
          "sleep.target"
        ];
      };
  };
}
