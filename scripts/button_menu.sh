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
var board = new five.Board({
  repl: false,
  debug: false,
  io: new chipio()
})
board.on('ready', function() {
  var statusLed = new chipio.StatusLed()
  function say(text, cb, lang='en-GB') {
    //statusLed.on()
    //fs.symlink('/dev/stdout', '/tmp/stdout.wav', function(err) {
    //  exec('pico2wave -l '+lang+' -w '+'/tmp/stdout.wav'+' ". '+text.toString().replace(/"/g,"'")+'" | aplay', function(err, stdout, stderr) {
    //    console.log(stderr)
    //    fs.unlink('/tmp/stdout.wav',function(err){
    //      statusLed.off()
    //      cb && cb(err)
    //    })
    //  })
    //})
    
    statusLed.on()
    exec('say '+text.toString(), function(err, stdout, stderr) {
      statusLed.off()
      cb && cb(err)
    })
  }
  say('node ready')
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
      switch(press_count){
        case 1: say('1. menu. 2. uptime. 3. reboot. 4. shutdown.'); break;
        case 2:
          exec('date "+%I:%M %p, %A, %e %B %Y"',function(err,date,stderr){
            exec('uptime -p',function(err,uptime,stderr){
              say('2. '+date+', the device has been powered for '+uptime.replace('up ',''))
            })
          })
        break;
        case 3: say('3. rebooting',     function(){exec('init 6')}); break;
        case 4: say('4. shutting down', function(){exec('init 0')}); break;
        default: say(press_count+'. unknown command'); break;
      }
      press_count = 0
    }, press_timeout_length)
  })
})
EOF
rm -r /root/j5test/node_modules
#sudo 
npm install chip-io johnny-five

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
