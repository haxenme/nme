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
 
#ifndef __NME_H__
#define __NME_H__

#define RRGB( c )	(val_int( c ) >> 16 & 0xFF);
#define GRGB( c )	(val_int( c ) >> 8 & 0xFF);
#define BRGB( c )	(val_int( c ) & 0xFF);

typedef enum nme_eventtype {
	et_noevent = -1,
	et_active = 0,
	et_keydown,
	et_keyup,
	et_motion,
	et_button_down,
	et_button_up,
	et_jaxis,
	et_jball,
	et_jhat,
	et_jbutton,
	et_resize,
	et_quit,
	et_user,
	et_syswm
};

typedef enum nme_spriteanimtype {
	at_once = 0,
	at_loop,
	at_pingpong
};

#define MAX(a,b)	((a > b) ? a : b);
#define MIN(a,b)	((a < b) ? a : b);

SDL_Surface* nme_loadimage( value file );
SDL_Surface* nme_loadimage_from_bytes( value inBytes, value inLen, value inType , value inAlpha, value inAlphaLen);
void nme_surface_free( value surface );

bool IsOpenGLMode();
bool IsOpenGLScreen(SDL_Surface *inSurface);



#endif
