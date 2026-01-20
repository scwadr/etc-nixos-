{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.kiyurica.quaderno-sync;

  python = pkgs.python3.withPackages (ps: [ ps.pyserial ]);

  quaderno-sync-script = pkgs.writeShellScriptBin "quaderno-sync" ''
    set -euo pipefail

    SERIAL_DEV="''${SERIAL_DEV:-${lib.escapeShellArg cfg.serialDevice}}"
    MDNS_NAME="''${MDNS_NAME:-${lib.escapeShellArg cfg.mdnsName}}"

    USB_SYS_PATH="''${USB_SYS_PATH:-}"
    QUADERNO_VID="''${QUADERNO_VID:-${lib.escapeShellArg cfg.autoSync.vendorId}}"
    QUADERNO_PID="''${QUADERNO_PID:-${lib.escapeShellArg cfg.autoSync.productId}}"

    usb_path=""
    if [ -n "$USB_SYS_PATH" ]; then
      usb_path="$(readlink -f "$USB_SYS_PATH")"
    fi

    if [ -z "$usb_path" ]; then
      for dev in /sys/bus/usb/devices/*; do
        [ -f "$dev/idVendor" ] || continue
        [ -f "$dev/idProduct" ] || continue
        if [ "$(cat "$dev/idVendor")" = "$QUADERNO_VID" ] && [ "$(cat "$dev/idProduct")" = "$QUADERNO_PID" ]; then
          usb_path="$dev"
          break
        fi
      done
    fi

    if [ -z "$usb_path" ] || [ ! -e "$usb_path/idVendor" ]; then
      echo "quaderno-sync: failed to locate Quaderno USB device ($QUADERNO_VID:$QUADERNO_PID)" >&2
      exit 1
    fi

    echo "quaderno-sync: using usb device: $usb_path ($(cat "$usb_path/idVendor"):$(cat "$usb_path/idProduct"))" >&2

    shopt -s nullglob

    iface=""
    for p in "$usb_path":*/net/*; do
      if [ -d "$p" ]; then
        iface="$(basename "$p")"
        break
      fi
    done

    if [ -n "$iface" ]; then
      echo "quaderno-sync: found existing net interface: $iface" >&2
    else
      echo "quaderno-sync: no net interface yet; will try enabling RNDIS" >&2
    fi

    if [ -z "$iface" ]; then
      # RNDIS isn't up yet; try to enable it over the Quaderno's serial interface (if present).
      if [ ! -e "$SERIAL_DEV" ]; then
        SERIAL_DEV=""
        for p in "$usb_path":*/tty/ttyACM*; do
          if [ -e "$p" ]; then
            SERIAL_DEV="/dev/$(basename "$p")"
            break
          fi
        done
      fi

      if [ -z "$SERIAL_DEV" ] || [ ! -e "$SERIAL_DEV" ]; then
        echo "quaderno-sync: no net interface and no ttyACM serial interface to enable RNDIS" >&2
        exit 1
      fi

      echo "quaderno-sync: enabling RNDIS via serial: $SERIAL_DEV" >&2

      export SERIAL_DEV
      python3 -c 'import os, serial; port = serial.Serial(os.environ["SERIAL_DEV"]); port.write(b"\x01\x00\x00\x01\x00\x00\x00\x01\x00\x04"); port.close()'

      for _ in $(seq 1 ${toString cfg.interfaceWaitSeconds}); do
        for p in "$usb_path":*/net/*; do
          if [ -d "$p" ]; then
            iface="$(basename "$p")"
            break
          fi
        done
        if [ -n "$iface" ]; then
          break
        fi
        sleep 1
      done
    fi

    if [ -z "$iface" ]; then
      echo "quaderno-sync: timed out waiting for Quaderno RNDIS interface" >&2
      exit 1
    fi

    echo "quaderno-sync: using net interface: $iface" >&2

    echo "quaderno-sync: resolving mDNS: $MDNS_NAME" >&2
    ip6="$(avahi-resolve -n "$MDNS_NAME" | awk '{print $2}' | head -n1 || true)"
    if [ -z "$ip6" ]; then
      echo "quaderno-sync: failed to resolve $MDNS_NAME via avahi" >&2
      exit 1
    fi

    addr="[$ip6%$iface]"

    # Forward script args to dptrp1, injecting --addr <addr> if missing.
    if [ "$#" -eq 0 ]; then
      set -- sync
    fi

    has_addr=0
    for a in "$@"; do
      case "$a" in
        --addr|--addr=*) has_addr=1 ;;
      esac
    done

    if [ "$has_addr" -eq 0 ]; then
      set -- "$@" --addr "$addr"
    fi

    echo "quaderno-sync: running: dptrp1 $*" >&2
    exec dptrp1 "$@"
  '';

  quaderno-sync-env = pkgs.symlinkJoin {
    name = "quaderno-sync-env";
    paths = [
      quaderno-sync-script
      python
    ]
    ++ (with pkgs; [
      iproute2
      gawk
      coreutils
      avahi
      dptrp1
    ]);
  };

in
{
  options.kiyurica.quaderno-sync = {
    enable = lib.mkEnableOption "Fujitsu Quaderno Gen 2 sync (RNDIS + dptrp1)";

    autoSync = {
      enable = lib.mkEnableOption "auto-run quaderno-sync on USB connect";

      vendorId = lib.mkOption {
        type = lib.types.str;
        default = "04c5";
        description = "USB vendor ID of the Quaderno.";
      };

      productId = lib.mkOption {
        type = lib.types.str;
        default = "1657";
        description = "USB product ID of the Quaderno.";
      };

    };

    serialDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/ttyACM0";
      description = "Serial device to send the RNDIS enable command to.";
    };

    mdnsName = lib.mkOption {
      type = lib.types.str;
      default = "Android.local";
      description = "mDNS name to resolve for the Quaderno over RNDIS.";
    };

    interfaceWaitSeconds = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Seconds to wait for the RNDIS network interface to appear.";
    };

    syncLocalPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.services.syncthing.settings.folders.inaba.path}/quaderno";
      description = "Local path for `dptrp1 sync <local_path>`.";
    };

    dptrp1Args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "sync"
        cfg.syncLocalPath
      ];
      description = "Arguments passed to dptrp1. If --addr is omitted, an appropriate address setting is injected.";
    };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = [ quaderno-sync-env ];

    # User service (runs as whichever user is currently logged in)
    systemd.user.services.quaderno-sync = lib.mkIf cfg.autoSync.enable {
      description = "Sync Fujitsu Quaderno";
      wantedBy = [ ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = "%h";
        Environment = [
          "QUADERNO_VID=${cfg.autoSync.vendorId}"
          "QUADERNO_PID=${cfg.autoSync.productId}"
        ];
        ExecStart = "${quaderno-sync-env}/bin/quaderno-sync ${lib.escapeShellArgs cfg.dptrp1Args}";
      };
    };

    services.udev.extraRules = lib.mkAfter (
      lib.optionalString cfg.autoSync.enable ''
        ACTION=="add", SUBSYSTEM=="usb", DEVTYPE=="usb_device", ATTR{idVendor}=="${cfg.autoSync.vendorId}", ATTR{idProduct}=="${cfg.autoSync.productId}", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="quaderno-sync.service"
      ''
    );

    services.avahi.enable = lib.mkDefault true;
  };
}
