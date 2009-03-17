
ifeq ("x$(NEKO_INSTALL_PATH)","x")
   NEKO_INSTALL_PATH := /usr/lib/neko/
endif

SOURCE_FILES := $(wildcard *.cpp) $(wildcard renderer/*cpp)
NDLL_OBJS := $(SOURCE_FILES:%.cpp=ndll_objs/%.o)
DSO_OBJS := $(SOURCE_FILES:%.cpp=dso_objs/%.o)


INCLUDE += -I/usr/include/SDL -I/usr/include/freetype2
NDLL_INCLUDE = $(INCLUDE) -I$(NEKO_INSTALL_PATH)/include
DSO_INCLUDE  = $(INCLUDE) -I$(HXCPP)/include

NDLL_CFLAGS += -O2 $(NDLL_INCLUDE) -fPIC
DSO_CFLAGS += -O2 $(DSO_INCLUDE) -fPIC

NDLL_DIR := ../ndll/Linux/

NDLL := $(NDLL_DIR)/nme.ndll
DSO := $(NDLL_DIR)/nme.dso

all:ndll dso

ndll:ndll_objs ndll_objs/renderer $(NDLL_DIR) $(NDLL)

dso:dso_objs dso_objs/renderer $(NDLL_DIR) $(DSO)

clean:
	- rm rf ndll_objs dso_objs 

LIB_PATH = -Wl,-L/usr/lib

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


LIBS := SDL_mixer SDL_image SDL_ttf SDLmain SDL GL

FULL_LIBS:= $(LIBS:%=-l%)

$(NDLL) : $(NDLL_OBJS)
	gcc -shared -Wl-Bsymbolic $(NDLL_OBJS) -o $(NDLL) $(LIB_PATH) $(FULL_LIBS) -lm
$(DSO) : $(DSO_OBJS)
	gcc -shared -Wl-Bsymbolic $(DSO_OBJS) -o $(DSO) $(LIB_PATH) $(FULL_LIBS) -lm
