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

using namespace std;

// helper functions


DEFINE_KIND( k_surf );
DEFINE_KIND( k_snd );
DEFINE_KIND( k_mus );


static SDL_Surface* nme_loadimage( value file )
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



// surface relative functions




static value nme_surface_clear( value surf, value c )
{
	val_check_kind( surf, k_surf );
	
	val_check( c, int );
	SDL_Surface* scr = SURFACE(surf);

	Uint8 r = RRGB( c );
	Uint8 g = GRGB( c );
	Uint8 b = BRGB( c );

	SDL_FillRect( scr, NULL, SDL_MapRGB( scr->format, r, g, b ) );

	return alloc_int( 0 );
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



value nme_delay( value period )
{
	val_check( period, int );
	SDL_Delay( val_int( period ) );
	return alloc_int( 0 );
}

value nme_flipbuffer( value buff )
{
	val_check_kind( buff, k_surf );

	SDL_Surface* srf = SURFACE( buff );
	SDL_Flip( srf );
	SDL_Delay( 1 );

	return alloc_int( 0 );
}

value nme_screen_flip()
{
	value o = val_this();
	val_check( o, object );
	nme_flipbuffer( val_field( o, val_id( "screen" ) ) );
	return alloc_int( 0 );
}

value nme_screen_init( value width, value height, value title, value fullscreen, value icon )
{
	if ( SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER ) == -1 ) failure( SDL_GetError() );
	
	if ( TTF_Init() != 0 )
		printf("unable to initialize the truetype font support\n");

	val_check( width, int );
	val_check( height, int );
	val_check( title, string );

	Uint32 flags = SDL_HWSURFACE | SDL_DOUBLEBUF;
	int bpp = 0;

	if ( val_is_bool( fullscreen ) )
		if ( val_bool( fullscreen ) == true )
		{
			flags |= SDL_FULLSCREEN;
			bpp = 16;
		}
	SDL_Surface* screen;

	if ( val_is_string( icon ) )
	{
		SDL_Surface *icn = nme_loadimage( icon );
		if ( icn != NULL )
		{
			SDL_WM_SetIcon( icn, NULL );
		}
	}

	screen = SDL_SetVideoMode( val_int( width ), val_int( height ), bpp, flags );
	if (!screen) failure( SDL_GetError() );

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
			return alloc_object( evt );
		}
		if (event.type == SDL_KEYUP)
		{
			alloc_field( evt, val_id( "type" ), alloc_int( et_keyup ) );
			alloc_field( evt, val_id( "key" ), alloc_int( event.key.keysym.sym ) );
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
			alloc_field( evt, val_id( "type" ), alloc_int( et_button ) );
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
	TTF_Quit();
	SDL_Quit();
	return alloc_int( 0 );
}



// sprite relative functions




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

	SDL_BlitSurface(imageSurface, &srcRect, screenSurface, &dstRect);

	return alloc_int( 0 );
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


// collision detection





/*
	SDL surface test if offset (u,v) is a transparent pixel
*/

bool nme_collision_transparentpixel(SDL_Surface *surface , int u , int v)
{
	/*assert that (u,v) offsets lie within surface*/
	if( !((u < surface->w) || (v < surface->h)) )
		return false;

	int bpp = surface->format->BytesPerPixel;
	/*here p is the address to the pixel we want to retrieve*/
	Uint8 *p = (Uint8 *)surface->pixels + v * surface->pitch + u * bpp;

	Uint32 pixelcolor;

	switch(bpp)
	{
		case(1):
			pixelcolor = *p;
		break;

		case(2):
			pixelcolor = *(Uint16 *)p;
		break;

		case(3):
			if(SDL_BYTEORDER == SDL_BIG_ENDIAN)
				pixelcolor = p[0] << 16 | p[1] << 8 | p[2];
			else
				pixelcolor = p[0] | p[1] << 8 | p[2] << 16;
		break;

		case(4):
			pixelcolor = *(Uint32 *)p;
		break;
	}

	/*test whether pixels color == color of transparent pixels for that surface*/
	return (pixelcolor == surface->format->colorkey);
}

value nme_collision_pixel( value asurf, value arect,
						  value bsurf, value brect, value point )
{
	/*Box A;
	Box B;*/
	val_check_kind( asurf, k_surf );
	val_check_kind( bsurf, k_surf );

	val_check( arect, object );
	val_check( brect, object );
	val_check( point, object );

	int x = 0;
	int y = 0;
	int w = INT_FIELD( point, "x" );
	int h = INT_FIELD( point, "y" );
	int ax = INT_FIELD( arect, "x" );
	int ay = INT_FIELD( arect, "y" );
	int aw = INT_FIELD( arect, "w" );
	int ah = INT_FIELD( arect, "h" );
	int bx = INT_FIELD( brect, "x" );
	int by = INT_FIELD( brect, "y" );
	int bw = INT_FIELD( brect, "w" );
	int bh = INT_FIELD( brect, "h" );

	/*a - bottom right co-ordinates*/
	int ax1 = x + aw - 1;
	int ay1 = y + ah - 1;
	
	/*b - bottom right co-ordinates*/
	int bx1 = w + bw - 1;
	int by1 = h + bh - 1;

	/*check if bounding boxes intersect*/
	if ( ( bx1 < x ) || ( ax1 < w ) || ( by1 < y ) || ( ay1 < h ) )
		return alloc_bool( false );


/*Now lets make the bounding box for which we check for a pixel collision*/

	/*To get the bounding box we do
	    Ax1,Ay1_____________
		|					|
		|					|
		|					|
		|		Bx1,By1_________________
		|			|		|			|
		|			|		|			|
		|___________|_______|			|
					|    Ax2,Ay2		|
					|					|
					|					|
					|________________Bx2,By2

	To find that overlap we find the biggest left hand cordinate
	AND the smallest right hand co-ordinate

	To find it for y we do the biggest top y value
	AND the smallest bottom y value

	Therefore the overlap here is Bx1,By1 --> Ax2,Ay2

	Remember	Ax2 = Ax1 + SA->w
			Bx2 = Bx1 + SB->w

			Ay2 = Ay1 + SA->h
			By2 = By1 + SB->h
	*/

	/*now we loop round every pixel in area of
	intersection
		if 2 pixels alpha values on 2 surfaces at the
		same place != 0 then we have a collision*/
	int inter_x0 = MAX(x,w);
	int inter_x1 = MIN(ax1,bx1);

	int inter_y0 = MAX(y,h);
	int inter_y1 = MIN(ay1,by1);

	bool check = false;

	for(int ly = inter_y0 ; ly <= inter_y1 ; ly++)
	{
		for(int lx = inter_x0 ; lx <= inter_x1 ; lx++)
		{
			/*compute offsets for surface
			before pass to TransparentPixel test*/
			SDL_Surface* as = SURFACE( asurf );
			SDL_Surface* bs = SURFACE( bsurf );
			int atest = nme_collision_transparentpixel( as, lx + ax, ly + ay );
			int btest = nme_collision_transparentpixel( bs, (lx + bx) - w, (ly + by) - h );
			if( !atest && !btest )
				check = true;
		}
	}
	return alloc_bool( check );
}

/*
	SDL bounding box collision test
*/
value nme_collision_boundingbox( value arect, value brect, value point )
{
	val_check( arect, object );
	val_check( brect, object );
	val_check( point, object );

	int x = 0;
	int y = 0;
	int w = INT_FIELD( point, "x" );
	int h = INT_FIELD( point, "y" );
	int ax = INT_FIELD( arect, "x" );
	int ay = INT_FIELD( arect, "y" );
	int aw = INT_FIELD( arect, "w" );
	int ah = INT_FIELD( arect, "h" );
	int bx = INT_FIELD( brect, "x" );
	int by = INT_FIELD( brect, "y" );
	int bw = INT_FIELD( brect, "w" );
	int bh = INT_FIELD( brect, "h" );

	/*a - bottom right co-ordinates*/
	int ax1 = x + aw - 1;
	int ay1 = y + ah - 1;
	
	/*b - bottom right co-ordinates*/
	int bx1 = w + bw - 1;
	int by1 = h + bh - 1;

	/*check if bounding boxes intersect*/
	if ( ( bx1 < x ) || ( ax1 < w ) || ( by1 < y ) || ( ay1 < h ) )
		return alloc_bool( false );

	return alloc_bool( true );				//bounding boxes intersect
}

/*
	tests whether 2 circles intersect

	circle1 : centre (x1,y1) with radius r1
	circle2 : centre (x2,y2) with radius r2
	
	(allow distance between circles of offset)
*/
value nme_collision_boundingcircle( value rp1, value rp2, value poffset )
{
	val_check( rp1, int );
	val_check( rp2, int );
	val_check( poffset, object );

	int r1 = val_int( rp1 );
	int r2 = val_int( rp2 );
	int xdiff = INT_FIELD( poffset, "x" );
	int ydiff = INT_FIELD( poffset, "y" );

	/* distance between the circles centres squared */
	int dcentre_sq = (ydiff*ydiff) + (xdiff*xdiff);
	
	/* calculate sum of radiuses squared */
	int r_sum_sq = r1 + r2;	// square on seperate line, so
	r_sum_sq *= r_sum_sq;	// dont recompute r1 + r2

	return alloc_bool( dcentre_sq - r_sum_sq);// <= (offset*offset) );
}



// text based functions



// TTF_Init() must be called before using this function.
// Remember to call TTF_Quit() when done.
value nme_ttf_shaded( value str, value fnt, value size, value fc, value bc )
{
	val_check( str, string );
	val_check( fnt, string );
	val_check( size, int );
	val_check( fc, int );
	val_check( bc, int );

	TTF_Font* font = TTF_OpenFont( val_string( fnt ), val_int( size ) );

	int rbc = RRGB( bc );
	int gbc = GRGB( bc );
	int bbc = BRGB( bc );
	int rfc = RRGB( fc );
	int gfc = GRGB( fc );
	int bfc = BRGB( fc );

	SDL_Color foregroundColor = { rfc, gfc, bfc };
	SDL_Color backgroundColor = { rbc, gbc, bbc };

	SDL_Surface* textSurface = TTF_RenderText_Shaded( font, val_string( str ), foregroundColor, backgroundColor );

	TTF_CloseFont(font);

	value v = alloc_abstract( k_surf, textSurface );
	val_gc( v, nme_surface_free );
	return v;
}

value nme_ttf_draw( value screen, value text, value point )
{
	val_check_kind( screen, k_surf );
	val_check_kind( text, k_surf );
	val_check( point, object );

	SDL_Surface* scr = SURFACE( screen );
	SDL_Surface* txt = SURFACE( text );
	int x = INT_FIELD( point, "x" );
	int y = INT_FIELD( point, "y" );

	SDL_Rect textLocation = { x, y, 0, 0 };
	SDL_BlitSurface( txt, NULL, scr, &textLocation );

	return alloc_int( 0 );
}



// sound related functions




void nme_sound_free( value snd )
{
	if ( val_is_kind( snd, k_snd ) )
	{
		val_gc( snd, NULL );

		Mix_Chunk *chunk = SOUND( snd );
		Mix_FreeChunk( chunk );
	}
}

value nme_sound_loadwav( value file )
{
	val_check( file, string );

	Mix_Chunk *snd = Mix_LoadWAV( val_string( file ) );
	if ( snd == NULL )
		printf("unable to load sound %s\n", val_string( file ));

	value v = alloc_abstract( k_snd, snd );
	val_gc( v, nme_sound_free );
	return v;
}

value nme_sound_setchannels( value cnt )
{
	val_check( cnt, int );

	return alloc_int( Mix_AllocateChannels( val_int( cnt ) ) );
}

value nme_sound_volume( value snd, value volume )
{
	val_check_kind( snd, k_snd );
	val_check( volume, int );
	
	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_VolumeChunk( chunk, val_int( volume ) ) );
}

value nme_sound_playchannel( value snd, value channel, value loop )
{
	val_check_kind( snd, k_snd );
	val_check( channel, int );
	val_check( loop, int );

	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_PlayChannel( val_int( channel ), chunk, val_int( loop ) ) );
}

value nme_sound_playchanneltimed( value snd, value channel, value loop, value ticks )
{
	val_check_kind( snd, k_snd );
	val_check( channel, int );
	val_check( loop, int );
	val_check( ticks, int );

	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_PlayChannelTimed( val_int( channel ), chunk, val_int( loop ), val_int( ticks ) ) );
}

value nme_sound_fadeinchannel( value snd, value channel, value loop, value ms )
{
	val_check_kind( snd, k_snd );
	val_check( channel, int );
	val_check( loop, int );
	val_check( ms, int );

	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_FadeInChannel( val_int( channel ), chunk, val_int( loop ), val_int( ms ) ) );
}

value nme_sound_fadeinchanneltimed( value snd, value channel, value loop, value ms, value ticks )
{
	val_check_kind( snd, k_snd );
	val_check( channel, int );
	val_check( loop, int );
	val_check( ms, int );
	val_check( ticks, int );

	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_FadeInChannelTimed( val_int( channel ), chunk, val_int( loop ), val_int( ms ), val_int( ticks ) ) );
}

value nme_sound_fadeoutchannel( value channel, value ms )
{
	val_check( channel, int );
	val_check( ms, int );

	Mix_FadeOutChannel( val_int( channel ), val_int( ms ) );
}

value nme_sound_pause( value channel )
{
	val_check( channel, int );

	Mix_Pause( val_int( channel ) );

	alloc_int( 0 );
}

value nme_sound_resume( value channel )
{
	val_check( channel, int );

	Mix_Resume( val_int( channel ) );

	alloc_int( 0 );
}

value nme_sound_stop( value channel )
{
	val_check( channel, int );

	Mix_HaltChannel( val_int( channel ) );

	return alloc_int( 0 );
}

value nme_sound_stoptimed( value channel, value ticks )
{
	val_check( channel, int );
	val_check( ticks, int );

	return alloc_int( Mix_ExpireChannel( val_int( channel ), val_int( ticks ) ) );
}

value nme_sound_isplaying( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_Playing( val_int( channel ) ) );
}

value nme_sound_ispaused( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_Paused( val_int( channel ) ) );
}

value nme_sound_isfading( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_FadingChannel( val_int( channel ) ) );
}

value nme_sound_reservechannels( value cnt )
{
	val_check( cnt, int );

	return alloc_int( Mix_ReserveChannels( val_int( cnt ) ) );
}

value nme_sound_groupchannels( value from, value to, value group )
{
	val_check( from, int );
	val_check( to, int );
	val_check( group, int );

	return alloc_int( Mix_GroupChannels( val_int( from ), val_int( to ), val_int( group ) ) );
}

value nme_sound_groupchannel( value channel, value group )
{
	val_check( channel, int );
	val_check( group, int );

	return alloc_int( Mix_GroupChannel( val_int( channel ), val_int( group ) ) );
}

value nme_sound_groupcount( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_GroupCount( val_int( channel ) ) );
}

value nme_sound_groupavailable( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_GroupAvailable( val_int( channel ) ) );
}

value nme_sound_fadeoutgroup( value channel, value ms )
{
	val_check( channel, int );
	val_check( ms, int );

	return alloc_int( Mix_FadeOutGroup( val_int( channel ), val_int( ms ) ) );
}

value nme_sound_stopgroup( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_HaltGroup( val_int( channel ) ) );
}



// music relative functions



void nme_music_free( value music )
{
	if ( val_is_kind( music, k_mus ) )
	{
		val_gc( music, NULL );

		Mix_Music *msc = MUSIC( music );
		Mix_FreeMusic( msc );
	}
}

value nme_music_init( value file )
{
	val_check( file, string );

	Mix_Music *music;
	music = Mix_LoadMUS( val_string( file ) );
	if(!music)
		printf("%s : %s\n", val_string( file ), Mix_GetError());
	
	value v = alloc_abstract( k_mus, music );
	val_gc( v, nme_music_free );
	return v;
}

value nme_music_play( value music, value loops )
{
	val_check_kind( music, k_mus );
	val_check( loops, int );

	Mix_Music *msc = MUSIC( music );

	return alloc_int( Mix_PlayMusic( msc, val_int( loops ) ) );
}

value nme_music_fadeinplay( value music, value loops, value ms )
{
	val_check_kind( music, k_mus );
	val_check( loops, int );
	val_check( ms, int );

	Mix_Music *msc = MUSIC( music );

	return alloc_int( Mix_FadeInMusic( msc, val_int( loops ), val_int( ms ) ) );
}

value nme_music_fadeinplaypos( value music, value loops, value ms, value pos )
{
	val_check_kind( music, k_mus );
	val_check( loops, int );
	val_check( ms, int );
	val_check( pos, int );

	Mix_Music *msc = MUSIC( music );

	return alloc_int( Mix_FadeInMusicPos( msc, val_int( loops ), val_int( ms ), val_int( pos ) ) );
}

value nme_music_fadeout( value ms )
{
	val_check( ms, int );

	return alloc_int( Mix_FadeOutMusic( val_int( ms ) ) );
}

value nme_music_stop()
{
	return alloc_int( Mix_HaltMusic() );
}

value nme_music_pause()
{
	Mix_PauseMusic();

	return alloc_int( 0 );
}

value nme_music_resume()
{
	Mix_ResumeMusic();

	return alloc_int( 0 );
}

value nme_music_restart()
{
	Mix_RewindMusic();

	return alloc_int( 0 );
}

value nme_music_volume( value volume )
{
	val_check( volume, int );

	return alloc_int( Mix_VolumeMusic( val_int( volume ) ) );
}

value nme_music_isplaying()
{
	return alloc_int( Mix_PlayingMusic() );
}

value nme_music_ispaused()
{
	return alloc_int( Mix_PausedMusic() );
}

value nme_music_isfading()
{
	return alloc_int( Mix_FadingMusic() );
}



DEFINE_PRIM(nme_event, 0);
DEFINE_PRIM(nme_delay, 1);
DEFINE_PRIM(nme_flipbuffer, 1);

DEFINE_PRIM(nme_screen_init, 5);
DEFINE_PRIM(nme_screen_close, 0);

DEFINE_PRIM(nme_sprite_init, 1);
DEFINE_PRIM(nme_sprite_draw, 4);
DEFINE_PRIM(nme_sprite_alpha, 2);

DEFINE_PRIM(nme_surface_clear, 2);
DEFINE_PRIM(nme_surface_free, 1);
DEFINE_PRIM(nme_surface_colourkey, 4);

DEFINE_PRIM(nme_collision_pixel, 5);
DEFINE_PRIM(nme_collision_boundingbox, 3);
DEFINE_PRIM(nme_collision_boundingcircle, 3);

DEFINE_PRIM(nme_ttf_shaded, 5);
DEFINE_PRIM(nme_ttf_draw, 3);

DEFINE_PRIM(nme_sound_loadwav, 1);
DEFINE_PRIM(nme_sound_free, 1);
DEFINE_PRIM(nme_sound_setchannels, 1);
DEFINE_PRIM(nme_sound_volume, 2);
DEFINE_PRIM(nme_sound_playchannel, 3);
DEFINE_PRIM(nme_sound_playchanneltimed, 4);
DEFINE_PRIM(nme_sound_fadeinchannel, 4);
DEFINE_PRIM(nme_sound_fadeinchanneltimed, 5);
DEFINE_PRIM(nme_sound_fadeoutchannel, 2);
DEFINE_PRIM(nme_sound_pause, 1);
DEFINE_PRIM(nme_sound_resume, 1);
DEFINE_PRIM(nme_sound_stop, 1);
DEFINE_PRIM(nme_sound_stoptimed, 2);
DEFINE_PRIM(nme_sound_isplaying, 1);
DEFINE_PRIM(nme_sound_ispaused, 1);
DEFINE_PRIM(nme_sound_isfading, 1);
DEFINE_PRIM(nme_sound_reservechannels, 1);
DEFINE_PRIM(nme_sound_groupchannel, 2);
DEFINE_PRIM(nme_sound_groupchannels, 3);
DEFINE_PRIM(nme_sound_groupcount, 1);
DEFINE_PRIM(nme_sound_groupavailable, 1);
DEFINE_PRIM(nme_sound_fadeoutgroup, 2);
DEFINE_PRIM(nme_sound_stopgroup, 1);

DEFINE_PRIM(nme_music_init, 1);
DEFINE_PRIM(nme_music_free, 1);
DEFINE_PRIM(nme_music_play, 2);
DEFINE_PRIM(nme_music_fadeinplay, 3);
DEFINE_PRIM(nme_music_fadeinplaypos, 4);
DEFINE_PRIM(nme_music_fadeout, 1);
DEFINE_PRIM(nme_music_stop, 0);
DEFINE_PRIM(nme_music_pause, 0);
DEFINE_PRIM(nme_music_resume, 0);
DEFINE_PRIM(nme_music_restart, 0);
DEFINE_PRIM(nme_music_volume, 1);
DEFINE_PRIM(nme_music_isplaying, 0);
DEFINE_PRIM(nme_music_ispaused, 0);
DEFINE_PRIM(nme_music_isfading, 0);