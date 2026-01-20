#!/usr/bin/env bash
set -euo pipefail

VID="${QUADERNO_VID:-04c5}"
PID="${QUADERNO_PID:-1657}"

# Usage:
#   ./quaderno-sysfs-test.sh [wait_seconds]
#   QUADERNO_VID=04c5 QUADERNO_PID=1657 ./quaderno-sysfs-test.sh 30
WAIT_SECS="${1:-0}"

find_usb_device() {
  local dev
  local matches=()

  for dev in /sys/bus/usb/devices/*; do
    [ -f "$dev/idVendor" ] || continue
    [ -f "$dev/idProduct" ] || continue

    if [ "$(cat "$dev/idVendor")" = "$VID" ] && [ "$(cat "$dev/idProduct")" = "$PID" ]; then
      matches+=("$dev")
    fi
  done

  if [ "${#matches[@]}" -eq 0 ]; then
    echo "failed: no USB device found with vid:pid $VID:$PID" >&2
    exit 1
  fi

  if [ "${#matches[@]}" -gt 1 ]; then
    echo "warning: multiple USB devices match $VID:$PID; using first:" >&2
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

find_ttys() {
  shopt -s nullglob
  local found=1
  for p in "$usb_path":*/tty/ttyACM*; do
    [ -e "$p" ] || continue
    echo "tty:       /dev/$(basename "$p")   ($p)"
    found=0
  done
  return $found
}

find_ifaces() {
  shopt -s nullglob
  local found=1
  for p in "$usb_path":*/net/*; do
    [ -d "$p" ] || continue
    echo "net iface: $(basename "$p")   ($p)"
    found=0
  done
  return $found
}

echo "--- tty nodes (may disappear after RNDIS enable) ---"
find_ttys || true

echo
echo "--- net interfaces (appear after RNDIS enable) ---"
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
