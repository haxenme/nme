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
#include <SDL_ttf.h>


// TTF_Init() must be called before using this function.
// Remember to call TTF_Quit() when done.
value nme_ttf_shaded( value* args, int nargs )
{
	if ( nargs < 9 ) failure( "not enough parameters passed to function nme_ttf_shaded. expected 9" );
	val_check_kind( args[0], k_surf ); // screen
	val_check( args[1], string ); // string
	val_check( args[2], string ); // font
	val_check( args[3], int ); // size
	val_check( args[4], int ); // x
	val_check( args[5], int ); // y
	val_check( args[6], int ); // forecolor
	val_check( args[7], int ); // backcolor
	val_check( args[8], int ); // alpha

	TTF_Font* font = TTF_OpenFont(val_string(args[2]), val_int(args[3]) );

        SDL_Color fg,bg;

        fg.r = RRGB( args[6] );
        fg.g = GRGB( args[6] );
        fg.b = BRGB( args[6] );
        bg.r = RRGB( args[7] );
        bg.g = GRGB( args[7] );
        bg.b = BRGB( args[7] );


	SDL_Surface* scr = SURFACE( args[0] );


        SDL_Surface *text_surf =TTF_RenderText_Shaded(font,val_string(args[1]),
                     fg,bg);

        SDL_Rect dest;
        dest.x = val_int(args[4]);
        dest.y = val_int(args[5]);
        dest.w = text_surf->w;
        dest.h = text_surf->h;


        SDL_BlitSurface(text_surf,0,scr,&dest);

        SDL_FreeSurface(text_surf);

	TTF_CloseFont(font);
        return alloc_int(0);
}

DEFINE_PRIM_MULT(nme_ttf_shaded);
