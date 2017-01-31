#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

if (whiptail --title "Status LED" --yesno "Disable status LED blinking? (temporary)" 15 46) then
  echo none | tee "/sys/class/leds/chip:white:status/trigger"
fi
