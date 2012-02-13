#!/bin/sh

sudo rm -rf /usr/bin/neko
sudo rm -rf /usr/bin/nekoc
sudo rm -rf /usr/bin/nekotools

sudo ln -s /usr/lib/neko/neko /usr/bin/neko
sudo ln -s /usr/lib/neko/nekoc /usr/bin/nekoc
sudo ln -s /usr/lib/neko/nekotools /usr/bin/nekotools
