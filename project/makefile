.PHONY: ndll dso

ifeq ("x$(NEKO_INSTALL_PATH)","x")
   NEKO_INSTALL_PATH := /usr/lib/neko/
endif

SDL_BASE := ../../sdl-static

SOURCE_FILES := $(wildcard *.cpp) $(wildcard renderer/*cpp)
NDLL_OBJS := $(SOURCE_FILES:%.cpp=ndll_objs/%.o)
DSO_OBJS := $(SOURCE_FILES:%.cpp=dso_objs/%.o)


INCLUDE += -I$(SDL_BASE)/include
DSO_INCLUDE  = $(INCLUDE) -I$(HXCPP)/include

DSO_CFLAGS += $(DSO_INCLUDE) -fPIC

ifdef HXCPP_DEBUG
DSO_CFLAGS += -g
else
DSO_CFLAGS += -O2
endif

all:dso

OS := $(OSTYPE:darwin%=darwin)

ifeq ("x$(OS)","xdarwin")

LIBS := X11

FULL_LIBS:= $(LIBS:%=-l%)
DSO_CFLAGS += -DSDL13
NDLL_CFLAGS += -DSDL13
FULL_LIBS += \
   $(SDL_BASE)/lib/mac/libSDL.a \
   $(SDL_BASE)/lib/mac/libSDL_mixer.a \
   $(SDL_BASE)/lib/mac/libSDL_ttf.a \
   $(SDL_BASE)/lib/mac/libSDL_image.a \
   $(SDL_BASE)/lib/mac/libogg.a \
   $(SDL_BASE)/lib/mac/libsmpeg.a \
   $(SDL_BASE)/lib/mac/libvorbis.a \
   $(SDL_BASE)/lib/mac/libfreetype.a \
   $(SDL_BASE)/lib/mac/libpng.a \
   $(SDL_BASE)/lib/mac/libjpeg.a \
   $(SDL_BASE)/lib/mac/libz.a \

FRAMEWORKS := \
   -framework IOKit \
   -framework CoreAudio \
   -framework Carbon \
   -framework AudioToolbox \
   -framework AudioUnit \
   -framework ForceFeedback \
   -framework Cocoa \
   -framework OpenGL \
   -framework QuickTime


NDLL_DIR := ../ndll/Mac/

LD_FLAGS := -fpic -fPIC -dynamiclib
NDLL_LINK +=   $(NEKO_INSTALL_PATH)/libneko.dylib 

MACBOOT := common_objs/MacBoot.o
$(MACBOOT) : MacBoot.m
	@mkdir -p common_objs
	g++ $(INCLUDE) MacBoot.m -c -o $(MACBOOT)
FULL_LIBS += $(MACBOOT) $(FRAMEWORKS)

DSO := $(NDLL_DIR)/nme.dylib
STATIC_LIB := $(NDLL_DIR)/libstatic_nme.a
IPHONE_SIM_OBJS := $(SOURCE_FILES:%.cpp=iphone_sim_objs/%.o)
IPHONE_ARM_OBJS := $(SOURCE_FILES:%.cpp=iphone_arm_objs/%.o)

IPHONE_SIM_LIB := $(NDLL_DIR)/libnme.sim.a
IPHONE_ARM_LIB := $(NDLL_DIR)/libnme.iphoneos.a

iphone : iphone_sim_objs iphone_sim_objs/renderer iphone_arm_objs iphone_arm_objs/renderer $(IPHONE_ARM_LIB) $(IPHONE_SIM_LIB)

IPHONE_SIM_CFLAGS := $(DSO_CFLAGS) -DIPHONE

IPHONE_CPP :=  /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc-4.0 -x c++
IPHONE_VER := 2.2.1
IPHONE_ARM_CFLAGS := -DIPHONE=1 \
      -I../sdl-1.3/include -DSDL13 \
      -arch armv6 -fmessage-length=0 -pipe -Wno-trigraphs -fpascal-strings \
      -fasm-blocks -Wreturn-type -Wunused-variable \
      -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(IPHONE_VER).sdk \
      -fvisibility=hidden -gdwarf-2  \
      -miphoneos-version-min=$(IPHONE_VER)



else

#LIBS := SDL_mixer SDL_image SDL_ttf SDLmain SDL GL
LIBS := GL
FULL_LIBS:= $(LIBS:%=-l%)
FULL_LIBS += ../../thirdparty/lib/static_linux/libSDLmain.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libSDL_mixer.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libSDL_image.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libSDL_ttf.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libfreetype.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libpng.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libz.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libSDL.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libvorbisfile.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libvorbisenc.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libvorbis.a
FULL_LIBS += ../../thirdparty/lib/static_linux/libogg.a
NDLL_DIR := ../ndll/Linux/
LD_FLAGS := -Wl-Bsymbolic
DSO := $(NDLL_DIR)/nme.dso
STATIC_LIB := $(NDLL_DIR)/libstatic_nme.a
endif

lib : dso ndll $(STATIC_LIB)

NDLL := $(NDLL_DIR)/nme.ndll


ndll:ndll_objs ndll_objs/renderer $(NDLL_DIR) $(NDLL)

dso:dso_objs dso_objs/renderer $(NDLL_DIR) $(DSO)


LIB_PATH = -Wl,-L../../thirdparty/lib/static_linux -Wl,-L/usr/lib -Wl,-L/opt/local/lib

$(NDLL_DIR):
	mkdir -p $(NDLL_DIR)

ndll_objs:
	mkdir ndll_objs
ndll_objs/renderer:
	mkdir ndll_objs/renderer
dso_objs:
	mkdir dso_objs
dso_objs/renderer:
	mkdir dso_objs/renderer

iphone_arm_objs:
	@mkdir iphone_arm_objs
iphone_arm_objs/renderer:
	@mkdir iphone_arm_objs/renderer
iphone_sim_objs:
	@mkdir iphone_sim_objs
iphone_sim_objs/renderer:
	@mkdir iphone_sim_objs/renderer

dso_objs/%.o:%.cpp
	g++ $(DSO_CFLAGS) -c $< -o $@
dso_objs/renderer/%.o:renderer/%.cpp
	g++ $(DSO_CFLAGS) -c $< -o $@

ndll_objs/%.o:%.cpp
	g++ $(NDLL_CFLAGS) -c $< -o $@
ndll_objs/renderer/%.o:renderer/%.cpp
	g++ $(NDLL_CFLAGS) -c $< -o $@

iphone_sim_objs/%.o:%.cpp
	g++ $(IPHONE_SIM_CFLAGS) -c $< -o $@
iphone_sim_objs/renderer/%.o:renderer/%.cpp
	g++ $(IPHONE_SIM_CFLAGS) -c $< -o $@

iphone_arm_objs/%.o:%.cpp
	$(IPHONE_CPP) $(IPHONE_ARM_CFLAGS) $(DSO_CFLAGS) -c $< -o $@
iphone_arm_objs/renderer/%.o:renderer/%.cpp
	$(IPHONE_CPP) $(IPHONE_ARM_CFLAGS) $(DSO_CFLAGS) -c $< -o $@


clean:
	- rm -rf ndll_objs dso_objs iphone_arm_objs iphone_sim_objs

$(NDLL) : $(NDLL_OBJS) $(MACBOOT)
	g++ -shared $(LD_FLAGS) $(NDLL_OBJS) -o $(NDLL) $(LIB_PATH) $(FULL_LIBS) $(NDLL_LINK) -lm
$(DSO) : $(DSO_OBJS) $(MACBOOT)
	g++ -shared $(LD_FLAGS) $(DSO_OBJS) -o $(DSO) $(LIB_PATH) $(FULL_LIBS) $(HXCPP_LINK) -lm
$(STATIC_LIB) : $(DSO_OBJS)
	ar -cr $(STATIC_LIB) $(DSO_OBJS)



ifeq ("x$(OS)","xdarwin")
$(IPHONE_SIM_LIB) : $(IPHONE_SIM_OBJS)
	ar -cr $(IPHONE_SIM_LIB) $(IPHONE_SIM_OBJS)
$(IPHONE_ARM_LIB) : $(IPHONE_ARM_OBJS)
	ar -cr $(IPHONE_ARM_LIB) $(IPHONE_ARM_OBJS)
endif




