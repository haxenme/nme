
ifeq ("x$(NEKO_INSTALL_PATH)","x")
   NEKO_INSTALL_PATH := /usr/lib/neko/
endif

SOURCE_FILES := $(wildcard *.cpp) $(wildcard renderer/*cpp)
OBJS := $(SOURCE_FILES:%.cpp=objs/%.o)


INCLUDE += -I/usr/include/SDL -I/usr/include/freetype2 \
           -I$(NEKO_INSTALL_PATH)/include

CFLAGS += -O2 $(INCLUDE) -fPIC

NDLL_DIR := ../ndll/Linux/

NDLL := $(NDLL_DIR)/nme.ndll

all:objs objs/renderer $(NDLL_DIR) $(NDLL)

clean:
	rm $(OBJS)

LIB_PATH = -Wl,-L/usr/lib

$(NDLL_DIR):
	mkdir -p $(NDLL_DIR)

objs:
	mkdir objs
objs/renderer:
	mkdir objs/renderer

objs/%.o:%.cpp
	g++ $(CFLAGS) -c $< -o $@
objs/renderer/%.o:renderer/%.cpp
	g++ $(CFLAGS) -c $< -o $@

LIBS := SDL_mixer SDL_image SDL_ttf SDLmain SDL GL

FULL_LIBS:= $(LIBS:%=-l%)

$(NDLL) : $(OBJS)
	gcc -shared -Wl-Bsymbolic $(OBJS) -o $(NDLL) $(LIB_PATH) $(FULL_LIBS) -lm
