---------------------------
      HOW TO BUILD
---------------------------


For most targets, go to the /src directory, then run "make OS=platform"

Supported platforms include:

 - windows
 - darwin (Mac)
 - linux
 - webos
 - blackberry
 - android
 - iphoneos
 - iphonesim


You can run "make clean" to remove generated files (for a fresh start)


---------------------------
    PLATFORM SPECIFICS
---------------------------


BlackBerry


You must have the BlackBerry Native SDK installed. Then you should set
BLACKBERRY_NDK_ROOT with the path to the install directory.

In order to configure your environment, you should execute the "bbndk-env"
script which is located with the Native SDK. On Unix platforms you should
call "source bbndk-env.sh" and on Windows you should call "bbndk-env.bat"

Here is an example batch file for building the BlackBerry binaries from
Windows:


set BLACKBERRY_NDK_ROOT=C:\Development\BlackBerry\bbndk-2.0.0
call %BLACKBERRY_NDK_ROOT%\bbndk-env.bat
set OS=blackberry

cd src

make clean
make


If you would like to build for the simulator instead of a device, you can
also set ARCH to x86.



Windows


You must have Visual Studio C++ installed. You also need a version of "make"
available in your PATH.

With Visual Studio installed, there will be a "Visual Studio Command Prompt"
entry in the Start Menu. This will create a command-prompt which includes all
the paths and environment for compiling with VSC++ with a command-prompt.
You can also open a normal command-prompt and run the MSVC.bat file that
comes with most copies of Visual Studio.

Although there are other choices, if you're set up to compile for BlackBerry, it
already includes a Windows version of make, which should be easy to link to.

While running the Visual Studio Command Prompt, add the directory where
make is located to your path, like this:


path=%PATH%;D:\Development\BlackBerry\bbndk-2.0.0\host\win32\x86\usr\bin


Then it should be simple to build:


cd src
make


To compile for WinRT, clean the directory then define SS_WINRT:


make clean
make SS_WINRT=1 




Linux


To compile for 32-bit, use "make" normally:


cd src
make


To compile for 64-bit, clean the directory then define SS_64:


make clean
SS_64=1 make




(Details for other platforms will be added in the future)
