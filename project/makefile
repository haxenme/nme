
ifeq ("x$(NEKO_INSTALL_PATH)","x")
   NEKO_INSTALL_PATH := /usr/lib/neko/
endif

SOURCE_FILES := $(wildcard *.cpp) $(wildcard renderer/*cpp)
NDLL_OBJS := $(SOURCE_FILES:%.cpp=ndll_objs/%.o)
DSO_OBJS := $(SOURCE_FILES:%.cpp=dso_objs/%.o)


INCLUDE += -I/usr/include/SDL -I/opt/local/include/SDL -I/usr/include/freetype2 -I/opt/local/include/freetype2 -I/usr/X11R6/include/
NDLL_INCLUDE = $(INCLUDE) -I$(NEKO_INSTALL_PATH)/include
DSO_INCLUDE  = $(INCLUDE) -I$(HXCPP)/include

NDLL_CFLAGS += -O2 $(NDLL_INCLUDE) -fPIC
DSO_CFLAGS += -O2 $(DSO_INCLUDE) -fPIC


all:ndll dso


ifeq ("x$(OSTYPE)","xdarwin")
LIBS := SDL_mixer SDL_image SDL_ttf SDLmain SDL freetype X11
FULL_LIBS:= $(LIBS:%=-l%)
NDLL_DIR := ../ndll/Mac/
LD_FLAGS := -fpic -fPIC -dynamiclib
MACBOOT := common_objs/MacBoot.o
$(MACBOOT) : MacBoot.m
	@mkdir -p common_objs
	g++ $(INCLUDE) MacBoot.m -c -o $(MACBOOT)
FULL_LIBS += $(MACBOOT) $(NEKO_INSTALL_PATH)/libneko.dylib -framework Cocoa -framework OpenGL
else
LIBS := SDL_mixer SDL_image SDL_ttf SDLmain SDL GL
FULL_LIBS:= $(LIBS:%=-l%)
NDLL_DIR := ../ndll/Linux/
LD_FLAGS := -Wl-Bsymbolic
endif

NDLL := $(NDLL_DIR)/nme.ndll
DSO := $(NDLL_DIR)/nme.dso


ndll:ndll_objs ndll_objs/renderer $(NDLL_DIR) $(NDLL)

dso:dso_objs dso_objs/renderer $(NDLL_DIR) $(DSO)

clean:
	- rm rf ndll_objs dso_objs 

LIB_PATH = -Wl,-L/usr/lib -Wl,-L/opt/local/lib

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

dso_objs/%.o:%.cpp
	g++ $(DSO_CFLAGS) -c $< -o $@
dso_objs/renderer/%.o:renderer/%.cpp
	g++ $(DSO_CFLAGS) -c $< -o $@

ndll_objs/%.o:%.cpp
	g++ $(NDLL_CFLAGS) -c $< -o $@
ndll_objs/renderer/%.o:renderer/%.cpp
	g++ $(NDLL_CFLAGS) -c $< -o $@



$(NDLL) : $(NDLL_OBJS) $(MACBOOT)
	g++ -shared $(LD_FLAGS) $(NDLL_OBJS) -o $(NDLL) $(LIB_PATH) $(FULL_LIBS) -lm
$(DSO) : $(DSO_OBJS) $(MACBOOT)
	g++ -shared $(LD_FLAGS) $(DSO_OBJS) -o $(DSO) $(LIB_PATH) $(FULL_LIBS) -lm
