[![Build Status](https://travis-ci.org/haxenme/nme.png?branch=master)](https://travis-ci.org/haxenme/nme) [![Join the chat at https://gitter.im/haxenme/nme](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/haxenme/nme?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

NME
===
<img src="http://www.nmehost.com/wp-content/uploads/2014/02/nme96.png" align="left" hspace=20/>
Native Media Engine

##### NME provides a backend for native iOS, Android, Windows, Mac and Linux applications.

---

# Installation

Make sure you have installed [Haxe](http://www.haxe.org).

To get the latest released NME version, install via haxelib:  
```
haxelib install nme
haxelib run nme setup
```

Alternative: To install the current git version:  
`haxelib git nme https://github.com/haxenme/nme.git`

To install older NME versions:  
http://nmehost.com/nme

### Dependencies

To build Haxe applications using C++, install [hxcpp](https://github.com/HaxeFoundation/hxcpp) via haxelib:  
`haxelib install hxcpp` 

# Building applications

NME comes with a custom build tool to configure the application, define the assets and manage the platform settings. The application isn't configured using a _.hxml_ file but with a _.nmml_ config file.

Build applications using one of the build targets:
```
nme test sample.nmml windows
nme test sample.nmml neko
nme test sample.nmml flash
nme test sample.nmml cpp
nme test sample.nmml android
nme test sample.nmml webos
nme test sample.nmml ios
````

 > *Note:* `nme` is a shortcut to `haxelib run nme`

# Learning NME

To learn NME by example, check out the [sample projects](https://github.com/haxenme/nme/tree/master/samples). These are also included in the installation. Every sample project contains the _.hx_ Haxe sources and the _.nmml_ config file to build the example.

