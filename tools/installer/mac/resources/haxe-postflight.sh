#!/bin/sh

sudo rm -rf /usr/bin/haxe
sudo rm -rf /usr/bin/haxedoc
sudo rm -rf /usr/bin/haxelib

sudo ln -s /usr/lib/haxe/haxe /usr/bin/haxe
sudo ln -s /usr/lib/haxe/haxedoc /usr/bin/haxedoc
sudo ln -s /usr/lib/haxe/haxelib /usr/bin/haxelib
