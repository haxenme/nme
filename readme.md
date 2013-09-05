# NME [![Build Status](https://travis-ci.org/haxenme/NME.png?branch=master)](https://travis-ci.org/haxenme/NME)

NME is a game and application framework that currently targets Windows, Mac, Linux, iOS, Android, BlackBerry, Flash, HTML5, while providing legacy support for webOS.

Developers can create applications for all supported platforms with the same source code. The mobile and desktop targets are fully native -- no scripting language or virtual machine is used. This allows for greater compatibility with additional libraries and gives ideal performance.

Learn more about NME at http://www.nme.io

## Installation

### Release Version

You can get a release installer for Windows, Mac or Linux at http://www.nme.io/download.


### Source Builds

To use NME from the source, follow these steps:

 1. Install Haxe 3 and Neko 2, available [here](http://haxe.org/manual/haxe3).

 2. Install Haxe libraries that NME depends on:
 
 ```
 haxelib install hxcpp
 haxelib install format
 haxelib install svg
 haxelib install swf
 haxelib install xfl
 ```
 
 3. Clone this repository, then tell haxelib where it is located:
 
 ```
 haxelib dev nme C:\Development\Haxe\nme
 ```
 
 4. Make sure you can compile a simple Haxe program targeting C++.

 5. Install latest version of **nmedev**.
     * For Mac or Linux, install "nmedev":
     
     ```
     haxelib git nmedev https://github.com/haxenme/nmedev.git
     ```
     * For Windows, clone https://github.com/haxenme/nmedev, then tell haxelib where it is located:
     
     ```
     haxelib dev nmedev C:\Development\Haxe\nmedev
     ```

 6. Alias the command `haxelib run nme` as `nme`.

 ```
 haxelib run nme setup # add `sudo` in the front for Mac or Linux
 ```

 7. Build the command-line tools if needed:

 ```
 nme rebuild tools
 ```
 
 It does not need to be built often - only if changes have occurred in the **tools** directory.

 8. Build a native library, using one or more of these commands:
 
 ```
 nme rebuild clean
 nme rebuild windows
 nme rebuild mac
 nme rebuild linux -32
 nme rebuild linux -64
 nme rebuild android
 nme rebuild blackberry
 nme rebuild ios
 nme rebuild webos
 ```

 You can also combine "rebuild" commands, using commas:
 
 ```
 nme rebuild tools,clean,windows
 ```
 
 The requirements to build a native library is similar to building an NME application for that platform. You can learn more on the [NME download page](http://www.nme.io/download).

 The native libraries also do not need to be built often - only if changes have occurred in the **project** directory.

## Contribution

We accept and encourage contribution to the project.
Contribution can be in the form of:
 * Reporting / fixing bugs
 * Development of NME or NME extension
 * Documentation

Please read our [wiki](https://github.com/haxenme/NME/wiki) for more info.

## License

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
