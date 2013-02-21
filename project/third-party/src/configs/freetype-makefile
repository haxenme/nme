
FREETYPE_SRC := \
	src/autofit/autofit.c \
	src/bdf/bdf.c \
	src/cff/cff.c \
	src/base/ftbase.c \
	src/base/ftbitmap.c \
	src/cache/ftcache.c \
	src/base/ftfstype.c \
	src/base/ftgasp.c \
	src/base/ftglyph.c \
	src/gzip/ftgzip.c \
	src/base/ftinit.c \
	src/lzw/ftlzw.c \
	src/base/ftstroke.c \
	src/base/ftsystem.c \
	src/smooth/smooth.c \
	src/base/ftbbox.c \
	src/base/ftmm.c \
	src/base/ftpfr.c \
	src/base/ftsynth.c \
	src/base/fttype1.c \
	src/base/ftwinfnt.c \
	src/pcf/pcf.c \
	src/pfr/pfr.c \
	src/psaux/psaux.c \
	src/pshinter/pshinter.c \
	src/psnames/psmodule.c \
	src/raster/raster.c \
	src/sfnt/sfnt.c \
	src/truetype/truetype.c \
	src/type1/type1.c \
	src/cid/type1cid.c \
	src/type42/type42.c \
	src/winfonts/winfnt.c


VPATH:=$(dir $(FREETYPE_SRC))

#src src/autofit src/bdf src/cff src/base src/cache src/gzip src/lwz src/smooth src/pcf src/pfr src/psaux src/pshinter src/psnames src/raster src/sfnt src/truetype src/typw1 src/cid src/type42 src/winfonts

FREETYPE_OBJS := $(notdir $(FREETYPE_SRC:%.c=%$(SS_OBJEXT)))
FREETYPE_OBJS := $(FREETYPE_OBJS:%=obj/%)

libfreetype$(SS_LIBEXT):$(FREETYPE_OBJS)
	mkdir -p obj
	$(SS_CREATELIB)$@ $(FREETYPE_OBJS)

obj/%$(SS_OBJEXT):%.c
	-mkdir -p obj
	$(SS_CC) $< -c $(SS_OBJOUT)$@ -DFT2_BUILD_LIBRARY -DDARWIN_NO_CARBON -Iinclude

clean:
	rm -f $(FREETYPE_OBJS)

