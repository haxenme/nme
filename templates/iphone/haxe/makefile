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


LIB_FILE := build/$(CONFIG)/ApplicationMain$(DEBUG).$(HAXE_OS).a

ifeq ("$(ACTION)","clean")
default: clean
else
default: build-haxe
endif


export HXCPP_COMPILE_THREADS := 2

build-haxe:
	@echo "Haxe  CONFIG : $(CONFIG)"
	mkdir -p build/$(CONFIG)
	haxe Build.hxml -D iphone -D $(HAXE_OS) -cpp build/$(CONFIG) $(DEBUG)
	if ( !(cmp -s $(LIB_FILE) ../lib/ApplicationMain.a) ); then echo "Copy library..."; cp $(LIB_FILE) ../lib/ApplicationMain.a; fi

clean:
	rm -rf build
