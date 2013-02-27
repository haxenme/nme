NME
===

NME is a game and application framework that currently targets Windows, Mac, Linux, iOS, Android, BlackBerry, Flash, HTML5, while providing legacy support for webOS.

Developers can create applications for all supported platforms with the same source code. The mobile and desktop targets are fully native -- no scripting language or virtual machine is used. This allows for greater compatibility with additional libraries and for ideal performance.

More information is available at http://www.nme.io


Download
========

You can get an installer for Windows, Mac or Linux at http://www.nme.io/download


Source
======

If you would like to use NME from the source, follow these steps:

 1. Clone NME to a new directory (like "C:\Development\Haxe\nme")

 2. Run "haxelib dev nme path/to/your/clone"

 3. Run "haxelib git nmedev https://github.com/haxenme/nmedev.git"

 4. Run "haxelib install" for format, hxcpp, svg, swf and xfl


To use the development builds, you must have Haxe 3 and Neko 2 installed.

We will attemp to keep nmedev up-to-date with binaries so you can get started without compiling. However, to be current (or if you contributing), you may need to recompile the tools or platform binaries from time-to-time.

NME includes a "rebuild" command to make this simple:

	nme rebuild tools,windows


The "rebuild" command accepts a comma-delimited list of targets among the following: "android", "blackberry", "clean", "ios", "linux", "mac", "tools", "webos" and "windows"

The requirements to build for one of these platforms will be similar to when you target the platform from a release build. You can find more details on the [download page](http://www.nme.io/download).


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
