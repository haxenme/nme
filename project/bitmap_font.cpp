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

DEFINE_KIND( k_bf );

/*
	FLAGS
	=================
	* SGE_BFTRANSP = 0x01 - Transparent (should usually be set).
	* SGE_BFNOCONVERT = 0x04 - Don't convert font surface to display format for faster blits.
	* SGE_BFSFONT = 0x02 - If you enabled support for SDL_img when compiling SGE you can also set the SGE_BFSFONT flag, this enables you to load Karl Bartel's SFont files.
	* SGE_BFPALETTE = 0x08 - Converts the font surface to a palette surface (8bit). Don't do this on color fonts or SFonts! Blits from the font surface will be a bit slower but sge_BF_SetColor() will be faster (O(1) instead of O(n^2)).
*/
value nme_bf_open_font( value file, value flags )
{
	val_check( file, string );
	val_check( flags, int );
	return alloc_abstract( k_bf, sge_BF_OpenFont( val_string( file ), val_int( flags ) ) );
}

value nme_bf_font_from_surface( value srf, value flags )
{
	SDL_Surface *src;
	val_check_kind( k_surf, srf );
	val_check( flags, int );

	src = SURFACE( val_kind( srf ) );
	return alloc_abstract( k_bf, sge_BF_CreateFont( src, val_int( flags ) ) );
}

value nme_bf_close_font( value font )
{
	val_check_kind( k_bf, font );
	sge_BF_CloseFont( (sge_bmpFont*)val_kind( font ) );
}

value nme_bf_set_font_color( value font, value r, value g, value b )
{
	val_check_kind( k_bf, font );
	val_check( r, int );
	val_check( g, int );
	val_check( b, int );

	sge_BF_SetColor( (sge_bmpFont*)val_kind( font ), val_int( r ), val_int( g ), val_int( b ) );
}

value nme_bf_set_font_alpha( value font, value alpha )
{
	val_check_kind( k_bf, font );
	val_check( alpha, int );

	sge_BF_SetAlpha( (sge_bmpFont*)val_kind( font ), val_int( alpha ) );
}

value nme_bf_get_font_height( value font )
{
	val_check_kind( k_bf, font );

	return alloc_int( sge_BF_GetHeight( (sge_bmpFont*)val_kind( font ) ) );
}

value nme_bf_get_font_width( value font )
{
	val_check_kind( k_bf, font );

	return alloc_int( sge_BF_GetWidth( (sge_bmpFont*)val_kind( font ) ) );
}

value nme_bf_text_size( value font, value text )
{
	SDL_Rect rect;
	value o;
	sge_bmpFont *f;
	val_check_kind( k_bf, font );
	val_check( text, string );

	f = (sge_bmpFont*)val_kind( font );

	rect = sge_BF_TextSize( f, val_string( text ) );

	o = alloc_object(NULL);
	alloc_field( o, val_id("x"), alloc_int( rect.x ) );
	alloc_field( o, val_id("y"), alloc_int( rect.y ) );
	alloc_field( o, val_id("w"), alloc_int( rect.w ) );
	alloc_field( o, val_id("h"), alloc_int( rect.h ) );

	return o;
}

value nme_bf_text_out( value srf, value font, value text, value x, value y )
{
    SDL_Rect rect;
	value o;
	SDL_Surface *src;
	sge_bmpFont *f;
	val_check_kind( k_surf, srf );
	val_check_kind( k_bf, font );
	val_check( text, string );
	val_check( x, int );
	val_check( y, int );

	src = SURFACE( srf );
	f = (sge_bmpFont*)val_kind( font );

	rect = sge_BF_textout( src, f, val_string( text ), val_int( x ), val_int( y ) );

	o = alloc_object(NULL);
	alloc_field( o, val_id("x"), alloc_int( rect.x ) );
	alloc_field( o, val_id("y"), alloc_int( rect.y ) );
	alloc_field( o, val_id("w"), alloc_int( rect.w ) );
	alloc_field( o, val_id("h"), alloc_int( rect.h ) );

	return o;
}

DEFINE_PRIM(nme_bf_open_font,2);
DEFINE_PRIM(nme_bf_font_from_surface,2);
DEFINE_PRIM(nme_bf_close_font,1);
DEFINE_PRIM(nme_bf_set_font_color,4);
DEFINE_PRIM(nme_bf_set_font_alpha,2);
DEFINE_PRIM(nme_bf_get_font_height,1);
DEFINE_PRIM(nme_bf_get_font_width,1);
DEFINE_PRIM(nme_bf_text_size,2);
DEFINE_PRIM(nme_bf_text_out,5);