
HAXE_BUILDS := $(ARCHS:%=build-haxe-%)

ifeq ("$(ACTION)","clean")
default: clean
else
default: $(HAXE_BUILDS)
endif

ifeq ("$(CONFIGURATION)","Debug")
   BUILD_STYLE := Debug
endif


default: debug_print


ifeq ("$(BUILD_STYLE)","Debug")
   DEBUG := -debug
   CONFIG := Debug
else
   DEBUG :=
   CONFIG := Release
endif

HAXE_OS := $(PLATFORM_NAME)
ifeq ("$(HAXE_OS)","iphonesimulator")
   HAXE_OS := iphonesim
endif
CONFIG := $(CONFIG)-$(HAXE_OS)




debug_print:
	@echo "Make $(HAXE_BUILDS)"


LIB_BASE := build/$(CONFIG)/ApplicationMain$(DEBUG)
LIB_DEST := $(DEBUG)/libApplicationMain.a

export HXCPP_COMPILE_THREADS := 2

build-haxe-i386:
	@echo "Haxe simulator build CONFIG : $(CONFIG)"
	haxe Build.hxml -D iphone -D iphonesim -cpp build/$(CONFIG) $(DEBUG)
	cp $(LIB_BASE).iphonesim.a ../lib/i386$(LIB_DEST)
	touch ../Classes/Main.cpp


build-haxe-armv6:
	@echo "Haxe armv6 build CONFIG : $(CONFIG)"
	haxe Build.hxml -D iphone -D iphoneos -D HXCPP_ARMV6 -cpp build/$(CONFIG) $(DEBUG)
	cp $(LIB_BASE).iphoneos.a ../lib/armv6$(LIB_DEST)
	touch ../Classes/Main.cpp



build-haxe-armv7:
	@echo "Haxe armv7 build CONFIG : $(CONFIG)"
	haxe Build.hxml -D iphone -D iphoneos -D HXCPP_ARMV7 -cpp build/$(CONFIG) $(DEBUG)
	cp $(LIB_BASE).iphoneos-v7.a ../lib/armv7$(LIB_DEST)
	touch ../Classes/Main.cpp





clean:
	rm -rf build
