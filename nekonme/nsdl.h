#ifndef __NME_SDL_H__
#define __NME_SDL_H__

#include <SDL.h>
#include <SDL_image.h>
#include <SDL_ttf.h>
#include <SDL_mixer.h>

#include <neko.h>

#define SURFACE( o )		(SDL_Surface*)val_data( o );
#define SOUND( o )			(Mix_Chunk*)val_data( o );
#define MUSIC( o )			(Mix_Music*)val_data( o );
#define INT_FIELD( o, f )	val_int( val_field( o, val_id( f ) ) );
#define OBJ_FIELD( o, f )	val_field( o, val_id( f ) );

#endif