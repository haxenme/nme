/*
    SPriG v0.9
    by Jonathan Dearborn 12/10/07
*/



/*
*	SDL Graphics Extension
*	Triangles of every sort
*
*	Started 000428
*
*	License: LGPL v2+ (see the file LICENSE)
*	(c)2000-2003 Anders Lindström & Johan E. Thelin
*/

/*********************************************************************
 *  This library is free software; you can redistribute it and/or    *
 *  modify it under the terms of the GNU Library General Public      *
 *  License as published by the Free Software Foundation; either     *
 *  version 2 of the License, or (at your option) any later version. *
 *********************************************************************/

/*
*  Written with some help from Johan E. Thelin.
*/

#include "SPriG.h"

#define SWAP(x,y,temp) temp=x;x=y;y=temp

/* Global used for SPG_Lock (defined in SPG_surface) */
extern bool _SPG_lock;
extern Uint8 _SPG_alpha_hack;

void _SetPixel(SDL_Surface *surface, Sint16 x, Sint16 y, Uint32 color);
/* We need some internal functions */
extern void _Line(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color);
extern void _LineAlpha(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 Color, Uint8 alpha);
extern void _HLine(SDL_Surface *Surface, Sint16 x1, Sint16 x2, Sint16 y, Uint32 Color);
extern void _HLineAlpha(SDL_Surface *Surface, Sint16 x1, Sint16 x2, Sint16 y, Uint32 Color, Uint8 alpha);
extern void callback_alpha_hack(SDL_Surface *surf, Sint16 x, Sint16 y, Uint32 color);
extern void _AALineAlpha(SDL_Surface *dst, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color, Uint8 alpha);
extern void _AAmcLineAlpha(SDL_Surface *dst, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint8 alpha1, Uint32 color2, Uint8 alpha2);

/* Macro to inline RGB mapping */
#define MapRGB(format, r, g, b)\
	(r >> format->Rloss) << format->Rshift\
		| (g >> format->Gloss) << format->Gshift\
		| (b >> format->Bloss) << format->Bshift


//==================================================================================
// Draws a horisontal line, fading the colors
//==================================================================================
void _FadedLine(SDL_Surface *dest,Sint16 x1,Sint16 x2,Sint16 y,Uint8 r1,Uint8 g1,Uint8 b1,Uint8 r2,Uint8 g2,Uint8 b2)
{
	Sint16 x;
	Uint8 t;
	
	/* Fix coords */
	if ( x1 > x2 ) {
		SWAP(x1,x2,x);
		SWAP(r1,r2,t);
		SWAP(g1,g2,t);
		SWAP(b1,b2,t);
	}	
	
	/* We use fixedpoint math */
	Sint32 R = r1<<16;
	Sint32 G = g1<<16;
	Sint32 B = b1<<16;
	
	/* Color step value */
	Sint32 rstep = Sint32((r2-r1)<<16) / Sint32(x2-x1+1);
	Sint32 gstep = Sint32((g2-g1)<<16) / Sint32(x2-x1+1);
	Sint32 bstep = Sint32((b2-b1)<<16) / Sint32(x2-x1+1);
	
	
	/* Clipping */
	if(x2<SPG_clip_xmin(dest) || x1>SPG_clip_xmax(dest) || y<SPG_clip_ymin(dest) || y>SPG_clip_ymax(dest))
		return;
	if (x1 < SPG_clip_xmin(dest)){
		/* Update start colors */
		R += (SPG_clip_xmin(dest)-x1)*rstep;
		G += (SPG_clip_xmin(dest)-x1)*gstep;
		B += (SPG_clip_xmin(dest)-x1)*bstep;
  		x1 = SPG_clip_xmin(dest);
	}
	if (x2 > SPG_clip_xmax(dest))
  		x2 = SPG_clip_xmax(dest);

	
	switch (dest->format->BytesPerPixel) {
		case 1: { /* Assuming 8-bpp */
			Uint8 *pixel;
			Uint8 *row = (Uint8 *)dest->pixels + y*dest->pitch;
			
			for (x = x1; x <= x2; x++){
				pixel = row + x;
				
				*pixel = SDL_MapRGB( dest->format, R>>16, G>>16, B>>16 );
		
				R += rstep;
				G += gstep;
				B += bstep;
			}
		}
		break;

		case 2: { /* Probably 15-bpp or 16-bpp */
			Uint16 *pixel;
			Uint16 *row = (Uint16 *)dest->pixels + y*dest->pitch/2;
			
			for (x = x1; x <= x2; x++){
				pixel = row + x;
				
				*pixel = MapRGB( dest->format, R>>16, G>>16, B>>16 );
		
				R += rstep;
				G += gstep;
				B += bstep;
			}
		}
		break;

		case 3: { /* Slow 24-bpp mode, usually not used */
			Uint8 *pixel;
			Uint8 *row = (Uint8 *)dest->pixels + y*dest->pitch;
			
			Uint8 rshift8=dest->format->Rshift/8;
			Uint8 gshift8=dest->format->Gshift/8;
			Uint8 bshift8=dest->format->Bshift/8;
			
			for (x = x1; x <= x2; x++){
				pixel = row + x*3;
		
				*(pixel+rshift8) = R>>16;
  				*(pixel+gshift8) = G>>16;
  				*(pixel+bshift8) = B>>16;
		
				R += rstep;
				G += gstep;
				B += bstep;
			}
		}
		break;

		case 4: { /* Probably 32-bpp */
			Uint32 *pixel;
			Uint32 *row = (Uint32 *)dest->pixels + y*dest->pitch/4;
			
			for (x = x1; x <= x2; x++){
				pixel = row + x;
				
				*pixel = MapRGB( dest->format, R>>16, G>>16, B>>16 );
		
				R += rstep;
				G += gstep;
				B += bstep;
			}
		}
		break;
	}
}

void SPG_FadedLine(SDL_Surface *dest,Sint16 x1,Sint16 x2,Sint16 y,Uint8 r1,Uint8 g1,Uint8 b1,Uint8 r2,Uint8 g2,Uint8 b2)
{
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		if ( SDL_LockSurface(dest) < 0 )
			return;

	_FadedLine(dest,x1,x2,y,r1,g1,b1,r2,g2,b2);
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
    
}


//==================================================================================
// Draws a horisontal, textured line
//==================================================================================
void _TexturedLine(SDL_Surface *dest,Sint16 x1,Sint16 x2,Sint16 y,SDL_Surface *source,Sint16 sx1,Sint16 sy1,Sint16 sx2,Sint16 sy2)
{
	Sint16 x;
	
	/* Fix coords */
	if ( x1 > x2 ) {
		SWAP(x1,x2,x);
		SWAP(sx1,sx2,x);
		SWAP(sy1,sy2,x);
	}	
	
	/* Fixed point texture starting coords */
	Sint32 srcx = sx1<<16;
	Sint32 srcy = sy1<<16;
	
	/* Texture coords stepping value */
	Sint32 xstep = Sint32((sx2-sx1)<<16) / Sint32(x2-x1+1);
	Sint32 ystep = Sint32((sy2-sy1)<<16) / Sint32(x2-x1+1);
	
	
	/* Clipping */
	if(x2<SPG_clip_xmin(dest) || x1>SPG_clip_xmax(dest) || y<SPG_clip_ymin(dest) || y>SPG_clip_ymax(dest))
		return;
	if (x1 < SPG_clip_xmin(dest)){
		/* Fix texture starting coord */
		srcx += (SPG_clip_xmin(dest)-x1)*xstep;
		srcy += (SPG_clip_xmin(dest)-x1)*ystep;
  		x1 = SPG_clip_xmin(dest);
	}
	if (x2 > SPG_clip_xmax(dest))
  		x2 = SPG_clip_xmax(dest);

	
	if(dest->format->BytesPerPixel == source->format->BytesPerPixel){
		/* Fast mode. Just copy the pixel */
	
		switch (dest->format->BytesPerPixel) {
			case 1: { /* Assuming 8-bpp */
				Uint8 *pixel;
				Uint8 *row = (Uint8 *)dest->pixels + y*dest->pitch;
			
				for (x = x1; x <= x2; x++){
					pixel = row + x;
				
					*pixel = *((Uint8 *)source->pixels + (srcy>>16)*source->pitch + (srcx>>16));
		
					srcx += xstep;
					srcy += ystep;
				}
			}
			break;

			case 2: { /* Probably 15-bpp or 16-bpp */
				Uint16 *pixel;
				Uint16 *row = (Uint16 *)dest->pixels + y*dest->pitch/2;
			
				Uint16 pitch = source->pitch/2;
			
				for (x = x1; x <= x2; x++){
					pixel = row + x;
				
					*pixel = *((Uint16 *)source->pixels + (srcy>>16)*pitch + (srcx>>16));
		
					srcx += xstep;
					srcy += ystep;
				}
			}
			break;

			case 3: { /* Slow 24-bpp mode, usually not used */
				Uint8 *pixel, *srcpixel;
				Uint8 *row = (Uint8 *)dest->pixels + y*dest->pitch;
			
				Uint8 rshift8=dest->format->Rshift/8;
				Uint8 gshift8=dest->format->Gshift/8;
				Uint8 bshift8=dest->format->Bshift/8;
			
				for (x = x1; x <= x2; x++){
					pixel = row + x*3;
					srcpixel = (Uint8 *)source->pixels + (srcy>>16)*source->pitch + (srcx>>16)*3;
		
					*(pixel+rshift8) = *(srcpixel+rshift8);
  					*(pixel+gshift8) = *(srcpixel+gshift8);
  					*(pixel+bshift8) = *(srcpixel+bshift8);
		
					srcx += xstep;
					srcy += ystep;
				}	
			}
			break;

			case 4: { /* Probably 32-bpp */
				Uint32 *pixel;
				Uint32 *row = (Uint32 *)dest->pixels + y*dest->pitch/4;
			
				Uint16 pitch = source->pitch/4;
			
				for (x = x1; x <= x2; x++){
					pixel = row + x;
				
					*pixel = *((Uint32 *)source->pixels + (srcy>>16)*pitch + (srcx>>16));
		
					srcx += xstep;
					srcy += ystep;
				}
			}
			break;
		}
	}else{
		/* Slow mode. We must translate every pixel color! */
	
		Uint8 r=0,g=0,b=0;
	
		switch (dest->format->BytesPerPixel) {
			case 1: { /* Assuming 8-bpp */
				Uint8 *pixel;
				Uint8 *row = (Uint8 *)dest->pixels + y*dest->pitch;
			
				for (x = x1; x <= x2; x++){
					pixel = row + x;
				
					SDL_GetRGB(SPG_GetPixel(source, srcx>>16, srcy>>16), source->format, &r, &g, &b);
					*pixel = SDL_MapRGB( dest->format, r, g, b );
		
					srcx += xstep;
					srcy += ystep;
				}
			}
			break;

			case 2: { /* Probably 15-bpp or 16-bpp */
				Uint16 *pixel;
				Uint16 *row = (Uint16 *)dest->pixels + y*dest->pitch/2;
			
				for (x = x1; x <= x2; x++){
					pixel = row + x;
					
					SDL_GetRGB(SPG_GetPixel(source, srcx>>16, srcy>>16), source->format, &r, &g, &b);
					*pixel = MapRGB( dest->format, r, g, b );
		
					srcx += xstep;
					srcy += ystep;
				}
			}
			break;

			case 3: { /* Slow 24-bpp mode, usually not used */
				Uint8 *pixel, *srcpixel;
				Uint8 *row = (Uint8 *)dest->pixels + y*dest->pitch;
			
				Uint8 rshift8=dest->format->Rshift/8;
				Uint8 gshift8=dest->format->Gshift/8;
				Uint8 bshift8=dest->format->Bshift/8;
			
				for (x = x1; x <= x2; x++){
					pixel = row + x*3;
					srcpixel = (Uint8 *)source->pixels + (srcy>>16)*source->pitch + (srcx>>16)*3;
		
					SDL_GetRGB(SPG_GetPixel(source, srcx>>16, srcy>>16), source->format, &r, &g, &b);
					
					*(pixel+rshift8) = r;
  					*(pixel+gshift8) = g;
  					*(pixel+bshift8) = b;
		
					srcx += xstep;
					srcy += ystep;
				}	
			}
			break;

			case 4: { /* Probably 32-bpp */
				Uint32 *pixel;
				Uint32 *row = (Uint32 *)dest->pixels + y*dest->pitch/4;
			
				for (x = x1; x <= x2; x++){
					pixel = row + x;
				
					SDL_GetRGB(SPG_GetPixel(source, srcx>>16, srcy>>16), source->format, &r, &g, &b);
					*pixel = MapRGB( dest->format, r, g, b );
		
					srcx += xstep;
					srcy += ystep;
				}
			}
			break;
		}
	}
}

void SPG_LineTex(SDL_Surface *dest,Sint16 x1,Sint16 x2,Sint16 y,SDL_Surface *source,Sint16 sx1,Sint16 sy1,Sint16 sx2,Sint16 sy2)
{
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		if ( SDL_LockSurface(dest) < 0 )
			return;
	if ( SDL_MUSTLOCK(source) && _SPG_lock )
		if ( SDL_LockSurface(source) < 0 )
			return;

	_TexturedLine(dest,x1,x2,y,source,sx1,sy1,sx2,sy2);
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
	if ( SDL_MUSTLOCK(source) && _SPG_lock )
		SDL_UnlockSurface(source);
    
}

//==================================================================================
// Draws a trigon
//==================================================================================
void SPG_Trigon(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color)
{
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		if ( SDL_LockSurface(dest) < 0 )
			return;

	_Line(dest,x1,y1,x2,y2,color);
	_Line(dest,x1,y1,x3,y3,color);
	_Line(dest,x3,y3,x2,y2,color);
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
		
}

void SPG_Trigon(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint8 R, Uint8 G, Uint8 B)
{
	SPG_Trigon(dest,x1,y1,x2,y2,x3,y3, SDL_MapRGB(dest->format, R,G,B));
}


//==================================================================================
// Draws a trigon (alpha)
//==================================================================================
void SPG_TrigonBlend(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color, Uint8 alpha)
{
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		if ( SDL_LockSurface(dest) < 0 )
			return;
	
	_LineAlpha(dest,x1,y1,x2,y2,color, alpha);
	_LineAlpha(dest,x1,y1,x3,y3,color, alpha);
	_LineAlpha(dest,x3,y3,x2,y2,color, alpha);
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
	
}



//==================================================================================
// Draws an AA trigon (alpha)
//==================================================================================
void SPG_TrigonAABlend(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color, Uint8 alpha)
{
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		if ( SDL_LockSurface(dest) < 0 )
			return;
	
	_AALineAlpha(dest,x1,y1,x2,y2,color, alpha);
	_AALineAlpha(dest,x1,y1,x3,y3,color, alpha);
	_AALineAlpha(dest,x3,y3,x2,y2,color, alpha);
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);	

}



void SPG_TrigonAA(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color)
{
	SPG_TrigonAABlend(dest,x1,y1,x2,y2,x3,y3, color, SDL_ALPHA_OPAQUE);
}



//==================================================================================
// Draws a filled trigon
//==================================================================================
void SPG_TrigonFilled(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color)
{
	Sint16 y;

	if( y1==y3 )
		return;

	/* Sort coords */
	if ( y1 > y2 ) {
		SWAP(y1,y2,y);
		SWAP(x1,x2,y);
	}
	if ( y2 > y3 ) {
		SWAP(y2,y3,y);
		SWAP(x2,x3,y);
	}
	if ( y1 > y2 ) {
		SWAP(y1,y2,y);
		SWAP(x1,x2,y);
	}
	
	/*
	 * How do we calculate the starting and ending x coordinate of the horizontal line
	 * on each y coordinate?  We can do this by using a standard line algorithm but
	 * instead of plotting pixels, use the x coordinates as start and stop
	 * coordinates for the horizontal line.
	 * So we will simply trace the outlining of the triangle; this will require 3 lines.
	 * Line 1 is the line between (x1,y1) and (x2,y2)
	 * Line 2 is the line between (x1,y1) and (x3,y3)
	 * Line 3 is the line between (x2,y2) and (x3,y3)
	 *
	 * We can divide the triangle into 2 halfs. The upper half will be outlined by line
	 * 1 and 2. The lower half will be outlined by line line 2 and 3.
	*/
	
	
	/* Starting coords for the three lines */
	Sint32 xa = Sint32(x1<<16);
	Sint32 xb = xa;
	Sint32 xc = Sint32(x2<<16);

	/* Lines step values */
	Sint32 m1 = 0;
	Sint32 m2 = Sint32((x3 - x1)<<16)/Sint32(y3 - y1);
	Sint32 m3 = 0;
	
	/* Upper half of the triangle */
	if( y1==y2 )
		_HLine(dest, x1, x2, y1, color);
	else{
		m1 = Sint32((x2 - x1)<<16)/Sint32(y2 - y1);
		
		for ( y = y1; y <= y2; y++) {
			_HLine(dest, xa>>16, xb>>16, y, color);
				
			xa += m1;
			xb += m2;
		}
	}
	
	/* Lower half of the triangle */
	if( y2==y3 )
		_HLine(dest, x2, x3, y2, color);
	else{
		m3 = Sint32((x3 - x2)<<16)/Sint32(y3 - y2);
		
		for ( y = y2+1; y <= y3; y++) {
			_HLine(dest, xb>>16, xc>>16, y, color);

			xb += m2;
			xc += m3;
		}
	}
	
	
}



//==================================================================================
// Draws a filled trigon (alpha)
//==================================================================================
void SPG_TrigonFilledBlend(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color, Uint8 alpha)
{
	Sint16 y;

	if( y1==y3 )
		return;

	/* Sort coords */
	if ( y1 > y2 ) {
		SWAP(y1,y2,y);
		SWAP(x1,x2,y);
	}
	if ( y2 > y3 ) {
		SWAP(y2,y3,y);
		SWAP(x2,x3,y);
	}
	if ( y1 > y2 ) {
		SWAP(y1,y2,y);
		SWAP(x1,x2,y);
	}

	Sint32 xa = Sint32(x1<<16);
	Sint32 xb = xa;
	Sint32 xc = Sint32(x2<<16);

	Sint32 m1 = 0;
	Sint32 m2 = Sint32((x3 - x1)<<16)/Sint32(y3 - y1);
	Sint32 m3 = 0;
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		if ( SDL_LockSurface(dest) < 0 )
			return;
	
	/* Upper half of the triangle */
	if( y1==y2 )
		_HLineAlpha(dest, x1, x2, y1, color, alpha);
	else{
		m1 = Sint32((x2 - x1)<<16)/Sint32(y2 - y1);
		
		for ( y = y1; y <= y2; y++) {
			_HLineAlpha(dest, xa>>16, xb>>16, y, color, alpha);
				
			xa += m1;
			xb += m2;
		}
	}
	
	/* Lower half of the triangle */
	if( y2==y3 )
		_HLineAlpha(dest, x2, x3, y2, color, alpha);
	else{
		m3 = Sint32((x3 - x2)<<16)/Sint32(y3 - y2);
		
		for ( y = y2+1; y <= y3; y++) {
			_HLineAlpha(dest, xb>>16, xc>>16, y, color, alpha);

			xb += m2;
			xc += m3;
		}
	}
	
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
	
	
}



//==================================================================================
// Draws a gourand shaded trigon
//==================================================================================
void SPG_TrigonFade(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 c1,Uint32 c2,Uint32 c3)
{
	Sint16 y;

	if( y1==y3 )
		return;
		
	Uint8 c=0;
	SDL_Color col1;
	SDL_Color col2;
	SDL_Color col3;
	
	col1 = SPG_GetColor(dest,c1);
	col2 = SPG_GetColor(dest,c2);
	col3 = SPG_GetColor(dest,c3);

	/* Sort coords */
	if ( y1 > y2 ) {
		SWAP(y1,y2,y);
		SWAP(x1,x2,y);
		SWAP(col1.r,col2.r,c);
		SWAP(col1.g,col2.g,c);
		SWAP(col1.b,col2.b,c);
	}
	if ( y2 > y3 ) {
		SWAP(y2,y3,y);
		SWAP(x2,x3,y);
		SWAP(col2.r,col3.r,c);
		SWAP(col2.g,col3.g,c);
		SWAP(col2.b,col3.b,c);
	}
	if ( y1 > y2 ) {
		SWAP(y1,y2,y);
		SWAP(x1,x2,y);
		SWAP(col1.r,col2.r,c);
		SWAP(col1.g,col2.g,c);
		SWAP(col1.b,col2.b,c);
	}

	/*
	 * We trace three lines exactly like in SPG_FilledTrigon(), but here we
	 * must also keep track of the colors. We simply calculate how the color
	 * will change along the three lines.
	*/

	/* Starting coords for the three lines */
	Sint32 xa = Sint32(x1<<16);
	Sint32 xb = xa;
	Sint32 xc = Sint32(x2<<16);
	
	/* Starting colors (rgb) for the three lines */
	Sint32 r1 = Sint32(col1.r<<16);
	Sint32 r2 = r1;
	Sint32 r3 = Sint32(col2.r<<16);
	
	Sint32 g1 = Sint32(col1.g<<16);
	Sint32 g2 = g1;
	Sint32 g3 = Sint32(col2.g<<16);
	
	Sint32 b1 = Sint32(col1.b<<16);
	Sint32 b2 = b1;
	Sint32 b3 = Sint32(col2.b<<16);
	
	/* Lines step values */
	Sint32 m1 = 0;
	Sint32 m2 = Sint32((x3 - x1)<<16)/Sint32(y3 - y1);
	Sint32 m3 = 0;
	
	/* Colors step values */
	Sint32 rstep1 = 0;
	Sint32 rstep2 = Sint32((col3.r - col1.r) << 16) / Sint32(y3 - y1);
	Sint32 rstep3 = 0;
	
	Sint32 gstep1 = 0;
	Sint32 gstep2 = Sint32((col3.g - col1.g) << 16) / Sint32(y3 - y1);
	Sint32 gstep3 = 0;
	
	Sint32 bstep1 = 0;
	Sint32 bstep2 = Sint32((col3.b - col1.b) << 16) / Sint32(y3 - y1);
	Sint32 bstep3 = 0;
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		if ( SDL_LockSurface(dest) < 0 )
			return;
	
	/* Upper half of the triangle */
	if( y1==y2 )
		_FadedLine(dest, x1, x2, y1, col1.r, col1.g, col1.b, col2.r, col2.g, col2.b);
	else{
		m1 = Sint32((x2 - x1)<<16)/Sint32(y2 - y1);
		
		rstep1 = Sint32((col2.r - col1.r) << 16) / Sint32(y2 - y1);
		gstep1 = Sint32((col2.g - col1.g) << 16) / Sint32(y2 - y1);
		bstep1 = Sint32((col2.b - col1.b) << 16) / Sint32(y2 - y1);
		
		for ( y = y1; y <= y2; y++) {
			_FadedLine(dest, xa>>16, xb>>16, y, r1>>16, g1>>16, b1>>16, r2>>16, g2>>16, b2>>16);
				
			xa += m1;
			xb += m2;
			
			r1 += rstep1;
			g1 += gstep1;
			b1 += bstep1;
			
			r2 += rstep2;
			g2 += gstep2;
			b2 += bstep2;
		}
	}
	
	/* Lower half of the triangle */
	if( y2==y3 )
		_FadedLine(dest, x2, x3, y2, col2.r, col2.g, col2.b, col3.r, col3.g, col3.b);
	else{
		m3 = Sint32((x3 - x2)<<16)/Sint32(y3 - y2);
		
		rstep3 = Sint32((col3.r - col2.r) << 16) / Sint32(y3 - y2);
		gstep3 = Sint32((col3.g - col2.g) << 16) / Sint32(y3 - y2);
		bstep3 = Sint32((col3.b - col2.b) << 16) / Sint32(y3 - y2);
		
		for ( y = y2+1; y <= y3; y++) {
			_FadedLine(dest, xb>>16, xc>>16, y, r2>>16, g2>>16, b2>>16, r3>>16, g3>>16, b3>>16);

			xb += m2;
			xc += m3;
			
			r2 += rstep2;
			g2 += gstep2;
			b2 += bstep2;
			
			r3 += rstep3;
			g3 += gstep3;
			b3 += bstep3;
		}
	}
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
	
}


//==================================================================================
// Draws a texured trigon (fast)
//==================================================================================
void SPG_TrigonTex(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,SDL_Surface *source,Sint16 sx1,Sint16 sy1,Sint16 sx2,Sint16 sy2,Sint16 sx3,Sint16 sy3)
{
	Sint16 y;

	if( y1==y3 )
		return;

	/* Sort coords */
	if ( y1 > y2 ) {
		SWAP(y1,y2,y);
		SWAP(x1,x2,y);
		SWAP(sx1,sx2,y);
		SWAP(sy1,sy2,y);
	}
	if ( y2 > y3 ) {
		SWAP(y2,y3,y);
		SWAP(x2,x3,y);
		SWAP(sx2,sx3,y);
		SWAP(sy2,sy3,y);
	}
	if ( y1 > y2 ) {
		SWAP(y1,y2,y);
		SWAP(x1,x2,y);
		SWAP(sx1,sx2,y);
		SWAP(sy1,sy2,y);
	}

	/*
	 * Again we do the same thing as in SPG_FilledTrigon(). But here we must keep track of how the 
	 * texture coords change along the lines.
	*/

	/* Starting coords for the three lines */
	Sint32 xa = Sint32(x1<<16);
	Sint32 xb = xa;
	Sint32 xc = Sint32(x2<<16);

	/* Lines step values */
	Sint32 m1 = 0;
	Sint32 m2 = Sint32((x3 - x1)<<16)/Sint32(y3 - y1);
	Sint32 m3 = 0;

	/* Starting texture coords for the three lines */	
	Sint32 srcx1 = Sint32(sx1<<16);
	Sint32 srcx2 = srcx1;
	Sint32 srcx3 = Sint32(sx2<<16);
	
	Sint32 srcy1 = Sint32(sy1<<16);
	Sint32 srcy2 = srcy1;
	Sint32 srcy3 = Sint32(sy2<<16);
	
	/* Texture coords stepping value */
	Sint32 xstep1 = 0;
	Sint32 xstep2 = Sint32((sx3 - sx1) << 16) / Sint32(y3 - y1);
	Sint32 xstep3 = 0;
	
	Sint32 ystep1 = 0;
	Sint32 ystep2 = Sint32((sy3 - sy1) << 16) / Sint32(y3 - y1);
	Sint32 ystep3 = 0;
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		if ( SDL_LockSurface(dest) < 0 )
			return;
	if ( SDL_MUSTLOCK(source) && _SPG_lock )
		if ( SDL_LockSurface(source) < 0 )
			return;
	
	/* Upper half of the triangle */
	if( y1==y2 )
		_TexturedLine(dest,x1,x2,y1,source,sx1,sy1,sx2,sy2);
	else{
		m1 = Sint32((x2 - x1)<<16)/Sint32(y2 - y1);
		
		xstep1 = Sint32((sx2 - sx1) << 16) / Sint32(y2 - y1);
		ystep1 = Sint32((sy2 - sy1) << 16) / Sint32(y2 - y1);
		
		for ( y = y1; y <= y2; y++) {
			_TexturedLine(dest, xa>>16, xb>>16, y, source, srcx1>>16, srcy1>>16, srcx2>>16, srcy2>>16);
				
			xa += m1;
			xb += m2;
			
			srcx1 += xstep1;
			srcx2 += xstep2;
			srcy1 += ystep1;
			srcy2 += ystep2;
		}
	}
	
	/* Lower half of the triangle */
	if( y2==y3 )
		_TexturedLine(dest,x2,x3,y2,source,sx2,sy2,sx3,sy3);
	else{
		m3 = Sint32((x3 - x2)<<16)/Sint32(y3 - y2);
		
		xstep3 = Sint32((sx3 - sx2) << 16) / Sint32(y3 - y2);
		ystep3 = Sint32((sy3 - sy2) << 16) / Sint32(y3 - y2);
		
		for ( y = y2+1; y <= y3; y++) {
			_TexturedLine(dest, xb>>16, xc>>16, y, source, srcx2>>16, srcy2>>16, srcx3>>16, srcy3>>16);

			xb += m2;
			xc += m3;
			
			srcx2 += xstep2;
			srcx3 += xstep3;
			srcy2 += ystep2;
			srcy3 += ystep3;
		}
	}
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
	if ( SDL_MUSTLOCK(source) && _SPG_lock )
		SDL_UnlockSurface(source);
	
}


//==================================================================================
// Draws a texured *RECTANGLE*
//==================================================================================
void SPG_QuadTex(SDL_Surface *dest,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Sint16 x4,Sint16 y4,SDL_Surface *source,Sint16 sx1,Sint16 sy1,Sint16 sx2,Sint16 sy2,Sint16 sx3,Sint16 sy3,Sint16 sx4,Sint16 sy4)
{
	Sint16 y;
	
	if( y1==y3 || y1 == y4 || y4 == y2 )
		return;
	
	/* Sort the coords */
	if ( y1 > y2 ) {
		SWAP(x1,x2,y);
		SWAP(y1,y2,y);
		SWAP(sx1,sx2,y);
		SWAP(sy1,sy2,y);
	}
	if ( y2 > y3 ) {
		SWAP(x3,x2,y);
		SWAP(y3,y2,y);
		SWAP(sx3,sx2,y);
		SWAP(sy3,sy2,y);
	}
	if ( y1 > y2 ) {
		SWAP(x1,x2,y);
		SWAP(y1,y2,y);
		SWAP(sx1,sx2,y);
		SWAP(sy1,sy2,y);
	}
	if ( y3 > y4 ) {
		SWAP(x3,x4,y);
		SWAP(y3,y4,y);
		SWAP(sx3,sx4,y);
		SWAP(sy3,sy4,y);
	}
	if ( y2 > y3 ) {
		SWAP(x3,x2,y);
		SWAP(y3,y2,y);
		SWAP(sx3,sx2,y);
		SWAP(sy3,sy2,y);
	}
	if ( y1 > y2 ) {
		SWAP(x1,x2,y);
		SWAP(y1,y2,y);
		SWAP(sx1,sx2,y);
		SWAP(sy1,sy2,y);
	}

	/*
	 * We do this exactly like SPG_TexturedTrigon(), but here we must trace four lines.
	*/

	Sint32 xa = Sint32(x1<<16);
	Sint32 xb = xa;
	Sint32 xc = Sint32(x2<<16);
	Sint32 xd = Sint32(x3<<16);

	Sint32 m1 = 0;
	Sint32 m2 = Sint32((x3 - x1)<<16)/Sint32(y3 - y1);
	Sint32 m3 = Sint32((x4 - x2)<<16)/Sint32(y4 - y2);
	Sint32 m4 = 0;
	
	Sint32 srcx1 = Sint32(sx1<<16);
	Sint32 srcx2 = srcx1;
	Sint32 srcx3 = Sint32(sx2<<16);
	Sint32 srcx4 = Sint32(sx3<<16);
	
	Sint32 srcy1 = Sint32(sy1<<16);
	Sint32 srcy2 = srcy1;
	Sint32 srcy3 = Sint32(sy2<<16);
	Sint32 srcy4 = Sint32(sy3<<16);
	
	Sint32 xstep1 = 0;
	Sint32 xstep2 = Sint32((sx3 - sx1) << 16) / Sint32(y3 - y1);
	Sint32 xstep3 = Sint32((sx4 - sx2) << 16) / Sint32(y4 - y2);
	Sint32 xstep4 = 0;
	
	Sint32 ystep1 = 0;
	Sint32 ystep2 = Sint32((sy3 - sy1) << 16) / Sint32(y3 - y1);
	Sint32 ystep3 = Sint32((sy4 - sy2) << 16) / Sint32(y4 - y2);
	Sint32 ystep4 = 0;
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		if ( SDL_LockSurface(dest) < 0 )
			return;
	
	/* Upper bit of the rectangle */
	if( y1==y2 )
		_TexturedLine(dest,x1,x2,y1,source,sx1,sy1,sx2,sy2);
	else{
		m1 = Sint32((x2 - x1)<<16)/Sint32(y2 - y1);
		
		xstep1 = Sint32((sx2 - sx1) << 16) / Sint32(y2 - y1);
		ystep1 = Sint32((sy2 - sy1) << 16) / Sint32(y2 - y1);
		
		for ( y = y1; y <= y2; y++) {
			_TexturedLine(dest, xa>>16, xb>>16, y, source, srcx1>>16, srcy1>>16, srcx2>>16, srcy2>>16);
				
			xa += m1;
			xb += m2;
			
			srcx1 += xstep1;
			srcx2 += xstep2;
			srcy1 += ystep1;
			srcy2 += ystep2;
		}
	}
	
	/* Middle bit of the rectangle */	
	for ( y = y2+1; y <= y3; y++) {
		_TexturedLine(dest, xb>>16, xc>>16, y, source, srcx2>>16, srcy2>>16, srcx3>>16, srcy3>>16);

		xb += m2;
		xc += m3;
			
		srcx2 += xstep2;
		srcx3 += xstep3;
		srcy2 += ystep2;
		srcy3 += ystep3;
	}
	
	/* Lower bit of the rectangle */
	if( y3==y4 )
		_TexturedLine(dest,x3,x4,y3,source,sx3,sy3,sx4,sy4);
	else{
		m4 = Sint32((x4 - x3)<<16)/Sint32(y4 - y3);
		
		xstep4 = Sint32((sx4 - sx3) << 16) / Sint32(y4 - y3);
		ystep4 = Sint32((sy4 - sy3) << 16) / Sint32(y4 - y3);
		
		for ( y = y3+1; y <= y4; y++) {
			_TexturedLine(dest, xc>>16, xd>>16, y, source, srcx3>>16, srcy3>>16, srcx4>>16, srcy4>>16);

			xc += m3;
			xd += m4;
			
			srcx3 += xstep3;
			srcx4 += xstep4;
			srcy3 += ystep3;
			srcy4 += ystep4;
		}
			
	}
	
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
	
}



//==================================================================================
// And now to something completly different: Polygons!
//==================================================================================

/* Base polygon structure */
class pline{
public:
	Sint16 x1,x2, y1,y2;
	
	Sint32 fx, fm;
	
	Sint16 x;
	
	pline *next;
	
	virtual void update(void)
	{
		x = Sint16(fx>>16);
		fx += fm;
	}
};

/* Pointer storage (to preserve polymorphism) */
struct pline_p{
	pline *p;
};

/* Radix sort */
pline* rsort(pline *inlist)
{
	if(!inlist)
		return NULL;

	// 16 radix-buckets
	pline* bucket[16] = {NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL};
	pline* bi[16];     // bucket itterator (points to last element in bucket)
	
	pline *plist = inlist;
	
	int i,k;
	pline *j;
	Uint8 nr;
	
	// Radix sort in 4 steps (16-bit numbers)
	for( i = 0; i < 4; i++ ){
		for( j = plist; j; j = j->next ){
			nr = Uint8( ( j->x >> (4*i) ) & 0x000F);  // Get bucket number
			
			if( !bucket[nr] )
				bucket[nr] = j;   // First in bucket
			else
				bi[nr]->next = j; // Put last in bucket
				
			bi[nr] = j;           // Update bucket itterator
		}
		
		// Empty buckets (recombine list)
		j = NULL;
		for( k = 0; k < 16; k++ ){
			if( bucket[k] ){
				if( j )
					j->next = bucket[k]; // Connect elements in buckets
				else
					plist = bucket[k];   // First element
				
				j = bi[k];
			}
			bucket[k] = NULL;            // Empty 
		}
		j->next = NULL;                  // Terminate list
	} 
	
	return plist;
}

/* Calculate the scanline for y */
pline* get_scanline(pline_p *plist, Uint16 n, Sint32 y)
{
	pline* p = NULL;
	pline* list = NULL;
	pline* li = NULL;
		
	for( int i = 0; i < n; i++ ){
		// Is polyline on this scanline?
		p = plist[i].p;
		if( p->y1 <= y  &&  p->y2 >= y  &&  (p->y1 != p->y2) ){		
			if( list )
				li->next = p; // Add last in list
			else
				list = p;     // Add first in list	
							
			li = p;           // Update itterator
					
			// Calculate x
			p->update();
		}
	}

	if( li )
		li->next = NULL;  // terminate

	// Sort list
	return rsort(list);
}

/* Removes duplicates if needed */
inline void remove_dup(pline *li, Sint16 y)
{
	if( li->next )
		if( (y==li->y1 || y==li->y2) && (y==li->next->y1 || y==li->next->y2) )
			if( ((y == li->y1)? -1:1) != ((y == li->next->y1)? -1:1) )
				li->next = li->next->next;
}


//==================================================================================
// Draws a n-points filled polygon
//==================================================================================

int SPG_PolygonFilledBlend(SDL_Surface *dest, Uint16 n, Sint16 *x, Sint16 *y, Uint32 color, Uint8 alpha)
{
	if(n<3)
		return -1;

	if (SDL_MUSTLOCK(dest) && _SPG_lock)
		if (SDL_LockSurface(dest) < 0)
			return -2;

	pline *line = new pline[n];
	pline_p *plist = new pline_p[n];
	
	Sint16 y1,y2, x1, x2, tmp, sy;
	Sint16 ymin = y[1], ymax=y[1];
	Sint16 xmin = x[1], xmax=x[1];
	Uint16 i;
	
	/* Decompose polygon into straight lines */
	for( i = 0; i < n; i++ ){
		y1 = y[i];
		x1 = x[i];
		
		if( i == n-1 ){
			// Last point == First point
			y2 = y[0];
			x2 = x[0];
		}else{
		 	y2 = y[i+1];
			x2 = x[i+1];
		}
		
		// Make sure y1 <= y2
		if( y1 > y2 ) {
			SWAP(y1,y2,tmp);
			SWAP(x1,x2,tmp);
		}
		
		// Reject polygons with negative coords
		if( y1 < 0  ||  x1 < 0  ||  x2 < 0 ){
			if (SDL_MUSTLOCK(dest) && _SPG_lock)
				SDL_UnlockSurface(dest);
			
			delete[] line;
			delete[] plist;
			return -1;
		}
		
		if( y1 < ymin )
			ymin = y1;
		if( y2 > ymax )
			ymax = y2;
		if( x1 < xmin )
			xmin = x1;
		else if( x1 > xmax )
			xmax = x1;
		if( x2 < xmin )
			xmin = x2;
		else if( x2 > xmax )
			xmax = x2;
		
		//Fill structure
		line[i].y1 = y1;
		line[i].y2 = y2;
		line[i].x1 = x1;
		line[i].x2 = x2;
		
		// Start x-value (fixed point)
		line[i].fx = Sint32(x1<<16);
		
		// Lines step value (fixed point)
		if( y1 != y2)
			line[i].fm = Sint32((x2 - x1)<<16)/Sint32(y2 - y1);
		else
			line[i].fm = 0;
		
		line[i].next = NULL;
		
		// Add to list
		plist[i].p = &line[i];
		
		// Draw the polygon outline (looks nicer)
		if( alpha == SDL_ALPHA_OPAQUE )
			_Line(dest,x1,y1,x2,y2,color); // Can't do this with alpha, might overlap with the filling
	}
	
	/* Remove surface lock if _HLine() is to be used */
	if (SDL_MUSTLOCK(dest) && _SPG_lock && alpha == SDL_ALPHA_OPAQUE)
		SDL_UnlockSurface(dest);
	
	pline* list = NULL;
	pline* li = NULL;   // list itterator
	
	// Scan y-lines
	for( sy = ymin; sy <= ymax; sy++){
		list = get_scanline(plist, n, sy);
		
		if( !list )
			continue;     // nothing in list... hmmmm
			
		x1 = x2 = -1;
		
		// Draw horizontal lines between pairs
		for( li = list; li; li = li->next ){
			remove_dup(li, sy);
			
			if( x1 < 0 )
				x1 = li->x+1;
			else if( x2 < 0 )
				x2 = li->x;
				
			if( x1 >= 0  &&  x2 >= 0 ){
				if( x2-x1 < 0  && alpha == SDL_ALPHA_OPAQUE ){
					// Already drawn by the outline
					x1 = x2 = -1;
					continue;
				}
			
				if( alpha == SDL_ALPHA_OPAQUE )
					_HLine(dest, x1, x2, sy, color);
				else
					_HLineAlpha(dest, x1-1, x2, sy, color, alpha);
					
				x1 = x2 = -1;
			}
		}
	}
	
	if (SDL_MUSTLOCK(dest) && _SPG_lock && alpha != SDL_ALPHA_OPAQUE)
		SDL_UnlockSurface(dest);
	
	delete[] line;
	delete[] plist;
	
	
	return 0;
}


int SPG_PolygonFilled(SDL_Surface *dest, Uint16 n, Sint16 *x, Sint16 *y, Uint32 color)
{
	return SPG_PolygonFilledBlend(dest, n, x, y, color, SDL_ALPHA_OPAQUE);
}



//==================================================================================
// Draws a n-points (AA) filled polygon
//==================================================================================

int SPG_PolygonFilledAA(SDL_Surface *dest, Uint16 n, Sint16 *x, Sint16 *y, Uint32 color)
{
	if(n<3)
		return -1;

	
	if (SDL_MUSTLOCK(dest) && _SPG_lock)
		if (SDL_LockSurface(dest) < 0)
			return -2;

	pline *line = new pline[n];
	pline_p *plist = new pline_p[n];
	
	Sint16 y1,y2, x1, x2, tmp, sy;
	Sint16 ymin = y[1], ymax=y[1];
	Sint16 xmin = x[1], xmax=x[1];
	Uint16 i;
	
	/* Decompose polygon into straight lines */
	for( i = 0; i < n; i++ ){
		y1 = y[i];
		x1 = x[i];
		
		if( i == n-1 ){
			// Last point == First point
			y2 = y[0];
			x2 = x[0];
		}else{
		 	y2 = y[i+1];
			x2 = x[i+1];
		}
		
		// Make sure y1 <= y2
		if( y1 > y2 ) {
			SWAP(y1,y2,tmp);
			SWAP(x1,x2,tmp);
		}
		
		// Reject polygons with negative coords
		if( y1 < 0  ||  x1 < 0  ||  x2 < 0 ){
			if (SDL_MUSTLOCK(dest) && _SPG_lock)
				SDL_UnlockSurface(dest);
		
			delete[] line;
			delete[] plist;
			return -1;
		}
		
		if( y1 < ymin )
			ymin = y1;
		if( y2 > ymax )
			ymax = y2;
		if( x1 < xmin )
			xmin = x1;
		else if( x1 > xmax )
			xmax = x1;
		if( x2 < xmin )
			xmin = x2;
		else if( x2 > xmax )
			xmax = x2;
		
		//Fill structure
		line[i].y1 = y1;
		line[i].y2 = y2;
		line[i].x1 = x1;
		line[i].x2 = x2;
		
		// Start x-value (fixed point)
		line[i].fx = Sint32(x1<<16);
		
		// Lines step value (fixed point)
		if( y1 != y2)
			line[i].fm = Sint32((x2 - x1)<<16)/Sint32(y2 - y1);
		else
			line[i].fm = 0;
		
		line[i].next = NULL;
		
		// Add to list
		plist[i].p = &line[i];
		
		// Draw AA Line				
		_AALineAlpha(dest,x1,y1,x2,y2,color, SDL_ALPHA_OPAQUE);
	}
	
	if (SDL_MUSTLOCK(dest) && _SPG_lock)
		SDL_UnlockSurface(dest);
	

	pline* list = NULL;
	pline* li = NULL;   // list itterator
	
	// Scan y-lines
	for( sy = ymin; sy <= ymax; sy++){
		list = get_scanline(plist, n, sy);
		
		if( !list )
			continue;     // nothing in list... hmmmm
			
		x1 = x2 = -1;
		
		// Draw horizontal lines between pairs
		for( li = list; li; li = li->next ){
			remove_dup(li, sy);
			
			if( x1 < 0 )
				x1 = li->x+1;
			else if( x2 < 0 )
				x2 = li->x;
				
			if( x1 >= 0  &&  x2 >= 0 ){
				if( x2-x1 < 0 ){
					x1 = x2 = -1;
					continue;
				}
			
				_HLine(dest, x1, x2, sy, color);

				x1 = x2 = -1;
			}
		}
	}
	
	delete[] line;
	delete[] plist;
	
	
	return 0;
}



//==================================================================================
// Draws a n-points gourand shaded polygon
//==================================================================================

/* faded polygon structure */
class fpline : public pline{
public:
	Uint8 r1, r2; 
	Uint8 g1, g2; 
	Uint8 b1, b2;
	
	Uint32 fr, fg, fb;
	Sint32 fmr, fmg, fmb;
	
	Uint8 r,g,b;
	
	virtual void update(void)
	{
		x = Sint16(fx>>16);
		fx += fm;
		
		r = Uint8(fr>>16);
		g = Uint8(fg>>16);
		b = Uint8(fb>>16);
		
		fr += fmr;
		fg += fmg;
		fb += fmb;
	}
};

int SPG_PolygonFadeBlend(SDL_Surface *dest, Uint16 n, Sint16 *x, Sint16 *y, Uint32* colors)
{
	if(n<3)
		return -1;

	if (SDL_MUSTLOCK(dest) && _SPG_lock)
		if (SDL_LockSurface(dest) < 0)
			return -2;

	fpline *line = new fpline[n];
	pline_p *plist = new pline_p[n];
	
	Sint16 y1,y2, x1, x2, tmp, sy;
	Sint16 ymin = y[1], ymax=y[1];
	Sint16 xmin = x[1], xmax=x[1];
	Uint16 i;
	Uint8 r1=0, g1=0, b1=0, r2=0, g2=0, b2=0, t;
	
	// Decompose polygon into straight lines
	for( i = 0; i < n; i++ ){
		y1 = y[i];
		x1 = x[i];
        r1 = colors[i] & dest->format->Rmask;
        g1 = colors[i] & dest->format->Gmask;
        b1 = colors[i] & dest->format->Bmask;
		
		if( i == n-1 ){
			// Last point == First point
			y2 = y[0];
			x2 = x[0];
			r2 = colors[0] & dest->format->Rmask;
			g2 = colors[0] & dest->format->Gmask;
			b2 = colors[0] & dest->format->Bmask;
		}else{
		 	y2 = y[i+1];
			x2 = x[i+1];
			r2 = colors[i+1] & dest->format->Rmask;
			g2 = colors[i+1] & dest->format->Gmask;
			b2 = colors[i+1] & dest->format->Bmask;
		}
		
		// Make sure y1 <= y2
		if( y1 > y2 ) {
			SWAP(y1,y2,tmp);
			SWAP(x1,x2,tmp);
			SWAP(r1,r2,t);
			SWAP(g1,g2,t);
			SWAP(b1,b2,t);
		}
		
		// Reject polygons with negative coords
		if( y1 < 0  ||  x1 < 0  ||  x2 < 0 ){
			if ( SDL_MUSTLOCK(dest) && _SPG_lock )
				SDL_UnlockSurface(dest);
			
			delete[] line;
			delete[] plist;
			return -1;
		}
		
		if( y1 < ymin )
			ymin = y1;
		if( y2 > ymax )
			ymax = y2;
		if( x1 < xmin )
			xmin = x1;
		else if( x1 > xmax )
			xmax = x1;
		if( x2 < xmin )
			xmin = x2;
		else if( x2 > xmax )
			xmax = x2;
		
		//Fill structure
		line[i].y1 = y1;
		line[i].y2 = y2;
		line[i].x1 = x1;
		line[i].x2 = x2;
		line[i].r1 = r1;
		line[i].g1 = g1;
		line[i].b1 = b1;
		line[i].r2 = r2;
		line[i].g2 = g2;
		line[i].b2 = b2;
		
		// Start x-value (fixed point)
		line[i].fx = Sint32(x1<<16);

		line[i].fr = Uint32(r1<<16);
		line[i].fg = Uint32(g1<<16);
		line[i].fb = Uint32(b1<<16);
		
		// Lines step value (fixed point)
		if( y1 != y2){
			line[i].fm  = Sint32((x2 - x1)<<16)/Sint32(y2 - y1);
			
			line[i].fmr = Sint32((r2 - r1)<<16)/Sint32(y2 - y1);
			line[i].fmg = Sint32((g2 - g1)<<16)/Sint32(y2 - y1);
			line[i].fmb = Sint32((b2 - b1)<<16)/Sint32(y2 - y1);
		}else{
			line[i].fm  = 0;
			line[i].fmr = 0;
			line[i].fmg = 0;
			line[i].fmb = 0;
		}
		
		line[i].next = NULL;
		
		// Add to list
		plist[i].p = &line[i];
		
		// Draw the polygon outline (looks nicer)
		if( (colors[i] & dest->format->Amask) == SDL_ALPHA_OPAQUE )
			SPG_LineMultiFn(dest,x1,y1,x2,y2,SDL_MapRGB(dest->format, r1,g1,b1),SDL_MapRGB(dest->format, r2,g2,b2), _SetPixel); // Can't do this with alpha, might overlap with the filling
	}
	
	fpline* list = NULL;
	fpline* li = NULL;   // list itterator
	
	// Scan y-lines
	for( sy = ymin; sy <= ymax; sy++){
		list = (fpline *)get_scanline(plist, n, sy);
		
		if( !list )
			continue;     // nothing in list... hmmmm
			
		x1 = x2 = -1;
		
		// Draw horizontal lines between pairs
		for( li = list; li; li = (fpline *)li->next ){
			remove_dup(li, sy);
			
			if( x1 < 0 ){
				x1 = li->x+1;
				r1 = li->r;
				g1 = li->g;
				b1 = li->b;
			}else if( x2 < 0 ){
				x2 = li->x;
				r2 = li->r;
				g2 = li->g;
				b2 = li->b;
			}
				
			if( x1 >= 0  &&  x2 >= 0 ){
				if( x2-x1 < 0 && (colors[i] & dest->format->Amask) == SDL_ALPHA_OPAQUE){
					x1 = x2 = -1;
					continue;
				}
			
				if( (colors[i] & dest->format->Amask) == SDL_ALPHA_OPAQUE )
					_FadedLine(dest, x1, x2, sy, r1, g1, b1, r2, g2, b2);
				else{
					_SPG_alpha_hack = (colors[i] & dest->format->Amask);
					SPG_LineMultiFn(dest, x1-1, sy, x2, sy, SDL_MapRGB(dest->format, r1, g1, b1), SDL_MapRGB(dest->format, r2, g2, b2), callback_alpha_hack);
				}
				
				x1 = x2 = -1;
			}
		}
	}
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
		
	delete[] line;
	delete[] plist;
	
	return 0;
}

int SPG_PolygonFade(SDL_Surface *dest, Uint16 n, Sint16 *x, Sint16 *y, Uint32* colors)
{
	return SPG_PolygonFadeBlend(dest, n, x, y, colors);
}


//==================================================================================
// Draws a n-points (AA) gourand shaded polygon
//==================================================================================
int SPG_PolygonFadeAA(SDL_Surface *dest, Uint16 n, Sint16 *x, Sint16 *y, Uint32* colors)
{
	if(n<3)
		return -1;

	if (SDL_MUSTLOCK(dest) && _SPG_lock)
		if (SDL_LockSurface(dest) < 0)
			return -2;

	fpline *line = new fpline[n];
	pline_p *plist = new pline_p[n];
	
	Sint16 y1,y2, x1, x2, tmp, sy;
	Sint16 ymin = y[1], ymax=y[1];
	Sint16 xmin = x[1], xmax=x[1];
	Uint16 i;
	Uint8 r1=0, g1=0, b1=0, r2=0, g2=0, b2=0, t;
	
	// Decompose polygon into straight lines
	for( i = 0; i < n; i++ ){
		y1 = y[i];
		x1 = x[i];
        r1 = colors[i] & dest->format->Rmask;
        g1 = colors[i] & dest->format->Gmask;
        b1 = colors[i] & dest->format->Bmask;
		
		if( i == n-1 ){
			// Last point == First point
			y2 = y[0];
			x2 = x[0];
			r2 = colors[0] & dest->format->Rmask;
			g2 = colors[0] & dest->format->Gmask;
			b2 = colors[0] & dest->format->Bmask;
		}else{
		 	y2 = y[i+1];
			x2 = x[i+1];
			r2 = colors[i+1] & dest->format->Rmask;
			g2 = colors[i+1] & dest->format->Gmask;
			b2 = colors[i+1] & dest->format->Bmask;
		}
		
		// Make sure y1 <= y2
		if( y1 > y2 ) {
			SWAP(y1,y2,tmp);
			SWAP(x1,x2,tmp);
			SWAP(r1,r2,t);
			SWAP(g1,g2,t);
			SWAP(b1,b2,t);
		}
		
		// Reject polygons with negative coords
		if( y1 < 0  ||  x1 < 0  ||  x2 < 0 ){
			if ( SDL_MUSTLOCK(dest) && _SPG_lock )
				SDL_UnlockSurface(dest);
			
			delete[] line;
			delete[] plist;
			return -1;
		}
		
		if( y1 < ymin )
			ymin = y1;
		if( y2 > ymax )
			ymax = y2;
		if( x1 < xmin )
			xmin = x1;
		else if( x1 > xmax )
			xmax = x1;
		if( x2 < xmin )
			xmin = x2;
		else if( x2 > xmax )
			xmax = x2;
		
		//Fill structure
		line[i].y1 = y1;
		line[i].y2 = y2;
		line[i].x1 = x1;
		line[i].x2 = x2;
		line[i].r1 = r1;
		line[i].g1 = g1;
		line[i].b1 = b1;
		line[i].r2 = r2;
		line[i].g2 = g2;
		line[i].b2 = b2;
		
		// Start x-value (fixed point)
		line[i].fx = Sint32(x1<<16);

		line[i].fr = Uint32(r1<<16);
		line[i].fg = Uint32(g1<<16);
		line[i].fb = Uint32(b1<<16);
		
		// Lines step value (fixed point)
		if( y1 != y2){
			line[i].fm  = Sint32((x2 - x1)<<16)/Sint32(y2 - y1);
			
			line[i].fmr = Sint32((r2 - r1)<<16)/Sint32(y2 - y1);
			line[i].fmg = Sint32((g2 - g1)<<16)/Sint32(y2 - y1);
			line[i].fmb = Sint32((b2 - b1)<<16)/Sint32(y2 - y1);
		}else{
			line[i].fm  = 0;
			line[i].fmr = 0;
			line[i].fmg = 0;
			line[i].fmb = 0;
		}
		
		line[i].next = NULL;
		
		// Add to list
		plist[i].p = &line[i];
		
		// Draw the polygon outline (AA)
		_AAmcLineAlpha(dest,x1,y1,x2,y2,SDL_MapRGB(dest->format, r1,g1,b1), SDL_ALPHA_OPAQUE,SDL_MapRGB(dest->format, r2,g2,b2), SDL_ALPHA_OPAQUE);
	}
	
	fpline* list = NULL;
	fpline* li = NULL;   // list itterator
	
	// Scan y-lines
	for( sy = ymin; sy <= ymax; sy++){
		list = (fpline *)get_scanline(plist, n, sy);
		
		if( !list )
			continue;     // nothing in list... hmmmm
			
		x1 = x2 = -1;
		
		// Draw horizontal lines between pairs
		for( li = list; li; li = (fpline *)li->next ){
			remove_dup(li, sy);
			
			if( x1 < 0 ){
				x1 = li->x+1;
				r1 = li->r;
				g1 = li->g;
				b1 = li->b;
			}else if( x2 < 0 ){
				x2 = li->x;
				r2 = li->r;
				g2 = li->g;
				b2 = li->b;
			}
				
			if( x1 >= 0  &&  x2 >= 0 ){
				if( x2-x1 < 0 ){
					x1 = x2 = -1;
					continue;
				}
			
				_FadedLine(dest, x1, x2, sy, r1, g1, b1, r2, g2, b2);

				x1 = x2 = -1;
			}
		}
	}
	
	if ( SDL_MUSTLOCK(dest) && _SPG_lock )
		SDL_UnlockSurface(dest);
		
	delete[] line;
	delete[] plist;
	
	
	return 0;
}
