Changes
=======


3.4.2
---------------
* Added support for SVG assets
* Improved OS X icons
* Added gap-free MP3 embedding in Flash
* Multiple consistency fixes for HTML5
* Corrected SharedObject support for Linux
* Fixed a regression with music on Android
* Fixed some Linux host issues
* Improved the unit tests for Flash and HTML5


3.4.1
---------------
* Added (beta) support for Apache Cordova, deploying HTML5 to Android, iOS and BlackBerry
* Added initial support for BlackBerry OS 6 and 7 devices, using HTML5
* Added (beta) support for Adobe AIR, deploying Flash to the desktop (so far)
* Improved trace() to consistently output in real-time on native targets
* Added support for <window parameters="" /> in Flash and HTML5
* Added support for <app url="" /> in Flash and HTML5
* Improved HTML5 rendering to use CSS3 transforms
* Added custom HTML5 preloader support
* Fixed HTML5 glow and drop shadow filters
* Disabled touch scrolling by default for HTML5 projects
* Improved bitmapData.draw for all platforms
* NME is now an extension, removing the need for boilerplate <ndll /> tags
* Added an OpenGL line scaling mode on native targets (used by default)
* Implemented bitmapData.noise for native targets
* Implemented displayObject.getBounds and displayObject.getRect for native targets
* Changed stage focus events to FocusEvent.FOCUS_IN and FocusEvent.FOCUS_OUT
* Fixed URLLoader for BlackBerry
* Fixed issues which occurred for launching iOS projects
* Added unit tests for bitmaps, display objects and graphics


3.4.0
---------------
* Added support for the BlackBerry simulator
* Implemented the "build" and "run" commands for iOS devices (without opening Xcode)
* Improved support for current versions of Xcode
* Added the "rebuild" command for use with development builds
* Expanded "nme setup blackberry" to help with keystore and debug token files
* Added the "clean" command and "-clean" flag to clean the export directory
* Increased the resolution support for Windows and Mac icons
* Added "-minify" and "-minify -yui" flags to help reduce HTML5 output
* Imported documentation from the open-source Flex SDK
* Added orientation and accelerometer support for HTML5
* Added multi-touch support for BlackBerry
* Updated to support Haxe 2.10
* Added "ios" preprocessor define
* Implemented Capabilities.language
* Added Lib.pause() and Lib.resume() for use with fullscreen native UI
* Added launchImage support for iOS
* Many small fixes and improvements


3.3.3
---------------
* Official support for debug and release native libraries
* Improved the windowing and shortcuts for OS X applications
* Added dynamic sound support for iOS
* Improved ByteArray support for HTML5
* Added 2x2 transforms on drawTiles
* Added "windows", "mac" and "linux" preprocessor defines
* Many small fixes and improvements

*NME-99* Linux installer fails on new Ubuntu install  
*NME-98* Waxe cpp compilation problem: ApplicationMain.hxtemplate, getAsset() method returning nothing  
*NME-97* nme/neash.geom.Rectangle unison() method bug  
*NME-96* SDL_GL Anti-aliasing bug  
*NME-94* Jeash SimpleButton impl. is missing  
*NME-93* HTTPStatusEvent: Recursive typedef is not allowed  
*NME-88* hasEventListener for MOUSE_UP on stage (iOS) fails  
*NME-87* ObjectHash breaks compilation  
*NME-86* TextField.htmlText problem on windows/C++  
*NME-85* TextField.htmlText crash  
*NME-84* Signing APK files fails because of wrong version of Java JDK  
*NME-83* Version number in NMML does not get passed through to Android APK file  
*JEASH-11* Using ObjectHash targeting HTML5 fails.  
*JEASH-5* jeash.display.SimpleButton  


3.3.2
---------------
* Jeash is now a part of NME
* Refactored to better handle multiple backends
* Updated documentation for Haxe 2.09
* Added dynamic sound support to Windows, Mac, Linux, BlackBerry and webOS
* Added release signing for BlackBerry
* Improved orientation handling for BlackBerry
* Added build numbers for iOS, Android and BlackBerry
* Improved the ObjectHash data type
* Improved stability and HTML text handling in TextFields

*NME-81* Alpha not being set for DisplayObjects with SW-rendered children  
*NME-74* Command+Q should quit the application on a Mac  


3.3.1
---------------
* Updated for Haxe 2.09
* Improved support for BlackBerry
* Improved URLLoader
* Improved accelerometer orientation

*NME-79* Compilation errors for neko on haxe 2.09  
*NME-78* Need to add a .keys() method to nme.ObjectHash  
*NME-67* DisplayObjectContainer::nmeGetObjectsUnderPoint calls itself rather than it's children  
*NME-62* BlackBerry target needs _sans, _serif, _typewriter default fonts  
*NME-56* Can't compile to Android  
*NME-55* ia32-libs-multiarch instead of ia32-libs on new linux ubuntu 11.10  
*NME-54* Hard coded path for windows blackberry bin directory  
*NME-39* TextField.wordWrap allows line breaks when a character has accents  


3.3.0
---------------
* Added native BlackBerry support.
* Added armv6/armv7 support for iOS and Android.
* Improved quality and stability when drawing shapes.
* Fixed support for older webOS devices.

*NME-52* Iphone dependency tag not working  
*NME-51* Add Lib.getURL support for Linux  
*NME-50* TriangleCulling is inverted between Flash and CPP targets (Win x64 tested)  
*NME-49* Windows crash with latest rc  
*NME-47* ObjectHash class not found  
*NME-45* Three of the Graphics classes are not defined under flash  
*NME-44* SQLite 1.06 from haxelib caused iOS build to fail  
*NME-39* TextField.wordWrap allows line breaks when a character has accents  
*NME-38* defaults _sans, typewriter not displaying on android 2.3  
*NME-37* soundChannel.stop () is not working for sounds on webOS  
*NME-35* Hardware-based bitmaps are sometimes rendering white (Windows)  
*NME-34* Events that are removed while they are still bubbling cause an error (NME 3.2)  
*NME-33* Events appear not to dispatch when the object is not added to the display list  
*NME-31* Inverted rotationY in Matrix3D.decompose  
*NME-30* Inconsistency in Matrix3D.transformVector(s)  
*NME-29* Alpha in colorTransform/concatenatedColorTransform is slightly different than Flash  
*NME-28* The <template /> tag does not create target directories if they do not exist  
*NME-27* Graphics drawn using Tilesheet.drawTiles do not register click events for the parent object  
*NME-26* Using a BlendMode or mask fails when the object has lines  
*NME-24* Calling "removeChild" when the object is not a child does not throw an error  
*NME-22* displayObjectContainer.addChildAt calls addChild internally, but it should act separately  
*NME-20* Using bitmapData.draw fails when the target includes lines  
*NME-19* Delta for MouseEvent.MOUSE_WHEEL should be reversed  
*NME-18* Custom display object events are not bubbling  
*NME-16* nme.utils.Timer does not respect a change in delay unless it is stopped and restarted  
*NME-13* Input TextFields do not respect defaultTextFormat if you don't set the text property first  
*NME-11* Use system folders for SharedObject on Mac  
*NME-7* Need to implement nme.system.Capabilities for BlackBerry  
*NME-6* Need to implement SharedObject for BlackBerry  
*NME-5* Need to implement accelerometer support for BlackBerry  
*NME-3* Android JNI is causing issues in NME 3.2  
*NME-1* Checking the size of a Shape fails when lines are included  


3.2.1
---------------
* Added "nme.text.NMEFont" to allow haxe-based fonts.
* Added "nme.display.SimpleButton" support to SWF generation.
* Resolved issues when compiling waxe-based projects that don't use NME.
* Updated "nme setup" for newer toolchains.
* Android builds now require Android NDK r7 or newer.
* iOS builds now compile for armv7 by default.
* Stability improvements and small fixes.


3.2.0
---------------
* Android applications will install to external storage (SD card) by default.
* Improved support for special directories on all targets.
* Added built-in support for SWF assets (Flash and C++ targets).
* Created a new "display" command for improved IDE support.
* Revised and improved the NMML file specification.
* Addressed "disappearing object" issues with the software renderer.
* Added support for "template" files, overwriting the default files for each target.
* URLLoader now supports HTTP POST and SSL on C++ targets.
* Added "mobile", "web" and "desktop" defines, for simplicity.
* Tilesheet.drawTiles now includes compatibility for use in Flash.
* Joystick support added for Windows, Mac and Linux.
* Improved tessellation for primitives in the hardware renderer.
* Made it possible to add additional iOS frameworks through NMML.
* Automatically handling orientation changes on iOS now.
* Many other fixes and improvements.


3.1.1
---------------
* Fixed graphics.drawTriangles (sorry!).
* Moved the drawTiles API to "nme.display.Tilesheet".
* Added Flash support for tileSheet.drawTiles.
* Improved the Flash preloader.
* Added preloader support to HTML5.
* Added "nme.utils.Timer".
* Several small fixes.


3.1.0
---------------
* Added HTML5 support (together with Jeash).
* Added support for Opera widgets, using Flash.
* Added support for Chrome apps, using Flash.
* Added multi-touch for webOS.
* Added code for NME installer.
* Added cross-publishing for Neko (experimental).
* Added "document" command for project documentation.
* Updated support for changes in XCode 4.3 and OS X Lion.
* Updated support for changes the Android SDK tools.
* Added "nme.Assets" for strong-typed, cross-platform embedded assets.
* Added "nme.net.SharedObject" support for Neko and C++ targets.
* Added "nme.JNI" to simplify Java access on Android.
* Added "nme.system.Capabilities" for screen DPI on Neko and C++.
* Added "build", "run" and "test" support for iOS.
* Added support for scale, alpha, RGB and smoothing in graphics.drawTiles.
* Added "setup" command to automate install of necessary toolchains.
* Added support for Android release-signing.
* Improved TTF and WAV embedding on Flash.
* Improved support for NME extensions.
* Many other compile, feature and consistency improvements.


3.0.0
---------------
* Added install-tool to make cross-platform development easier.
* Added webOS support.
* Added CURL support.
* Many, many improvements to flash compatibility.

 
2.0.0
---------------
* Overhauled just about everything.
* Added initial Android support.


0.3.1
---------------
* A few minor changes to make neash integration easier.
* Fixed bug with rendering PNG images to bitmaps.
* Added some font-path logic to make finding font files easier on non-windows.


0.3.0
---------------
* Major upgrade to add the flash drawing API.
* Renamed some classes to conform to the flash class structure.
* Statically link NME.ndll with SDL libraries for windows.
* Added initial Linux port.
* Removed SGE dependency.
* Added a bunch of examples.
* Added a GameBase class to simplify some tasks.


0.2.0
---------------
* Removed SDL_Net (haXe has far superior capabilities)
* Added SGE
* Removed SDL_TTF replacing it with functions in SGE
* Added Bitmap Font support from SGE
* Added scale and rotate surface support from SGE


0.1.1
---------------
* Added a couple of samples to get users going with the library


0.1.0
---------------
* Initial release of the Neko Media Engine (NME)
