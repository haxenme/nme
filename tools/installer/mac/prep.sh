#!/bin/sh

sudo chown -R root:admin resources/*
sudo chown root:wheel resources/actuate/usr
sudo chown root:wheel resources/actuate/usr/lib
sudo chown root:wheel resources/haxe/usr
sudo chown root:wheel resources/haxe/usr/bin
sudo chown root:wheel resources/haxe/usr/lib
sudo chown root:wheel resources/haxe/private
sudo chown root:wheel resources/haxe/private/etc
sudo chown root:wheel resources/hxcpp/usr
sudo chown root:wheel resources/hxcpp/usr/lib
sudo chown root:wheel resources/jeash/usr
sudo chown root:wheel resources/jeash/usr/lib
sudo chown root:wheel resources/neko/usr
sudo chown root:wheel resources/neko/usr/lib
sudo chown root:wheel resources/neko/usr/bin
sudo chown root:wheel resources/nme/usr
sudo chown root:wheel resources/nme/usr/lib
sudo chown root:wheel resources/swf/usr
sudo chown root:wheel resources/swf/usr/lib

sudo chmod -R 755 resources/*
sudo chmod -R 777 resources/actuate/usr/lib/haxe/*
sudo chmod -R 777 resources/hxcpp/usr/lib/haxe/*
sudo chmod -R 777 resources/jeash/usr/lib/haxe/*
sudo chmod -R 777 resources/nme/usr/lib/haxe/*
sudo chmod -R 777 resources/swf/usr/lib/haxe/*

sudo find resources/. -name '.DS_Store' -type f -delete
sudo find Installer.pmdoc/. -name '*-contents.xml' -type f -delete
