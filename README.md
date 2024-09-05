![Build Status](https://github.com/haxenme/nme/actions/workflows/main.yml/badge.svg)

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

To run with `NME_LOCAL_TOOLKIT` (the default for android now), update the submodules with:
```
git submodule init
git submodule update
```

To install a specific version

1. Go to [the releases page](https://github.com/haxenme/nme/releases)
1. Download a version, for example nme-6.3.24.zip
1. ```haxelib install ~/Downloads/nme-6.3.24.zip```

### Building applications

Create your own application, or clone a sample:

```
nme clone BunnyMark -v
cd BunnyMark
```

Build and test your application with the different backends:
```
nme cpp
nme cppia
nme jsprime
nme neko
nme android

nme update ios
 -> Build + run from XCode
````

 > *Note:* `nme` is a shortcut to `haxelib run nme`

### Learning NME

Browse the [sample projects](https://github.com/haxenme/nme/tree/master/samples). Every sample project contains the _.hx_ Haxe sources and the _.nmml_ config file to build the example.

### Android

* NDK(r20) Recommended
* `haxelib run nme build android` builds all APKs
* `haxelib run nme test android` only builds the APK required for the running devices architecture 
