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

It is recommended that you install a release version of NME before working from the source.

You may clone or fork this repository. Next, you should run "haxelib dev nme (path to checkout directory)" in order to tell haxelib where your development version is located.

Additional libraries for compiling NME are located in the "nmedev" haxelib. Run "haxelib install nmedev" to install on your system.

Source distributions do not include the binaries for the NME command-line tools or native libraries. You will need to compile them first.

NME includes a "rebuild" command to make this more convenient. Use "nme rebuild tools" to compile the command-line tools, or "nme rebuild windows" to compile the platform binary for Windows.


The "rebuild" command accepts a comma-delimited list of targets, including "android", "blackberry", "clean", "ios", "linux", "mac", "tools", "webos" and "windows"


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
