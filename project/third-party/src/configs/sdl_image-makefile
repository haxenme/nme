all:libSDL_image$(SS_LIBEXT)

SOURCE := \
   IMG.c		IMG_jpg.c	IMG_png.c	IMG_tif.c	IMG_xv.c \
   IMG_bmp.c	IMG_lbm.c	IMG_pnm.c	IMG_xcf.c	IMG_xxx.c \
   IMG_gif.c	IMG_pcx.c	IMG_tga.c	IMG_xpm.c

OBJS := $(SOURCE:%.c=%$(SS_OBJEXT))

libSDL_image$(SS_LIBEXT): $(OBJS)
	$(SS_CREATELIB)libSDL_image$(SS_LIBEXT) $(OBJS)

CONFIG := \
   -DLOAD_JPG \
   -DFAST_IS_JPEG \
   -DLOAD_PNG \
   -DLOAD_GIF \
   -DLOAD_XPM \
   -DLOAD_TGA \
   -DLOAD_XV

%$(SS_OBJEXT):%.c
	$(SS_CC) $(CONFIG) -I../../include -I../$(SDL_INC) $< -c

clean:
	rm -f $(OBJS)
