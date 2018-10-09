* Default to ndll builds for desktop
* Add winrpi for toolkit
* Default to libAngle on windows
* Ship acadnme binaries for windows/mac/linux
* Work on Winrt target - thanks Carlos
* Add Jsprime target
* Add mini http-server for js testing
* New combined .nme format for cppia and jsprime, no manifest file
* Moved haxe,nme and ios directories into "src" directory
* Reduced pre-compiled binaries to only windows32, mac64 and linux64
* Added more internal pixel formats

6.0
--------------------------

5.7
--------------------------

* Numerous other contributions - thanks everyone!
* Added some polygon clipping options
* More towards premultiplied alpha
* Some more openfl compatibility
* Fix tile sub-pixel offsets
* Android immersive mode fixes
* More native text options
* Move towards toolkit builds
* Optionally lock out multiplle instances of application
* Add smaller and lower-res icons for windows
* Fix issues with freeing sound buffers
* Add ios watch support
* ios default deployment set to "8.0".  Can be overridden with the 'deployment' attribute in the ios tag.
* Fix static linking flags

5.6
--------------------------
* Added TextField onScroll event
* Added clipboard code
* More distinction between character(text) and raw key inputs
* Some swflib compatibility changes
* Make window creation size depend on reported screen DPI
* Check haxe_ver to decide if static libraries are required
* Work in 'file copy' command for new version of haxe
* Some Windows64 fixes
* Some fixed for SDL music
* More immersive fullscreen more on android when supported
* Integrate more with the android native keyboard
* Start work on 'nme-toolkit' build
* More hide-and-seek with ios font locations (thanks codeservice)
* Updated bin location for El Capitan
* Turn off BITCODE in nme projects by default
* Correctly interpret ndll name in extension
* Allow custom intp.plist blocks on ios. (eg, facebook integration)
* Pause and resume the android rendering in response to system messages
* Simplify frame timer logic by default
* Allow multiple scroll steps per mouse wheel click
 Thanks Thomas
* Fix texture lean when clearing HardwareData
* Fix android colour format on some simulators

5.5
--------------------------

* Separate static binaries for msvc 19
* Speedups for the tile display list
* BitmapData.dispose now fully clears resources
* Fix font finding for ios 8.2+
* Added android mouse wheel support (thanks codeservice)
* Restore text event to allow non-keycode input (thanks codeservice)
* Fixed for Bitmap.copyChannel bounds (thanks Thomas)
* Allow custom iOS properties (thanks Thomas)
* Allow selection of sound engine where appropriate - eg SDL vs openAl on mac, android vs Opensl
* Added mp3 decoding for windows (post XP) and mac
* Added AudioTest sample
* Add Opensl sound backend for android
* Refactor sound support to use common code between sound engines.
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
