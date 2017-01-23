#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

curl -sL https://deb.nodesource.com/setup_7.x | bash -
apt install -y nodejs build-essential
