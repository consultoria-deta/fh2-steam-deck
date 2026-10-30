#!/bin/bash
# forza-fg.sh <fh2|fh3> <handheld|tv> <command...>
# Steam launch options:  WINEDLLOVERRIDES="winmm,dxgi,d3dcompiler_47=n,b" /path/to/forza-fg.sh fh2 handheld %command%
# Sets lsfg-vk frame generation from forza-fg.conf, turns off Proton's xalia, and optionally starts the DualSense helper.
G=${1:-fh2}; P=${2:-handheld}; shift 2
. "$(cd "$(dirname "$0")" && pwd)/forza-fg.conf"
K=$(echo "${G}_${P}" | tr a-z A-Z); FGV=${K}_FG; BV=${K}_BASE
if [ "${!FGV}" = 1 ]; then
  case "$P" in tv) export LSFGVK_PROFILE="Forza TV" ;; *) export LSFGVK_PROFILE="Forza Handheld" ;; esac
  export VKD3D_FRAME_RATE=${!BV}
else
  export DISABLE_LSFGVK=1
fi
# xalia (Proton's accessibility helper) costs ~25% of a CPU core and starves the GPU of power on the Deck.
export PROTON_USE_XALIA=0
if [ -n "$DUALSENSE_HELPER" ] && [ -f "$DUALSENSE_HELPER" ]; then
  rm -f /dev/shm/fh2-dualsense.shm
  setsid python3 -I "$DUALSENSE_HELPER" >> "$HOME/fh2-dualsense.log" 2>&1 < /dev/null &
fi
exec "$@"
