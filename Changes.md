
* Respect the flash meaning of mouseEnabled, and add hitEnabled to ignore hit tests

--------------------------
* Use async callback to fill ogg buffers (stops sound stutter in ios)

5.4
--------------------------
* Add Cppia/Acadnme integration
* Added some keyboard and scaling support to PiratePig
* Added some remote shell capabilities, via "nme shell deploy=IPADDR"
* Allow opting-out of 3x ios images
* Added some function notation to substitution, eg build="{gitver:}" pulls in the repo number
* Some android sound fixes (thanks Thomas)
* Added "nocompile" target, wich runs haxe without compiling
* Loads sounds and fonts from resources if required
* Allow windows to use freetype fonts too
* Add lime extension compatibility
* Tag all classes with @:nativeProperty
* Improve fat-line rendering
* Fix ios-view
* Fix TextField cursor

--------------------------
* Use alternate serif font on Android 5
* Fixed android-view linking with EGL
* Fix alpha for non-transparent bitmaps
* Better Flixel support

--------------------------
* Separated from Lime project
* Fixed sub-pixel offset for nearest mode
* Added options for handling unhandled exceptions
* Added bluetooth functions for android
* Added lldb options for starting with debug
* Some work on frame-rate control, including working at 0 frames-per-second
* Better integraion with waxe
* Some minor tesselation improvements
* Added some missing implementations in OGLExport
* Nme tool is now linked against gm2d, not svg
* Reworked text rendering to use drawTiles - allows rotated font rendering
* Added mingw support
* Added ios8 + 64 bit suport
* Float32Array/UInt16Array/Int32Array - meaning of third parameter has changed to match JS behaviour.  Please check if this affects you.

--------------------------
* Fixed font/texture bug
* Add Camera API
* Moved to haxenme repo
5.1
--------------------------

* Allow embed on Bitmap, Font and Sound assets
* Get samples working better
* Impove the 'quick compile' options for nme
* Start on factoring out stable header files (not complete yet)
* OpengGl fixes - allow multiple attributes for uniformfv, uniformMatricfv and vertextAttribfv
* Big internal change to pixel format, but nothing outwardly visible (hopefully)
5.0
--------------------------

* Refactor assets so the mostly live outside the template code, and allow embed/not embed to mix
* Fix CURL stall with https
* Refactored IOS UIView code to allow separate application controller
* Remove some android sensor messages on wrong thread - will need to fix later
* Fixed pixel-accurate interpolation
* Add some font-paths when searching ios
* Revert android audio back to java-based.
* Allow cross-compiling of linux from mac
* Improved android refresh timing
* Some initial support for premultiplied alpha
* Drop support for asset 'libraries'
* Refactor build tool to use inheritance
* Only support opengles 2+ (shaders)
* Drop support for ios < 5.1 (still support ipad1)
* Default to the highest supported andoird API for 'target'
* Added android x86 and emulator support
* Build c++11 for IOS
* Rationalized the directory structure for templates, with one main "haxe" directory each
* Removed warnings from ios builds, and uded image catalogs
* Fix some bugs in JNI
* Re-wrote preloader to avoid templates if possible
* Dynamically load libGL on linux in case it is not there
* Use vertex-buffers for improved performance
* Build against 'nme-state' library
* Use common hxcpp builder code for multiple builds
* Remove extensions until a good way is found
* Add initial support for pre-emptive GC
* Support static linking
* Build-tool assumes 'test' command if possible
* Re-integrate waxe
* Add shader-based line anti-aliasing
* Recover samples from context lost
* Improve android timing loop
* Some initial work on premultiplied alpha
* Add androidview support
* Add iosview support
* Improve JNI class handling
* Remove some android callbacks on wrong thread
* Some work on weak references for asset caching
* Add some StageVideo handlers
* Add openfl compatibility support
* Add cocktail support

5.0.0
--------------------------
* Imported from nekonme
