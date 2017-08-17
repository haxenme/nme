## Building with nme-dev

The original way of building nme was to use the libraries provided by the 'nme-dev' haxelib.
To do this, you install the haxelib and run "neko build.n", possibly passing desired architectures.

## Building with Native-Toolkit

To build with the native-toolkit, you will need a single directory containing all the source code for these projects.  You can check these out from git, by first creating a directory, say ~/native-toolkit, and then getting the repos via:

```
git clone git@github.com:native-toolkit/sdl.git
git clone git@github.com:native-toolkit/png.git
git clone git@github.com:native-toolkit/jpeg.git
git clone git@github.com:native-toolkit/zlib.git
git clone git@github.com:native-toolkit/ogg.git
git clone git@github.com:native-toolkit/vorbis.git
git clone git@github.com:native-toolkit/curl.git
git clone git@github.com:native-toolkit/freetype.git
git clone git@github.com:native-toolkit/modplug.git
git clone git@github.com:native-toolkit/sdl-mixer.git
```

Set the path the your native-toolkit directory so hxcpp can see it.  This is easiest in the vars section of your .hxcpp_config.xml file, like:

 `<set name="NATIVE_TOOLKIT_PATH" value="c:/Users/Hugh/dev/native-toolkit" />`
