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
    systemd.services.powertop-tune = {
      description = "run powertop tunings";
      serviceConfig.ExecStart = "${pkgs.bash}/bin/sh ${config.powertop-tune.path}";
      serviceConfig.ExecStartPost = ''${pkgs.bash}/bin/bash -c 'for f in $(find /sys/bus/usb/drivers/usbhid -regex '.*\/[0-9:.-]+' -printf '%f\n' | cut -d ":" -f 1 | sort -u); do echo on >| "/sys/bus/usb/devices/$f/power/control"; done' '';
      serviceConfig.Type = "oneshot";
      wantedBy = [
        "multi-user.target"
        "sleep.target"
      ];
    };
  };
}
