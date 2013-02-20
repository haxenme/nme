
OGG_SRC := src/bitwise.c src/framing.c

OGG_OBJS := $(OGG_SRC:%.c=%.o)

libogg$(SS_LIBEXT):$(OGG_OBJS)
	$(SS_CREATELIB)$@  $(OGG_OBJS)

src/%.o:src/%.c
	$(SS_CC) $< -c $(SS_OBJOUT)$@ -Iinclude

clean:
	rm -f $(OGG_OBJS)

