/*
 * Copyright (c) 2006, Lee McColl Sylvester - www.designrealm.co.uk
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
 
#include "nsdl.h"
#include "nme.h"


value nme_sprite_draw( value image, value screen, value rect, value point )
{
	val_check( rect, object );
	val_check( point, object );
	val_check_kind( image, k_surf );
	val_check_kind( screen, k_surf );

	SDL_Surface* imageSurface = SURFACE( image );
	SDL_Surface* screenSurface = SURFACE( screen );
	
	SDL_Rect srcRect;
	srcRect.x = val_int( val_field( rect, val_id( "x" ) ) );
	srcRect.y = val_int( val_field( rect, val_id( "y" ) ) );
	srcRect.w = val_int( val_field( rect, val_id( "w" ) ) );
	srcRect.h = val_int( val_field( rect, val_id( "h" ) ) );

	SDL_Rect dstRect;
	dstRect.x = val_int( val_field( point, val_id( "x" ) ) );
	dstRect.y = val_int( val_field( point, val_id( "y" ) ) );
	dstRect.w = val_int( val_field( rect, val_id( "w" ) ) );
	dstRect.h = val_int( val_field( rect, val_id( "h" ) ) );

        int r = SDL_BlitSurface(imageSurface,&srcRect,screenSurface, &dstRect);
        return alloc_int(r);
}

/*
	FLAGS
	=================
    * 0 - Default.
    * SGE_TAA - Use the interpolating renderer. Much slower but can look better.
    * SGE_TSAFE - Don't asume that the src and dst surfaces has the same pixel format. This is the default when the two surfaces don't have the same BPP. This is slower but will render weird pixel formats right.
    * SGE_TTMAP - Use texture mapping. This is a bit faster but the result isn't as nice as in the normal mode. This mode will also ignore the px/py coordinates and the other flags. 

	To get optimal performance PLEASE make sure that the two surfaces has the same pixel format (color depth) and doesn't use 24-bpp.
*/
value nme_sprite_transform( value *args, int nargs )
{
   failure("nme_sprite_transform - not implemented");
   return alloc_int(0);
   /*
	if ( nargs < 10 ) failure( "not enough arguments supplied to function nme_sprite_transform. expected 10." );
	SDL_Surface *src = SURFACE( args[0] );
	SDL_Surface *dst = SURFACE( args[1] );
	float angle = (float)val_number( args[2] );
	float xscale = (float)val_number( args[3] );
	float yscale = (float)val_number( args[4] );
	Uint16 px = (int)val_int( args[5] );
	Uint16 py = (int)val_int( args[6] );
	Uint16 qx = (int)val_int( args[7] );
	Uint16 qy = (int)val_int( args[8] );
	Uint8 flags = (int)val_int( args[9] );

	SDL_Rect rect = SPG_TransformSurface( src, dst, angle, xscale, yscale, px, py, qx, qy, flags);
	value o = alloc_object(NULL);
	alloc_field( o, val_id("x"), alloc_int( rect.x ) );
	alloc_field( o, val_id("y"), alloc_int( rect.y ) );
	alloc_field( o, val_id("w"), alloc_int( rect.w ) );
	alloc_field( o, val_id("h"), alloc_int( rect.h ) );
	return o;
    */
}

value nme_sprite_transform_surface( value *args, int nargs )
{
   failure("nme_sprite_transform_surface - not implemented");
   return alloc_int(0);
   /*
	if ( nargs < 6 ) failure( "not enough arguments supplied to function nme_sprite_transform_surface. expected 6." );
	SDL_Surface *src = SURFACE( args[0] );
	Uint32 bgcolor = val_int( args[1] );
	float angle = val_number( args[2] );
	float xscale = val_number( args[3] );
	float yscale = val_number( args[4] );
	Uint8 flags = val_int( args[5] );

	return alloc_abstract( k_surf, SPG_Transform( src, bgcolor, angle, xscale, yscale, flags ) );
        */
}

value nme_sprite_alpha( value sprite, value alpha )
{
	val_check_kind( sprite, k_surf );
	val_check( alpha, int );
	Uint8 a = (Uint8) val_int( alpha );
	SDL_Surface* srf = SURFACE( sprite );
	SDL_SetAlpha( srf, SDL_RLEACCEL | SDL_SRCALPHA, a );

	return alloc_int( 0 );
}

value nme_sprite_init( value file )
{
	val_check( file, string );

	SDL_Surface* bitmap;
	bitmap = nme_loadimage( file );
	if ( !bitmap ) failure( SDL_GetError() );

	value v = alloc_abstract( k_surf, bitmap );
	val_gc( v, nme_surface_free );
	return v;
}

DEFINE_PRIM(nme_sprite_init, 1);
DEFINE_PRIM(nme_sprite_draw, 4);
DEFINE_PRIM_MULT(nme_sprite_transform);
DEFINE_PRIM_MULT(nme_sprite_transform_surface);
DEFINE_PRIM(nme_sprite_alpha, 2);
