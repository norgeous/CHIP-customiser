#!/bin/bash

# CHIP customiser

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

OPTIONS=$(whiptail --title "CHIP customiser v0.1" --checklist --separate-output \
"\nChoose your options, use Spacebar to select multiple options then press Enter." 16 36 6 \
"update.sh" "" OFF \
"first_run.sh" "" OFF \
"nginx_router.sh" "" OFF \
"wifi_ap.sh" "" OFF \
"pihole.sh" "" OFF \
"motioneye.sh" "" OFF \
"say.sh" "" OFF \
"bluetooth_speaker.sh" "" OFF \
"nodejs.sh" "" OFF \
"wetty.sh" "" OFF \
"button_menu.sh" "" OFF \
"syncthing.sh" "" OFF \
3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
  for OPTION in $OPTIONS; do
    bash <(curl -sL https://rawgit.com/norgeous/CHIP-customiser/master/scripts/$OPTION)
  done
fi
