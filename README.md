![Build Status](https://github.com/haxenme/nme/actions/workflows/main.yml/badge.svg)
![<img src="https://img.shields.io/discord/162395145352904705.svg?logo=discord" alt="Discord">](https://discordapp.com/invite/0uEuWH3spjck73Lo)

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
* `haxelib run nme build android` builds all APKs
* `haxelib run nme test android` only builds the APK required for the running devices architecture 
