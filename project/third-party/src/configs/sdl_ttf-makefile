all:libSDL_ttf$(SS_LIBEXT)


libSDL_ttf$(SS_LIBEXT): SDL_ttf$(SS_OBJEXT)
	$(SS_CREATELIB)libSDL_ttf$(SS_LIBEXT) SDL_ttf$(SS_OBJEXT)

%$(SS_OBJEXT):%.c
	$(SS_CC) -I../../include -I../$(SDL_INC) $< -c
