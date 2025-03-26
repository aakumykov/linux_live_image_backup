#!/bin/bash

if !(which gpg > /dev/null) && !(which gpg2 > /dev/null); then
	echo "gpg or gpg2 command required but not found!" > /dev/stderr
	exit 1
fi

which dirmngr > /dev/null || {
	echo "dirmngr command required but not found!" > /dev/stderr
	exit 1
}

sudo apt-key adv --fetch-keys https://cpkg.datto.com/DATTO-PKGS-GPG-KEY
echo "deb [arch=amd64] https://cpkg.datto.com/datto-deb/public/$(lsb_release -sc) $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/datto-linux-agent.list
sudo apt-get update
sudo apt-get install dattobd-dkms dattobd-utils
