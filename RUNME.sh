#!/bin/bash

# CHIP customiser

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

OPTIONS=$(whiptail --title "CHIP customiser v0.1" --checklist --separate-output \
"\nChoose your options, use Spacebar to select multiple options then press Enter." 16 33 6 \
"update" "" OFF \
"first_run" "" OFF \
"nginx_router" "" OFF \
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
    bash <(curl -sL https://rawgit.com/norgeous/CHIP-customiser/master/scripts/$OPTION.sh)
  done
fi
