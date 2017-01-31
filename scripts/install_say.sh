#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

if (whiptail --title "Say" --yesno "Install say?" 15 46) then

apt install -y libttspico-utils sox

cat <<EOF > /usr/bin/say
#!/bin/bash
if [ ! -L /tmp/stdout.wav ]; then 
  ln -s "/dev/stdout" "/tmp/stdout.wav"
fi
say="\$@"
echo "[say]: \$say"
pico2wave -l "en-GB" -w "/tmp/stdout.wav" ". . \$say . . " | play --volume 0.5 --type wav - > /dev/null 2>&1
EOF
chmod +x /usr/bin/say

amixer set "Power Amplifier" 50%

fi
