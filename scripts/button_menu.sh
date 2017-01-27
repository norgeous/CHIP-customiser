#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# needs fixing (put it in a github repo)
mkdir /root/j5test
cd /root/j5test
cat <<EOF > /root/j5test/index.js
var five = require('johnny-five')
var chipio = require('chip-io')
var fs = require('fs')
var exec = require('child_process').exec
exec('echo none | tee "/sys/class/leds/chip:white:status/trigger"')
var menu = [
  {
    label:'menu',
    cmd:'say nothing'
  },
  {
    label:'uptime',
    cmd:'say `date "+%I:%M %p, %A, %e %B %Y"`. `uptime -p`'
  },
  {
    label:'reboot',
    cmd:'init 6'
  },
  {
    label:'shutdown',
    cmd:'init 0'
  },
]

var board = new five.Board({
  repl: false,
  debug: false,
  io: new chipio()
})
board.on('ready', function() {
  var statusLed = new chipio.StatusLed()
  var onboardButton = new chipio.OnboardButton()
  var press_timeout
  var press_timeout_length = 1000
  var press_count = 0
  onboardButton.on('up', function() {
    statusLed.on()
    setTimeout(function(){statusLed.off()},50)
    press_count++
    clearTimeout(press_timeout)
    press_timeout = setTimeout(function(){
      if(press_count===1){
        exec('say '+menu.map(function(t,i){return (i+1)+'. '+t.label+'.'}).join(' '),function(err,stdout,stderr){})
      } else if(press_count <= menu.length){
        exec('say '+press_count+'. '+menu[press_count-1].label+'.; '+menu[press_count-1].cmd,function(err,stdout,stderr){})
      } else {
        exec('say '+press_count+'. unknown command.',function(err,stdout,stderr){})
      }
      press_count = 0
    }, press_timeout_length)
  })
})
EOF
rm -r /root/j5test/node_modules
sudo npm install chip-io johnny-five #needs sudo for some reason


cat <<EOF > /etc/systemd/system/node-j5io.service
[Unit]
Description=Node GPIO
After=network.target

[Service]
WorkingDirectory=/root/j5test
Environment=NODE_ENV=production PORT=1337
ExecStart=/usr/bin/node index.js

[Install]
WantedBy=multi-user.target
EOF
systemctl enable node-j5io
systemctl start node-j5io
