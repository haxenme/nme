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
#include <stack>
#include <string.h>
#include <SDL_ttf.h>

#ifdef WIN32
#include <windows.h>
#endif
#include <GL/gl.h>

using namespace std;

// helper functions


DEFINE_KIND( k_surf );
DEFINE_KIND( k_snd );
DEFINE_KIND( k_mus );


SDL_Surface* nme_loadimage( value file )
{
	val_check( file, string );

	SDL_Surface* surf;
	surf = IMG_Load( val_string( file ) );
	if ( !surf )
		surf = SDL_LoadBMP( val_string( file ) );
	if ( !surf )
		return NULL;
	//SDL_Surface *surface = SDL_DisplayFormat( surf );
  	//SDL_FreeSurface( surf );
	return surf;
}

// creates a surface with alpha channel
value nme_create_image_32( value flags, value width, value height )
{
	val_check( flags, int );
	val_check( width, int );
	val_check( height, int );

//	return alloc_abstract( k_surf, sge_CreateAlphaSurface( val_int( flags ), val_int( width ), val_int( height ) ) );
	return alloc_int(0);
}

value nme_copy_surface( value surf )
{
	return alloc_int(0);
	/*
	val_check_kind( surf, k_surf );
	
	SDL_Surface* scr = SURFACE(surf);

	return alloc_abstract( k_surf, sge_copy_surface( scr ) );
	*/
}



// surface relative functions




static value nme_surface_clear( value surf, value c )
{
	val_check_kind( surf, k_surf );
	
	val_check( c, int );
	SDL_Surface* scr = SURFACE(surf);

	Uint8 r = RRGB( c );
	Uint8 g = GRGB( c );
	Uint8 b = BRGB( c );

        if (IsOpenGLScreen(scr))
        {
           int w = scr->w;
           int h = scr->h;
           glViewport(0,0,w,h);
           glMatrixMode(GL_PROJECTION);
           glLoadIdentity();
           glOrtho(0,w, h,0, -1000,1000);
           glMatrixMode(GL_MODELVIEW);
           glLoadIdentity();
           glClearColor((GLclampf)(r/255.0),
                        (GLclampf)(g/255.0),
                        (GLclampf)(b/255.0),
                        (GLclampf)1.0 );
           glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        }
        else
        {
	   SDL_FillRect( scr, NULL, SDL_MapRGB( scr->format, r, g, b ) );
        }

	return alloc_int( 0 );
	
}

value nme_surface_width( value surface )
{
	val_check_kind( surface, k_surf );

	SDL_Surface* surf = SURFACE(surface);
        return alloc_int(surf->w);
}

value nme_surface_height( value surface )
{
	val_check_kind( surface, k_surf );

	SDL_Surface* surf = SURFACE(surface);
        return alloc_int(surf->h);
}


void nme_surface_free( value surface )
{
	if ( val_is_kind( surface, k_surf ) )
	{
		val_gc( surface, NULL );

		SDL_Surface* surf = SURFACE( surface );
		SDL_FreeSurface( surf );
	}
}

value nme_surface_colourkey( value surface, value r, value g, value b )
{
	val_check_kind( surface, k_surf );
	val_check( r, int );
	val_check( g, int );
	val_check( b, int );

	SDL_Surface* surf = SURFACE( surface );
	if( !surf )
		return alloc_bool( false );
	unsigned int key = SDL_MapRGB( surf->format, val_int( r ), val_int( g ), val_int( b ) );
	SDL_SetColorKey( surf, SDL_RLEACCEL | SDL_SRCCOLORKEY, key );
	return alloc_bool( true );
}




// screen relative functions

static bool sOpenGL = false;
SDL_Surface *sOpenGLScreen = 0;
static bool sDoScissor;
SDL_Rect sScissorRect;

bool IsOpenGLMode() { return sOpenGL; }
bool IsOpenGLScreen(SDL_Surface *inSurface) { return sOpenGL && inSurface==sOpenGLScreen; }

value nme_delay( value period )
{
	val_check( period, int );
	SDL_Delay( val_int( period ) );
	return alloc_int( 0 );
}

value nme_flipbuffer( value buff )
{
   if (sOpenGL)
   {
	SDL_GL_SwapBuffers();
   }
   else
   {
	val_check_kind( buff, k_surf );

	SDL_Surface* srf = SURFACE( buff );
	SDL_Flip( srf );
	SDL_Delay( 1 );
   }

    return alloc_int( 0 );
}

value nme_swapbuffer()
{
	return alloc_int( 0 );
}


value nme_screen_flip()
{
	value o = val_this();
	val_check( o, object );
	nme_flipbuffer( val_field( o, val_id( "screen" ) ) );
	return alloc_int( 0 );
}

value AllocRect(const SDL_Rect &inRect)
{
   value r = alloc_object(0);
   alloc_field( r, val_id( "x" ), alloc_float( inRect.x ) );
   alloc_field( r, val_id( "y" ), alloc_float( inRect.y ) );
   alloc_field( r, val_id( "w" ), alloc_float( inRect.w ) );
   alloc_field( r, val_id( "h" ), alloc_float( inRect.h ) );
   return r;
}

value nme_set_clip_rect(value inSurface, value inRect)
{
   SDL_Rect rect;
   if (!val_is_null(inRect))
   {
      rect.x = (int)val_number( val_field(inRect, val_id("x")) );
      rect.y = (int)val_number( val_field(inRect, val_id("y")) );
      rect.w = (int)val_number( val_field(inRect, val_id("width")) );
      rect.h = (int)val_number( val_field(inRect, val_id("height")) );

   }
   else
      memset(&rect,0,sizeof(rect));

   if (val_is_kind(inSurface,k_surf))
   {
      SDL_Surface *surface = SURFACE(inSurface);

      if (IsOpenGLScreen(surface))
      {
         if (val_is_null(inRect))
         {
            sDoScissor = false;
            glDisable(GL_SCISSOR_TEST);
         }
         else
         {
            sDoScissor = true;
            glEnable(GL_SCISSOR_TEST);
            sScissorRect = rect;
            glScissor(sScissorRect.x,sScissorRect.y,
                      sScissorRect.w,sScissorRect.h);
         }
      }
      else
      {
         if (val_is_null(inRect))
         {
            SDL_SetClipRect(surface,0);
            SDL_GetClipRect(surface,&rect);
         }
         else
         {
            SDL_SetClipRect(surface,&rect);
         }
      }
   }

   return AllocRect(rect);
}

value nme_get_clip_rect(value inSurface)
{
   SDL_Rect rect;
   memset(&rect,0,sizeof(rect));

   if (val_is_kind(inSurface,k_surf))
   {
      SDL_Surface *surface = SURFACE(inSurface);

      if (IsOpenGLScreen(surface))
      {
         if (sDoScissor)
            rect = sScissorRect;
         else
         {
            rect.w = sOpenGLScreen->w;
            rect.h = sOpenGLScreen->h;
         }
      }
      else
      {
         SDL_GetClipRect(surface,&rect);
      }
   }

   return AllocRect(rect);
}



#define NME_FULLSCREEN 0x0001
#define NME_OPENGL     0x0002


value nme_screen_init( value width, value height, value title, value in_flags, value icon )
{
	val_check( in_flags, int );
        bool fullscreen = (val_int(in_flags) & NME_FULLSCREEN) != 0;
        bool opengl = (val_int(in_flags) & NME_OPENGL) != 0;

        sOpenGL = opengl;

        Uint32 init_flags = SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER;
        if (opengl)
           init_flags |= SDL_OPENGL;
	if ( SDL_Init( init_flags ) == -1 ) failure( SDL_GetError() );

	val_check( width, int );
	val_check( height, int );
	val_check( title, string );

	Uint32 flags = opengl ? SDL_HWSURFACE | SDL_OPENGL :
	                        SDL_HWSURFACE | SDL_DOUBLEBUF;
	int bpp = 24;

        if ( fullscreen )
        {
                flags |= SDL_FULLSCREEN;
                if (!opengl)
                    bpp = 16;
        }

	if ( val_is_string( icon ) )
	{
		SDL_Surface *icn = nme_loadimage( icon );
		if ( icn != NULL )
		{
			SDL_WM_SetIcon( icn, NULL );
		}
	}


        SDL_Surface* screen = 0;
        if (opengl)
        {
            int rgb_size[3];
            /* Initialize the display */
            switch (bpp) 
            {
            case 8:
                rgb_size[0] = 2;
                rgb_size[1] = 3;
                rgb_size[2] = 3;
                break;
            case 15:
            case 16:
                rgb_size[0] = 5;
                rgb_size[1] = 5;
                rgb_size[2] = 5;
                break;
            default:
                rgb_size[0] = 8;
                rgb_size[1] = 8;
                rgb_size[2] = 8;
                break;
            }
            SDL_GL_SetAttribute(SDL_GL_RED_SIZE, rgb_size[0]);
            SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, rgb_size[1]);
            SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, rgb_size[2]);
            SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, bpp);
            SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

            if ( (screen = SDL_SetVideoMode( val_int( width ), val_int( height ), bpp, flags )) == NULL) 
            {
                fprintf(stderr, "Couldn't set GL mode: %s\n", SDL_GetError());
                SDL_Quit();
                exit(1);
            }
            sOpenGLScreen = screen;
        }
        else
        {
        	screen = SDL_SetVideoMode( val_int( width ), val_int( height ), bpp, flags );
	        if (!screen) failure( SDL_GetError() );

        }
    
	if ( TTF_Init() != 0 )
		printf("unable to initialize the truetype font support\n");


	SDL_WM_SetCaption( val_string( title ), 0 );

	if ( Mix_OpenAudio( MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, 4096 ) != 0 )
		printf("unable to initialize the sound support\n");

	return alloc_abstract( k_surf, screen );
}





value nme_event()
{
	SDL_Event event;
	value evt = alloc_object(NULL);
	
	if (SDL_PollEvent(&event))
	{
		if (event.type == SDL_QUIT)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( et_quit ) );
			return alloc_object( evt );
		}
		if (event.type == SDL_KEYDOWN)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( et_keydown ) );
			alloc_field( evt, val_id( "key" ), alloc_int( event.key.keysym.sym ) );
			alloc_field( evt, val_id( "shift" ), alloc_bool( event.key.keysym.mod & KMOD_SHIFT ) );
			alloc_field( evt, val_id( "ctrl" ), alloc_bool( event.key.keysym.mod & KMOD_CTRL ) );
			alloc_field( evt, val_id( "alt" ), alloc_bool( event.key.keysym.mod & KMOD_ALT ) );
			return alloc_object( evt );
		}
		if (event.type == SDL_KEYUP)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( et_keyup ) );
			alloc_field( evt, val_id( "key" ), alloc_int( event.key.keysym.sym ) );
			alloc_field( evt, val_id( "shift" ), alloc_bool( event.key.keysym.mod & KMOD_SHIFT ) );
			alloc_field( evt, val_id( "ctrl" ), alloc_bool( event.key.keysym.mod & KMOD_CTRL ) );
			alloc_field( evt, val_id( "alt" ), alloc_bool( event.key.keysym.mod & KMOD_ALT ) );
			return alloc_object( evt );
		}
		if (event.type == SDL_MOUSEMOTION)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( et_motion ) );
			alloc_field( evt, val_id( "state" ), alloc_int( event.motion.state ) );
			alloc_field( evt, val_id( "x" ), alloc_int( event.motion.x ) );
			alloc_field( evt, val_id( "y" ), alloc_int( event.motion.y ) );
			alloc_field( evt, val_id( "xrel" ), alloc_int( event.motion.xrel ) );
			alloc_field( evt, val_id( "yrel" ), alloc_int( event.motion.yrel ) );
			return alloc_object( evt );
		}
		if (event.type == SDL_MOUSEBUTTONDOWN || event.type == SDL_MOUSEBUTTONUP)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( event.type == SDL_MOUSEBUTTONUP ?
                                                             et_button_up : et_button_down ) );
			alloc_field( evt, val_id( "state" ), alloc_int( event.button.state ) );
			alloc_field( evt, val_id( "x" ), alloc_int( event.button.x ) );
			alloc_field( evt, val_id( "y" ), alloc_int( event.button.y ) );
			alloc_field( evt, val_id( "which" ), alloc_int( event.button.which ) );
			alloc_field( evt, val_id( "button" ), alloc_int( event.button.button ) );
			return alloc_object( evt );
		}
		if (event.type == SDL_JOYAXISMOTION)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( et_jaxis ) );
			alloc_field( evt, val_id( "axis" ), alloc_int( event.jaxis.axis ) );
			alloc_field( evt, val_id( "value" ), alloc_int( event.jaxis.value ) );
			alloc_field( evt, val_id( "which" ), alloc_int( event.jaxis.which ) );
			return alloc_object( evt );
		}
		if (event.type == SDL_JOYBUTTONDOWN || event.type == SDL_JOYBUTTONUP)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( et_jbutton ) );
			alloc_field( evt, val_id( "button" ), alloc_int( event.jbutton.button ) );
			alloc_field( evt, val_id( "state" ), alloc_int( event.jbutton.state ) );
			alloc_field( evt, val_id( "which" ), alloc_int( event.jbutton.which ) );
			return alloc_object( evt );
		}
		if (event.type == SDL_JOYHATMOTION)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( et_jhat ) );
			alloc_field( evt, val_id( "button" ), alloc_int( event.jhat.hat ) );
			alloc_field( evt, val_id( "value" ), alloc_int( event.jhat.value ) );
			alloc_field( evt, val_id( "which" ), alloc_int( event.jhat.which ) );
			return alloc_object( evt );
		}
		if (event.type == SDL_JOYBALLMOTION)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( et_jball ) );
			alloc_field( evt, val_id( "ball" ), alloc_int( event.jball.ball ) );
			alloc_field( evt, val_id( "xrel" ), alloc_int( event.jball.xrel ) );
			alloc_field( evt, val_id( "yrel" ), alloc_int( event.jball.yrel ) );
			alloc_field( evt, val_id( "which" ), alloc_int( event.jball.which ) );
			return alloc_object( evt );
		}
	}
	alloc_field( evt, val_id( "type" ), alloc_int( et_noevent ) );
	return evt;
}

value nme_screen_close()
{
	Mix_CloseAudio();
	//sge_TTF_Quit();
	SDL_Quit();
	return alloc_int( 0 );
}


DEFINE_PRIM(nme_event, 0);
DEFINE_PRIM(nme_delay, 1);
DEFINE_PRIM(nme_flipbuffer, 1);


DEFINE_PRIM(nme_create_image_32,3);
DEFINE_PRIM(nme_copy_surface,1);

DEFINE_PRIM(nme_screen_init, 5);
DEFINE_PRIM(nme_screen_close, 0);

DEFINE_PRIM(nme_surface_clear, 2);
DEFINE_PRIM(nme_surface_free, 1);
DEFINE_PRIM(nme_surface_width, 1);
DEFINE_PRIM(nme_surface_height, 1);
DEFINE_PRIM(nme_surface_colourkey, 4);
DEFINE_PRIM(nme_set_clip_rect, 2);
DEFINE_PRIM(nme_get_clip_rect, 1);
