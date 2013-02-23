.PHONY: clean print zlib jpeg ogg vorbis freetype sdl sdl_ttf sdl_mixer always curl curl-ssl default

default:all

ifeq ("$(OS)","")
OS := $(OSTYPE)
endif
OS := $(OS:mac%=darwin)
OS := $(OS:darwin%=darwin)
OS := $(OS:linux%=linux)
OS := $(OS:Linux%=linux)
OS := $(OS:Windows%=windows)

ifeq ("$(OS)","")
OS := linux
endif

TAR_ARGS := --no-same-owner

SS_LIBEXT := .a
SS_OBJEXT := .o
SS_CC := gcc -O2
SS_OBJOUT := -o
EMPTY := 
SPACE :=  $(EMPTY) $(EMPTY)
SS_CREATELIB := ar -cr$(SPACE)
SDL_INC := ../include/SDL12
SDL := SDL-1.2.12
SS_CREATEDLL := gcc -dynamic -fPIC -o 

ifeq ("$(OS)","darwin")
  SS_MAC := 1
  export SS_MAC
  SS_CONFIG := mac
  LIB_DIR := ../bin/Mac
  JCONFIG := jconfig.mac
  SS_DLLEXT := .dylib

  # http://xquartz.macosforge.org/landing/
  # ln -s /opt/X11/include/X11 /usr/local/include/X11

  MACOSX_DEPLOYMENT_TARGET:=10.5
  export MACOSX_DEPLOYMENT_TARGET
  SS_CC := gcc -O2
  ifdef SS_64
   SS_CC += -fPIC -m64 -D_GNU_SOURCE=1 -DTARGET_API_MAC_CARBON -DTARGET_API_MAC_OSX -I/opt/X11/include
   LIB_DIR := ../bin/Mac64
  else
   SS_CC += -fPIC -m32 -D_GNU_SOURCE=1 -DTARGET_API_MAC_CARBON -DTARGET_API_MAC_OSX -I/opt/X11/include
  endif
 
endif

ifeq ("$(OS)","webos")

  ifeq ("$(PalmPDK)","")
     PalmPDK := /opt/PalmPDK
  endif

  PATH := $(PalmPDK)/arm-gcc/bin:$(PATH)


  SS_WEBOS := 1
  export SS_WEBOS
  export PATH
  SS_CONFIG := webos
  LIB_DIR := ../bin/webOS
  #JCONFIG := jconfig.mac
  SS_DLLEXT := .so
  SDL := ERROR
  SS_CC := arm-none-linux-gnueabi-gcc -mfloat-abi=softfp -DWEBOS
  SS_RANLIB :=  arm-none-linux-gnueabi-ranlib
endif


ifeq ("$(OS)","blackberry")

ifeq ("x$(BLACKBERRY_NDK_ROOT)","x")
default:
	@echo "Please set BLACKBERRY_NDK_ROOT"
endif

  #QNX_HOST := ${BLACKBERRY_NDK_ROOT}/host/win32/x86
  #QNX_TARGET := ${BLACKBERRY_NDK_ROOT}/target/qnx6

  #PATH := ${QNX_HOST}/usr/bin/:$(PATH)

  SS_BLACKBERRY := 1
  export SS_BLACKBERRY
  
ifeq ("$(ARCH)","x86")

  SS_ARCH_X86 := 1
  export SS_ARCH_X86
  
  SS_LIBEXT := -x86.a
  SS_DLLEXT := -x86.so
  SS_CC :=  i486-pc-nto-qnx6.5.0-gcc "-I${QNX_TARGET}/usr/include" -DBLACKBERRY -fpic -fPIC -O2 -fvisibility=hidden
  SS_RANLIB := i486-pc-nto-qnx6.5.0-ranlib
  SS_CREATELIB := i486-pc-nto-qnx6.5.0-ar -cr$(SPACE)
  
else

  SS_DLLEXT := .so
  SS_CC :=  arm-unknown-nto-qnx6.5.0eabi-gcc "-I${QNX_TARGET}/usr/include" -DBLACKBERRY -fpic -fPIC -O2 -fvisibility=hidden
  SS_RANLIB := arm-unknown-nto-qnx6.5.0-ranlib
  SS_CREATELIB := arm-unknown-nto-qnx6.5.0eabi-ar -cr$(SPACE)

endif
  
  SS_CONFIG := blackberry
  LIB_DIR := ../bin/BlackBerry
  #JCONFIG := jconfig.mac
  #SDL := ERROR
  
endif


ifeq ("$(OS)","android")

ifeq ("x$(ANDROID_NDK_ROOT)","x")
default:
	@echo "Please set ANDROID_NDK_ROOT"
endif

  ANDROID_HOST := $(OSTYPE)
  ANDROID_HOST := $(ANDROID_HOST:darwin%=darwin-x86)
  ANDROID_HOST := $(ANDROID_HOST:Windows%=windows)

  PATH := $(ANDROID_NDK_ROOT)/toolchains/arm-linux-androideabi-4.4.3/prebuilt/$(ANDROID_HOST)/arm-linux-androideabi/bin:$(ANDROID_NDK_ROOT)/toolchains/arm-linux-androideabi-4.4.3/prebuilt/$(ANDROID_HOST)/libexec/gcc/arm-linux-androideabi/4.4.3:$(PATH)


  SS_ANDROID := 1
  export SS_ANDROID
  SS_CONFIG := android
  LIB_DIR := ../bin/Android
  #JCONFIG := jconfig.mac
  SS_DLLEXT := .so
  SDL := ERROR
  SS_CC :=  gcc \
 "-I$(ANDROID_NDK_ROOT)/toolchains/arm-linux-androideabi-4.4.3/prebuilt/$(ANDROID_HOST)/lib/gcc/arm-linux-androideabi/4.4.3/include/" \
 "-I$(ANDROID_NDK_ROOT)/sources/cxx-stl/gnu-libstdc++/include" \
 "-I$(ANDROID_NDK_ROOT)/sources/cxx-stl/gnu-libstdc++/libs/armeabi/include" \
 "-I$(ANDROID_NDK_ROOT)/platforms/android-5/arch-arm/usr/include" \
-D_LINUX_STDDEF_H \
-fpic -fvisibility=hidden -mthumb-interwork -ffunction-sections -funwind-tables -fstack-protector -fno-short-enums -frtti -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__ -Wno-psabi -march=armv5te -mtune=xscale -msoft-float -mthumb -Os -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64 -DANDROID -Wa,--noexecstack -O2 -DNDEBUG -g -c
  SS_RANLIB := "ranlib"
endif



ifeq ("$(wildcard /Applications/Xcode.app/*)","")
  XCODE_DEVELOPER :=  /Developer
else
  XCODE_DEVELOPER :=  /Applications/Xcode.app/Contents/Developer
endif

IPHONE_VER := 6.0
ifneq ("$(VER)","")
   IPHONE_VER := $(VER)
endif

IPHONE_ARCH := armv6
ifeq ("$(ARM)","v7")
   IPHONE_ARCH := armv7
   ARCH_EXT := -v7
endif

ifeq ("$(OS)","iphoneos")
  SS_IPHONEOS := 1
  SS_LIBEXT := .iphoneos$(ARCH_EXT).a
  export SS_IPHONEOS
  export SS_IPHONE
  JCONFIG := jconfig.mac
  SS_CONFIG := iphoneos
  SS_IPHONE := 1
  LIB_DIR := ../bin/iPhone
  SDL_INC := ../include/SDL12
  SDL := ERROR
  SS_CC := $(XCODE_DEVELOPER)/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc  \
      -DIPHONE=1 -D__IPHONEOS__=1 -O2 \
      -I../../include/SDL12 -DSDL12 \
      -arch $(IPHONE_ARCH) -fmessage-length=0 -pipe -Wno-trigraphs -fpascal-strings \
      -Wreturn-type -Wunused-variable -fno-stack-protector  \
       -I$(XCODE_DEVELOPER)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(IPHONE_VER).sdk/usr/include/ \
      -isysroot $(XCODE_DEVELOPER)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(IPHONE_VER).sdk \

endif


ifeq ("$(OS)","iphonesim")
  SS_IPHONESIM := 1
  SS_LIBEXT := .iphonesim.a
  export SS_IPHONESIM
  export SS_IPHONE
  JCONFIG := jconfig.mac
  SS_CONFIG := iphonesim
  LIB_DIR := ../bin/iPhone
  SDL_INC := ../include/SDL12
  SDL := ERROR
  SS_IPHONE := 1
  SS_CC := $(XCODE_DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/usr/bin/gcc  \
      -DIPHONE=1 -D__IPHONESIM__=1 -O2 \
      -I../../include/SDL12 -DSDL12 \
      -arch i386 -fmessage-length=0 -pipe -Wno-trigraphs -fpascal-strings \
      -Wreturn-type -Wunused-variable  -fno-stack-protector \
       -I$(XCODE_DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneOS$(IPHONE_VER).sdk/usr/include/ \
      -isysroot $(XCODE_DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$(IPHONE_VER).sdk \

endif

ifeq ("$(OS)","linux")
  SS_CONFIG := linux
  SS_LINUX := 1
  export SS_LINUX
  ifeq ($(shell uname -a | cut -f 2 -d ' '),raspberrypi)
   SS_RPI := 1
   SS_CC += -fPIC -DRASPBERRYPI
   LIB_DIR := ../bin/RPi
  else
   ifdef SS_64
    SS_CC += -fPIC -m64
    LIB_DIR := ../bin/Linux64
   else
    SS_CC += -fPIC -m32
    LIB_DIR := ../bin/Linux
   endif
  endif
  export SS_ABI
  JCONFIG := jconfig.linux
  SS_DLLEXT := .dso
endif


ifeq ("$(OS)","windows")
  SS_WINDOWS := 1
  export SS_WINDOWS
  SS_CONFIG := windows
  ifdef SS_WINRT
   LIB_DIR := ../bin/WinRTx86
   SS_CC := cl.exe -nologo -MT -DWINAPI_FAMILY=WINAPI_FAMILY_APP /WX- /fp:precise -Z7 -O2 -DWINRT
  else
   LIB_DIR := ../bin/Windows
   SS_CC := cl.exe -nologo -MT -Z7 -O2 -DWIN32
  endif
  SS_LIBEXT := .lib
  JCONFIG := jconfig.vc
  SS_OBJEXT := .obj
  SS_OBJOUT := -Fo
  SS_CREATELIB := lib -out:
  SS_DLLEXT := .dll
endif


ifeq ("$(OS)","winrt")
  SS_WINDOWS := 1
  export SS_WINDOWS
  SS_WINRT := 1
  export SS_WINRT
  SS_CONFIG := winrt
  LIB_DIR := ../bin/WinRTx86
  SS_LIBEXT := .lib
  JCONFIG := jconfig.vc
  SS_CC := cl.exe -nologo -Z7 -O2 -DWIN32 -DWINAPI_FAMILY=2 "-Ic:\Program Files (x86)\Windows Kits\8.0\Include\shared" /Zl
  SS_OBJEXT := .obj
  SS_OBJOUT := -Fo
  SS_CREATELIB := lib -out:
  SS_DLLEXT := .dll
endif




export SS_CONFIG
export SS_CC
export SS_OBJOUT
export SS_OBJEXT
export SS_CREATELIB
export SS_LIBEXT
export SS_DLLEXT
export SS_CREATEDLL
export SDL_INC

all: print 

ifndef SS_ANDROID
all: zlib 
endif

ifndef SS_MAC
ifndef SS_IPHONE
ifndef SS_BLACKBERRY
#all: openal
endif
endif
endif

ifndef SS_WINRT
all: curl 
all: curl-ssl
endif

all: png 
all: jpeg 

ifndef SS_WEBOS
ifndef SS_ANDROID
ifndef SS_WINRT
all: ogg 
all: vorbis 
endif
endif
endif

all: freetype 

ifndef SS_IPHONE
ifndef SS_WEBOS
ifndef SS_ANDROID
ifndef SS_WINRT
all: smpeg 
all: sdl 
all: sdl_ttf 
all: sdl_mixer
endif
endif
endif
endif

print::
	@echo "OS: " $(OS)


# --- ZLIB ------------------------
ZLIB := zlib-1.2.3

zlib:$(ZLIB)

$(ZLIB):
	tar xvzf tars/$(ZLIB).tgz $(TAR_ARGS)
ifdef SS_WINDOWS
	cp patches/zlib/Makefile.msc $(ZLIB)/win32
	cd $(ZLIB); unset MAKEFLAGS; nmake -f win32/Makefile.msc
	cp $(ZLIB)/zlib$(SS_LIBEXT) $(LIB_DIR)/libz$(SS_LIBEXT)
else
	@echo $(OS)
	cp configs/zlib-makefile $(ZLIB)/Makefile
	cd $(ZLIB); make
	cp $(ZLIB)/libz$(SS_LIBEXT) $(LIB_DIR)
endif
ifdef SS_RANLIB
	$(SS_RANLIB) $(LIB_DIR)/libz$(SS_LIBEXT)
endif
	cp $(ZLIB)/zlib.h $(ZLIB)/zconf.h ../include

clean::
	rm -rf $(ZLIB)

	
# --- OpenAL ----------------------
OPENAL := openal-soft-1.15.1

openal:$(OPENAL)

$(OPENAL):
	tar xvzf tars/$(OPENAL).tgz $(TAR_ARGS)
	@echo $(OS)
	cd $(OPENAL)/build; cmake
	cp $(OPENAL)/libopenal-soft$(SS_LIBEXT) $(LIB_DIR)
ifdef SS_RANLIB
	$(SS_RANLIB) $(LIB_DIR)/libopenal-soft$(SS_LIBEXT)
endif

clean::
	rm -rf $(OPENAL)


# --- CURL ------------------------
CURL := curl-7.21.4

curl:$(CURL)

$(CURL):
	tar xvzf tars/$(CURL).tgz $(TAR_ARGS)
	cp configs/curl-makefile $(CURL)/lib/Makefile
	cp configs/curl_config.gcc $(CURL)/lib/curl_config.h
	cp patches/curl/curlbuild.h $(CURL)/include/curl
	cd $(CURL)/lib; make -f Makefile
	cp $(CURL)/lib/libcurl$(SS_LIBEXT) $(LIB_DIR)
ifdef SS_RANLIB
	$(SS_RANLIB) $(LIB_DIR)/libcurl$(SS_LIBEXT)
endif
	mkdir -p ../include/curl
ifndef SS_WINDOWS
	cp $(CURL)/include/curl/*.h ../include/curl
endif

clean::
	rm -rf $(CURL)

# Not used ....
# --- CURL-OPEN-SSL ------------------------

CURL_OSSL := open_ssl/curl-7.21.4

OPEN_SSL := openssl-1.0.0f

curl-ossl:$(CURL_OSSL)

$(CURL_OSSL):
	mkdir -p ossl
	cd ossl; tar xvzf ../tars/$(CURL).tgz $(TAR_ARGS)
	cd ossl; tar xvzf ../tars/$(OPEN_SSL).tgz $(TAR_ARGS)
	cp configs/curl-openssl-makefile $(CURL_OSSL)/lib/Makefile
	cp configs/curl_config_openssl.gcc $(CURL_OSSL)/lib/curl_config.h
	cp patches/curl/curlbuild.h $(CURL_OSSL)/include/curl
	cd $(CURL_OSSL)/lib; make -f Makefile
	cp $(CURL_OSSL)/lib/libcurl$(SS_LIBEXT) $(LIB_DIR)/libcurl_ssl$(SS_LIBEXT)
ifdef SS_RANLIB
	$(SS_RANLIB) $(LIB_DIR)/libcurl_ssl$(SS_LIBEXT)
endif

clean::
	rm -rf ossl


# --- CURL-SSL ------------------------

CURL_SSL := ssl/curl-7.21.4

AXTLS_SSL := axTLS-1.4.4

curl-ssl:$(CURL_SSL)

$(CURL_SSL):
	mkdir -p ssl
	cd ssl; tar xvzf ../tars/$(CURL).tgz $(TAR_ARGS)
	cd ssl; tar xvzf ../tars/$(AXTLS_SSL).tgz $(TAR_ARGS)
	cp configs/curl-ssl-makefile $(CURL_SSL)/lib/Makefile
	cp configs/curl_config.gcc $(CURL_SSL)/lib/curl_config.h
	cp configs/axTLS-config ssl/axTLS/config/.config
	cp configs/axTLS-config.h ssl/axTLS/config/config.h
	cp patches/curl/curlbuild.h $(CURL_SSL)/include/curl
	cp patches/curl/crypto_misc.c ssl/axTLS/crypto
ifdef SS_WEBOS
	cp patches/zlib.h ssl/axTLS/ssl
	cp patches/zconf.h ssl/axTLS/ssl
endif
ifdef SS_BLACKBERRY
	cp patches/zlib.h ssl/axTLS/ssl
	cp patches/zconf.h ssl/axTLS/ssl
endif
ifdef SS_LINUX
	cp patches/zlib.h ssl/axTLS/ssl
	cp patches/zconf.h ssl/axTLS/ssl
endif
	cp ssl/axTLS/ssl/ssl.h ssl/axTLS
	cd $(CURL_SSL)/lib; make -f Makefile
	cp $(CURL_SSL)/lib/libcurl$(SS_LIBEXT) $(LIB_DIR)/libcurl_ssl$(SS_LIBEXT)
ifdef SS_RANLIB
	$(SS_RANLIB) $(LIB_DIR)/libcurl_ssl$(SS_LIBEXT)
endif

clean::
	rm -rf ssl




# --- PNG ------------------------

PNG := libpng-1.2.24

png:$(PNG)

$(PNG):
	tar xvzf tars/$(PNG).tgz $(TAR_ARGS)
ifdef SS_WINDOWS
ifdef SS_WINRT
	cp configs/png-nmake-winrt $(PNG)/makefile
else
	cp configs/png-nmake-win32 $(PNG)/makefile
endif
	cd $(PNG); unset MAKEFLAGS; nmake -f makefile
else
	cp configs/png-nmake-gcc $(PNG)/makefile
	cd $(PNG); make -f makefile
endif
	cp $(PNG)/libpng$(SS_LIBEXT) $(LIB_DIR)
ifdef SS_RANLIB
	$(SS_RANLIB) $(LIB_DIR)/libpng$(SS_LIBEXT)
endif
	cp $(PNG)/png.h $(PNG)/pngconf.h ../include

clean::
	rm -rf $(PNG)


# --- JPEG ------------------------

JPEG := jpeg-6b

jpeg:$(JPEG)

$(JPEG):
	tar xvzf tars/$(JPEG).tgz $(TAR_ARGS)
	cp configs/jconfig.h configs/jconfig.mac configs/jconfig.iphoneos  configs/jconfig.vc configs/jconfig.linux $(JPEG)
ifdef SS_WINRT
	cp patches/jpeg/makefile.winrt $(JPEG)/makefile.vc
endif
ifdef SS_WINDOWS
	cd $(JPEG); unset MAKEFLAGS; nmake -f makefile.vc nodebug=1
else
	cp configs/jpeg-makefile $(JPEG)/Makefile
	cd $(JPEG); make -f Makefile nodebug=1
endif
	cp configs/jconfig.h configs/jconfig.mac configs/jconfig.iphoneos  configs/jconfig.vc configs/jconfig.linux ../include
	cp $(JPEG)/jpeglib.h  $(JPEG)/jmorecfg.h ../include
	cp $(JPEG)/libjpeg$(SS_LIBEXT) $(LIB_DIR)
ifdef SS_RANLIB
	$(SS_RANLIB) $(LIB_DIR)/libjpeg$(SS_LIBEXT)
endif

clean::
	rm -rf $(JPEG)


# --- OGG ------------------------

OGG := libogg-1.3.0

ogg:$(OGG)

$(OGG):
	tar xvzf tars/$(OGG).tgz $(TAR_ARGS)
	cp configs/ogg-config_types.h $(OGG)/include/ogg/config_types.h
	cp configs/ogg-makefile $(OGG)/Makefile
	cd $(OGG); unset MAKEFLAGS; make
	cp $(OGG)/libogg$(SS_LIBEXT) $(LIB_DIR)
	mkdir -p ../include/ogg
	cp $(OGG)/include/ogg/ogg.h ../include/ogg
	cp configs/ogg-config_types.h ../include/ogg/config_types.h
	cp $(OGG)/include/ogg/os_types.h ../include/ogg

clean::
	rm -rf $(OGG)


# --- VORBIS ------------------------

VORBIS := libvorbis-1.3.3

vorbis:$(VORBIS)

$(VORBIS):
	tar xvzf tars/$(VORBIS).tgz $(TAR_ARGS)
	cp configs/vorbis-makefile $(VORBIS)/Makefile
	cp patches/vorbis/os.h $(VORBIS)/lib
	cd $(VORBIS); make
	cp $(VORBIS)/libvorbis$(SS_LIBEXT) $(LIB_DIR)
	mkdir -p ../include/vorbis
	cp $(VORBIS)/include/vorbis/vorbisfile.h ../include/vorbis
	cp $(VORBIS)/include/vorbis/codec.h ../include/vorbis
	cp $(VORBIS)/include/vorbis/vorbisenc.h ../include/vorbis

clean::
	rm -rf $(VORBIS)


# --- FREETYPE ------------------------

FREETYPE := freetype-2.4.11

freetype:$(FREETYPE)

$(FREETYPE):
	tar xvzf tars/$(FREETYPE).tgz $(TAR_ARGS)
	cp configs/freetype-makefile $(FREETYPE)/Makefile
	cd $(FREETYPE); make
	cp $(FREETYPE)/libfreetype$(SS_LIBEXT) $(LIB_DIR)
ifdef SS_RANLIB
	$(SS_RANLIB) $(LIB_DIR)/libfreetype$(SS_LIBEXT)
endif
	cp $(FREETYPE)/include/ft2build.h ../include
	cp -r $(FREETYPE)/include/freetype ../include

clean::
	rm -rf $(FREETYPE)
	rm -rf ._$(FREETYPE)
	

# --- SMPEG ------------------------

SMPEG := smpeg

#smpeg:$(SMPEG)

$(SMPEG):
	tar xvzf tars/$(SMPEG).tgz $(TAR_ARGS)
	cp configs/smpeg-makefile $(SMPEG)/Makefile
	cp configs/smpeg-video.h $(SMPEG)/video/video.h
	cp patches/smpeg/mpeglayer3.cpp $(SMPEG)/audio
	cd $(SMPEG); make
	cp $(SMPEG)/libsmpeg$(SS_LIBEXT) $(LIB_DIR)
	cp $(SMPEG)/smpeg.h $(SMPEG)/MPEGfilter.h ../include/

clean::
	rm -rf $(SMPEG)




# --- SDL ------------------------

ifndef SS_IPHONE
SDL := SDL-1.2.15
SDL_INC := ../include/SDL12

sdl:$(SDL)

$(SDL):
	tar xzf tars/$(SDL).tgz $(TAR_ARGS)
	cp patches/SDL/SDL_config_macosx.h $(SDL)/include
	cp patches/SDL/SDL_config_linux.h $(SDL)/include
	cp patches/SDL/SDL_video.h $(SDL)/include
	cp patches/SDL/SDL_QuartzVideo-2.15.m $(SDL)/src/video/quartz/SDL_QuartzVideo.m
	mkdir -p $(SDL_INC)
	cp configs/sdl-makefile $(SDL)/Makefile
	cp patches/SDL/SDL_config.h $(SDL)/include
	cd $(SDL); make
	cp $(SDL)/libSDL$(SS_LIBEXT) $(LIB_DIR)
ifdef SS_WINDOWS
	cp $(SDL)/libSDLmain$(SS_LIBEXT) $(LIB_DIR)
	cp $(SDL)/include/*.h $(SDL_INC)
else
	cp $(SDL)/include/*.h $(SDL_INC)
endif
	cp patches/SDL/SDL_syswm.h $(SDL_INC)

clean::
	rm -rf $(SDL)


# --- SDL_TTF ------------------------

SDL_TTF := SDL_ttf-2.0.9

sdl_ttf:$(SDL_TTF)

$(SDL_TTF):
	tar xvzf tars/$(SDL_TTF).tgz $(TAR_ARGS)
	cp configs/sdl_ttf-makefile $(SDL_TTF)/Makefile
	cd $(SDL_TTF); make
	cp $(SDL_TTF)/libSDL_ttf$(SS_LIBEXT) $(LIB_DIR)
	cp $(SDL_TTF)/SDL_ttf.h ../include

clean::
	rm -rf $(SDL_TTF)

# --- SDL_IMAGE ------------------------

# SDL image is not required for NME
#SDL_IMAGE := SDL_image-1.2.7

#sdl_image:$(SDL_IMAGE)

#$(SDL_IMAGE):
	#tar xvzf tars/$(SDL_IMAGE).tgz $(TAR_ARGS)
	#cp configs/sdl_image-makefile $(SDL_IMAGE)/Makefile
	#cd $(SDL_IMAGE); make
	#cp $(SDL_IMAGE)/libSDL_image$(SS_LIBEXT) $(LIB_DIR)
	#cp $(SDL_IMAGE)/SDL_image.h ../include
#
#clean::
	#rm -rf $(SDL_IMAGE)


# --- SDL_MIXER ------------------------

SDL_MIXER := SDL_mixer-1.2.12
MIKMOD := libmikmod-3.1.12
export MIKMOD

sdl_mixer:$(SDL_MIXER)

$(SDL_MIXER):
	tar xvzf tars/$(SDL_MIXER).tgz $(TAR_ARGS)
	cd $(SDL_MIXER); unzip $(MIKMOD).zip
	cp $(SDL_MIXER)/$(MIKMOD).patched/macosx/mikmod.h $(SDL_MIXER)/$(MIKMOD).patched/include
	cp $(SDL_MIXER)/$(MIKMOD).patched/macosx/mikmod_build.h $(SDL_MIXER)/$(MIKMOD).patched/include
ifdef SS_MAC
	cp configs/sdl_mixer-config-osx $(SDL_MIXER)/$(MIKMOD).patched/include/config.h
	cp configs/sdl_mixer-config-osx $(SDL_MIXER)/$(MIKMOD).patched/macosx/config.h
endif
	cp configs/sdl_mixer-makefile $(SDL_MIXER)/Makefile
	cd $(SDL_MIXER); make
	cp $(SDL_MIXER)/libSDL_mixer$(SS_LIBEXT) $(LIB_DIR)
	cp $(SDL_MIXER)/SDL_mixer.h ../include

clean::
	rm -rf $(SDL_MIXER)


endif 

