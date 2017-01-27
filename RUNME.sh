#!/bin/bash

# CHIP customiser / first run
# Author: norgeous
# tested with 4.4.13-ntc-mlc headless image

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

OPTIONS=$(whiptail --title "CHIP customiser" --checklist --separate-output \
"Choose your options" 12 33 6 \
"update" "" OFF \
"first_run" "" OFF \
"nginx" "" OFF \
"wifi_ap" "" OFF \
"pihole" "" OFF \
"motioneye" "" OFF \
"say" "" OFF \
"bluetooth_speaker" "" OFF \
"nodejs" "" OFF \
"wetty" "" OFF \
"button_menu" "" OFF \
3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
  for OPTION in $OPTIONS; do
    bash <(curl -sL https://raw.githubusercontent.com/norgeous/chip-scripts/master/scripts/$OPTION.sh)
  done
fi