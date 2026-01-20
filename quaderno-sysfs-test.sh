#!/usr/bin/env bash
set -euo pipefail

# Quaderno Gen 2: 04c5:1656 initially (serial), then 04c5:1657 after RNDIS is enabled.
VID="${QUADERNO_VID:-04c5}"
INITIAL_PID="${QUADERNO_INITIAL_PID:-1656}"
RNDIS_PID="${QUADERNO_RNDIS_PID:-1657}"
WAIT_SECS="${1:-0}"

find_usb_device() {
  local dev
  local matches=()

  for dev in /sys/bus/usb/devices/*; do
    [ -f "$dev/idVendor" ] || continue
    [ -f "$dev/idProduct" ] || continue

    [ "$(cat "$dev/idVendor")" = "$VID" ] || continue

    local pid
    pid="$(cat "$dev/idProduct")"
    if [ "$pid" = "$INITIAL_PID" ] || [ "$pid" = "$RNDIS_PID" ]; then
      matches+=("$dev")
    fi
  done

  if [ "${#matches[@]}" -eq 0 ]; then
    echo "failed: no USB device found with vid=$VID pids=$INITIAL_PID/$RNDIS_PID" >&2
    exit 1
  fi

  if [ "${#matches[@]}" -gt 1 ]; then
    echo "warning: multiple USB devices match vid=$VID pids=$INITIAL_PID/$RNDIS_PID; using first:" >&2
    printf '  %s\n' "${matches[@]}" >&2
  fi

  echo "${matches[0]}"
}

usb_path="$(find_usb_device)"
vid="$(cat "$usb_path/idVendor")"
pid="$(cat "$usb_path/idProduct")"

echo "usb dev:   $usb_path"
echo "vid:pid:   $vid:$pid"
if [ -f "$usb_path/product" ]; then echo "product:   $(cat "$usb_path/product")"; fi
if [ -f "$usb_path/manufacturer" ]; then echo "mfr:       $(cat "$usb_path/manufacturer")"; fi
if [ -f "$usb_path/serial" ]; then echo "serial:    $(cat "$usb_path/serial")"; fi
echo

shopt -s nullglob

echo "--- tty nodes (may disappear after RNDIS enable) ---"
for p in "$usb_path":*/tty/ttyACM*; do
  [ -e "$p" ] || continue
  echo "tty:       /dev/$(basename "$p")   ($p)"
done

echo
echo "--- net interfaces (appear after RNDIS enable) ---"
find_ifaces() {
  local found=1
  local p
  for p in "$usb_path":*/net/*; do
    [ -d "$p" ] || continue
    echo "net iface: $(basename "$p")   ($p)"
    found=0
  done
  return $found
}

if ! find_ifaces; then
  for _ in $(seq 1 "$WAIT_SECS"); do
    sleep 1
    if find_ifaces; then
      exit 0
    fi
  done
  echo "no net interface found under USB device (try again after RNDIS is enabled)" >&2
  exit 2
fi
