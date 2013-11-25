

BUILDS := ::VALID_ARCHS::

BUILD_JOBS := $(BUILDS:%=build-haxe-%)

all:$(BUILD_JOBS) combine-libs

combine-libs:
	libtool -static  -o ::DEST_PATH:: ::APP_LIBS::

debug:
	echo $(BUILD_JOBS)

build-haxe-i386:
	@echo "Haxe simulator build"
	haxe Build.hxml -D simulator -cpp cpp $(DEBUG) $(HXCPP_CLANG)

build-haxe-armv6:
	@echo "Haxe armv6 build"
	haxe Build.hxml -D HXCPP_ARMV6 -cpp cpp $(DEBUG) $(HXCPP_CLANG)

build-haxe-armv7:
	@echo "Haxe armv7 build"
	haxe Build.hxml -D HXCPP_ARMV7 -cpp cpp $(DEBUG) $(HXCPP_CLANG)

clean:
	rm -rf armv6 armv7 i386
