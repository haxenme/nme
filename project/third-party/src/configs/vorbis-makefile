
VORBIS_SRC := \
        mdct.c smallft.c block.c envelope.c \
	window.c lsp.c lpc.c analysis.c synthesis.c psy.c \
	info.c floor1.c floor0.c res0.c mapping0.c registry.c \
	codebook.c sharedbook.c lookup.c bitrate.c \
        vorbisfile.c \
        vorbisenc.c


VORBIS_OBJS := $(VORBIS_SRC:%.c=%$(SS_OBJEXT))

libvorbis$(SS_LIBEXT):$(VORBIS_OBJS)
	$(SS_CREATELIB)$@ $(VORBIS_OBJS)

%$(SS_OBJEXT):lib/%.c
	$(SS_CC) $< -c $(SS_OBJOUT)$@ -Iinclude -Ilib -I../../include 

clean:
	rm -f $(VORBIS_OBJS)

