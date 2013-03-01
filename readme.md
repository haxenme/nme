NME
===

NME is a game and application framework that currently targets Windows, Mac, Linux, iOS, Android, BlackBerry, Flash, HTML5, while providing legacy support for webOS.

Developers can create applications for all supported platforms with the same source code. The mobile and desktop targets are fully native -- no scripting language or virtual machine is used. This allows for greater compatibility with additional libraries and for ideal performance.

More information is available at http://www.nme.io


Release Version
===============

You can get a release installer for Windows, Mac or Linux at http://www.nme.io/download


Source Builds
=============

To use NME from the source, follow these steps:

 1. Install Haxe 3 and Neko 2, available [here](http://haxe.org/manual/haxe3).

 2. Clone this repository, then tell haxelib where it is located
 
 <pre>haxelib dev nme C:\Development\Haxe\nme</pre>

 3. Install additional Haxe libraries
 
 <pre>haxelib install format
haxelib install hxcpp
haxelib install svg
haxelib install swf
haxelib install xfl</pre>

 4. For Mac or Linux, install "nmedev"

 <pre>haxelib git nmedev https://github.com/haxenme/nmedev.git</pre>

 5. For Windows, clone https://github.com/haxenme/nmedev and tell haxelib

 <pre>haxelib dev nmedev C:\Development\Haxe\nmedev</pre>

If you need to build the command-line tools, use this command:

	nme rebuild tools

If you need to build a native library, use one of these commands:

	nme rebuild clean
	nme rebuild windows
	nme rebuild mac
	nme rebuild linux -32
	nme rebuild linux -64
	nme rebuild android
	nme rebuild blackberry
	nme rebuild ios
	nme rebuild webos

You can combine "rebuild" commands using commas, as well

	nme rebuild tools,clean,windows

The native libraries do not need to be built often, only if changes have occurred in the "project" directory. Improvements to the command-line tools may occur more often.

The requirements to build the native libraries is similar to using a release version of NME. You can find more detail on the [download](http://www.nme.io/download) page.


License
=======

The MIT License

Copyright (c) 2007-2013 NME Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
