[![Build Status](https://travis-ci.org/haxenme/nme.svg?branch=master)](https://travis-ci.org/haxenme/nme) [![Join the chat at https://gitter.im/haxenme/nme](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/haxenme/nme?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

<img src="./assets/icons/nme.svg" align="left" width="100" height="100" />

## Native Media Engine

A proven backend for native iOS, Android, Windows, Mac and Linux

### Installation

1. Install [Haxe](http://www.haxe.org)

1. Install NME
```
haxelib install hxcpp
haxelib install nme
haxelib run nme setup
```

To install a specific version

1. Go to [NME Host](http://nmehost.com/nme)
1. Download a version, for example nme-5.5.11.zip
1. ```haxelib install ~/Downloads/nme-5.5.11.zip```

### Building applications

```
cd nme/samples/DisplayingABitmap
nme test neko
nme test cpp
nme test flash
nme test mac
nme test windows
nme test android
nme test webos
nme test ios
````

 > *Note:* `nme` is a shortcut to `haxelib run nme`

### Learning NME

Browse the [sample projects](https://github.com/haxenme/nme/tree/master/samples). Every sample project contains the _.hx_ Haxe sources and the _.nmml_ config file to build the example.

### Android

* NDK(r20) Recommended
* `haxelib run nme build android -gradle` builds all APKs
* `haxelib run nme test android -gradle` only builds the APK required for the running devices architecture 
