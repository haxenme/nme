
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
