/*
    SPriG v0.9
    by Jonathan Dearborn 12/10/07
*/



/*
*	SDL Graphics Extension
*	Rotation routines
*
*	Started 000625
*
*	License: LGPL v2+ (see the file LICENSE)
*	(c)1999-2003 Anders Lindström
*/

/*********************************************************************
 *  This library is free software; you can redistribute it and/or    *
 *  modify it under the terms of the GNU Library General Public      *
 *  License as published by the Free Software Foundation; either     *
 *  version 2 of the License, or (at your option) any later version. *
 *********************************************************************/

#include "SPriG.h"
#include <stdio.h>
#include <math.h>

#define SWAP(x,y,temp) temp=x;x=y;y=temp

extern bool _SPG_lock;

void _SetPixelX(SDL_Surface *dest,Sint16 x,Sint16 y,Uint32 color);


SDL_Rect SPG_transform_tmap(SDL_Surface *src, SDL_Surface *dst, float angle, float xscale, float yscale, Uint16 qx, Uint16 qy);


//==================================================================================
// Helper function to SPG_TransformSurface()
// Returns the bounding box
//==================================================================================
void _calcRect(SDL_Surface *src, SDL_Surface *dst, float theta, float xscale, float yscale, Uint16 px, Uint16 py, Uint16 qx, Uint16 qy, Sint16 *xmin, Sint16 *ymin, Sint16 *xmax, Sint16 *ymax)
{
	Sint16 x, y, rx, ry;
	
	// Clip to src surface
	Sint16 sxmin = SPG_clip_xmin(src);
	Sint16 sxmax = SPG_clip_xmax(src);
	Sint16 symin = SPG_clip_ymin(src);
	Sint16 symax = SPG_clip_ymax(src);
	Sint16 sx[]={sxmin, sxmax, sxmin, sxmax};
	Sint16 sy[]={symin, symax, symax, symin};
	
	// We don't really need fixed-point here
	// but why not?
	Sint32 const istx = Sint32((sin(theta)*xscale) * 8192.0);  /* Inverse transform */
	Sint32 const ictx = Sint32((cos(theta)*xscale) * 8192.2);
	Sint32 const isty = Sint32((sin(theta)*yscale) * 8192.0);
	Sint32 const icty = Sint32((cos(theta)*yscale) * 8192.2);

	//Calculate the four corner points
	for(int i=0; i<4; i++){
		rx = sx[i] - px;
		ry = sy[i] - py;
		
		x = Sint16(((ictx*rx - isty*ry) >> 13) + qx);
		y = Sint16(((icty*ry + istx*rx) >> 13) + qy);
		
		
		if(i==0){
			*xmax = *xmin = x;
			*ymax = *ymin = y;
		}else{
			if(x>*xmax)
				*xmax=x;
			else if(x<*xmin)
				*xmin=x;
				
			if(y>*ymax)
				*ymax=y;
			else if(y<*ymin)
				*ymin=y;
		}
	}
	
	//Better safe than sorry...
	*xmin -= 1;
	*ymin -= 1;
	*xmax += 1;
	*ymax += 1;
	
	//Clip to dst surface
	if( !dst )
		return;
	if( *xmin < SPG_clip_xmin(dst) )
		*xmin = SPG_clip_xmin(dst);
	if( *xmax > SPG_clip_xmax(dst) )
		*xmax = SPG_clip_xmax(dst);
	if( *ymin < SPG_clip_ymin(dst) )
		*ymin = SPG_clip_ymin(dst);
	if( *ymax > SPG_clip_ymax(dst) )
		*ymax = SPG_clip_ymax(dst);
}


/*==================================================================================
** Rotate by angle about pivot (px,py) scale by scale and place at
** position (qx,qy). 
** 
** Transformation matrix application (rotated coords "R"):
**
**   / rx \   /  cos(theta)  sin(theta) \  / dx \
**   |    | = |                         |  |    |
**   \ ry /   \ -sin(theta)  cos(theta) /  \ dy /
**
** =>  rx = cos(theta) dx + sin(theta) dy
**     ry = cos(theta) dy - sin(theta) dx 
** but represented as a fixed-point float using integer math
**
** Developed with the help from Terry Hancock (hancock@earthlink.net)
**
**==================================================================================*/
// First we need some macros to handle different bpp
// I'm sorry about this... 
#define TRANSFORM(UintXX, DIV) \
	Sint32 const src_pitch=src->pitch/DIV; \
	Sint32 const dst_pitch=dst->pitch/DIV; \
	UintXX const *src_row = (UintXX *)src->pixels; \
	UintXX *dst_row; \
\
	for (y=ymin; y<ymax; y++){ \
		dy = y - qy; \
\
		sx = Sint32(ctdx  + stx*dy + mx);  /* Compute source anchor points */ \
		sy = Sint32(cty*dy - stdx  + my); \
\
		/* Calculate pointer to dst surface */ \
		dst_row = (UintXX *)dst->pixels + y*dst_pitch; \
\
		for (x=xmin; x<xmax; x++){ \
			rx=Sint16(sx >> 13);  /* Convert from fixed-point */ \
			ry=Sint16(sy >> 13); \
\
			/* Make sure the source pixel is actually in the source image. */ \
			if( (rx>=sxmin) && (rx<=sxmax) && (ry>=symin) && (ry<=symax) ) \
				*(dst_row + x) = *(src_row + ry*src_pitch + rx); \
\
			sx += ctx;  /* Incremental transformations */ \
			sy -= sty; \
		} \
	}
	
	
#define TRANSFORM_GENERIC \
	Uint8 R, G, B, A; \
\
	for (y=ymin; y<ymax; y++){ \
		dy = y - qy; \
\
		sx = Sint32(ctdx  + stx*dy + mx);  /* Compute source anchor points */ \
		sy = Sint32(cty*dy - stdx  + my); \
\
		for (x=xmin; x<xmax; x++){ \
			rx=Sint16(sx >> 13);  /* Convert from fixed-point */ \
			ry=Sint16(sy >> 13); \
\
			/* Make sure the source pixel is actually in the source image. */ \
			if( (rx>=sxmin) && (rx<=sxmax) && (ry>=symin) && (ry<=symax) ){ \
				SPG_GetRGBA(SPG_GetPixel(src,rx,ry), src->format, &R, &G, &B, &A);\
				_SetPixelX(dst,x,y,SPG_MapRGBA(dst->format, R, G, B, A)); \
				\
			} \
			sx += ctx;  /* Incremental transformations */ \
			sy -= sty; \
		} \
	} 


// Interpolated transform
#define TRANSFORM_AA(UintXX, DIV) \
	Sint32 const src_pitch=src->pitch/DIV; \
	Sint32 const dst_pitch=dst->pitch/DIV; \
	UintXX const *src_row = (UintXX *)src->pixels; \
	UintXX *dst_row; \
	UintXX c1, c2, c3, c4;\
	Uint32 R, G, B, A=0; \
	UintXX Rmask = src->format->Rmask, Gmask = src->format->Gmask, Bmask = src->format->Bmask, Amask = src->format->Amask;\
	Uint32 wx, wy;\
	Uint32 p1, p2, p3, p4;\
\
	/* 
	*  Interpolation:
	*  We calculate the distances from our point to the four nearest pixels, d1..d4.
	*  d(a,b) = sqrt(a²+b²) ~= 0.707(a+b)  (Pythagoras (Taylor) expanded around (0.5;0.5))
	*  
	*    1  wx 2
	*     *-|-*  (+ = our point at (x,y))
	*     | | |  (* = the four nearest pixels)
	*  wy --+ |  wx = float(x) - int(x)
	*     |   |  wy = float(y) - int(y)
	*     *---*
	*    3     4
	*  d1 = d(wx,wy)  d2 = d(1-wx,wy)  d3 = d(wx,1-wy)  d4 = d(1-wx,1-wy)
	*  We now want to weight each pixels importance - it's vicinity to our point:
	*  w1=d4  w2=d3  w3=d2  w4=d1  (Yes it works... just think a bit about it)
	*
	*  If the pixels have the colors c1..c4 then our point should have the color
	*  c = (w1*c1 + w2*c2 + w3*c3 + w4*c4)/(w1+w2+w3+w4)   (the weighted average)
	*  but  w1+w2+w3+w4 = 4*0.707  so we might as well write it as
	*  c = p1*c1 + p2*c2 + p3*c3 + p4*c4  where  p1..p4 = (w1..w4)/(4*0.707)
	*
	*  But p1..p4 are fixed point so we can just divide the fixed point constant!
	*  8192/(4*0.71) = 2897  and we can skip 0.71 too (the division will cancel it everywhere)
	*  8192/4 = 2048
	*
	*  020102: I changed the fixed-point representation for the variables in the weighted average
	*          to 24.7 to avoid problems with 32bit colors. Everything else is still 18.13. This
	*          does however not solve the problem with 32bit RGBA colors... 
	*/\
\
	Sint32 const one = 2048>>6;   /* 1 in Fixed-point */ \
	Sint32 const two = 2*2048>>6; /* 2 in Fixed-point */ \
\
	for (y=ymin; y<ymax; y++){ \
		dy = y - qy; \
\
		sx = Sint32(ctdx  + stx*dy + mx);  /* Compute source anchor points */ \
		sy = Sint32(cty*dy - stdx  + my); \
\
		/* Calculate pointer to dst surface */ \
		dst_row = (UintXX *)dst->pixels + y*dst_pitch; \
\
		for (x=xmin; x<xmax; x++){ \
			rx=Sint16(sx >> 13);  /* Convert from fixed-point */ \
			ry=Sint16(sy >> 13); \
\
			/* Make sure the source pixel is actually in the source image. */ \
			if( (rx>=sxmin) && (rx+1<=sxmax) && (ry>=symin) && (ry+1<=symax) ){ \
				wx = (sx & 0x00001FFF) >>8;  /* (float(x) - int(x)) / 4 */ \
				wy = (sy & 0x00001FFF) >>8;\
\
				p4 = wx+wy;\
				p3 = one-wx+wy;\
				p2 = wx+one-wy;\
				p1 = two-wx-wy;\
\
				c1 = *(src_row + ry*src_pitch + rx);\
				c2 = *(src_row + ry*src_pitch + rx+1);\
				c3 = *(src_row + (ry+1)*src_pitch + rx);\
				c4 = *(src_row + (ry+1)*src_pitch + rx+1);\
\
				/* Calculate the average */\
				R = ((p1*(c1 & Rmask) + p2*(c2 & Rmask) + p3*(c3 & Rmask) + p4*(c4 & Rmask))>>7) & Rmask;\
				G = ((p1*(c1 & Gmask) + p2*(c2 & Gmask) + p3*(c3 & Gmask) + p4*(c4 & Gmask))>>7) & Gmask;\
				B = ((p1*(c1 & Bmask) + p2*(c2 & Bmask) + p3*(c3 & Bmask) + p4*(c4 & Bmask))>>7) & Bmask;\
				if(Amask)/** SDL_ALPHA_OPAQUE - added by Jonathan Dearborn 7-28-07 **/\
					A = SDL_ALPHA_OPAQUE - ((p1*(c1 & Amask) + p2*(c2 & Amask) + p3*(c3 & Amask) + p4*(c4 & Amask))>>7) & Amask;\
				\
				*(dst_row + x) = R | G | B | A;\
			} \
			sx += ctx;  /* Incremental transformations */ \
			sy -= sty; \
		} \
	} 

#define TRANSFORM_GENERIC_AA \
	Uint8 R, G, B, A, R1, G1, B1, A1=0, R2, G2, B2, A2=0, R3, G3, B3, A3=0, R4, G4, B4, A4=0; \
	Sint32 wx, wy, p1, p2, p3, p4;\
\
	Sint32 const one = 2048;   /* 1 in Fixed-point */ \
	Sint32 const two = 2*2048; /* 2 in Fixed-point */ \
\
	for (y=ymin; y<ymax; y++){ \
		dy = y - qy; \
\
		sx = Sint32(ctdx  + stx*dy + mx);  /* Compute source anchor points */ \
		sy = Sint32(cty*dy - stdx  + my); \
\
		for (x=xmin; x<xmax; x++){ \
			rx=Sint16(sx >> 13);  /* Convert from fixed-point */ \
			ry=Sint16(sy >> 13); \
\
			/* Make sure the source pixel is actually in the source image. */ \
			if( (rx>=sxmin) && (rx+1<=sxmax) && (ry>=symin) && (ry+1<=symax) ){ \
				wx = (sx & 0x00001FFF) >> 2;  /* (float(x) - int(x)) / 4 */ \
				wy = (sy & 0x00001FFF) >> 2;\
\
				p4 = wx+wy;\
				p3 = one-wx+wy;\
				p2 = wx+one-wy;\
				p1 = two-wx-wy;\
\
				SPG_GetRGBA(SPG_GetPixel(src,rx,  ry), src->format, &R1, &G1, &B1, &A1);\
				SPG_GetRGBA(SPG_GetPixel(src,rx+1,ry), src->format, &R2, &G2, &B2, &A2);\
				SPG_GetRGBA(SPG_GetPixel(src,rx,  ry+1), src->format, &R3, &G3, &B3, &A3);\
				SPG_GetRGBA(SPG_GetPixel(src,rx+1,ry+1), src->format, &R4, &G4, &B4, &A4);\
\
				/* Calculate the average */\
				R = (p1*R1 + p2*R2 + p3*R3 + p4*R4)>>13;\
				G = (p1*G1 + p2*G2 + p3*G3 + p4*G4)>>13;\
				B = (p1*B1 + p2*B2 + p3*B3 + p4*B4)>>13;\
				A = (p1*A1 + p2*A2 + p3*A3 + p4*A4)>>13;\
\
				_SetPixelX(dst,x,y,SPG_MapRGBA(dst->format, R, G, B, A)); \
				\
			} \
			sx += ctx;  /* Incremental transformations */ \
			sy -= sty; \
		} \
	} 

// We get better performance if AA and normal rendering is seperated into two functions (better optimization).
// SPG_TransformSurface() is used as a wrapper.

SDL_Rect SPG_transformNorm(SDL_Surface *src, SDL_Surface *dst, float angle, float xscale, float yscale ,Uint16 px, Uint16 py, Uint16 qx, Uint16 qy, Uint8 flags)
{
	Sint32 dy, sx, sy;
	Sint16 x, y, rx, ry;
	SDL_Rect r;
	r.x = r.y = r.w = r.h = 0;

	float theta = float(angle*PI/180.0);  /* Convert to radians.  */


	// Here we use 18.13 fixed point integer math
	// Sint32 should have 31 usable bits and one for sign
	// 2^13 = 8192

	// Check scales
	Sint32 maxint = Sint32(pow(2.0, sizeof(Sint32)*8.0 - 1 - 13));  // 2^(31-13)
	
	if( xscale == 0 || yscale == 0)
		return r;
		
	if( 8192.0/xscale > maxint )
		xscale =  float(8192.0/maxint);
	else if( 8192.0/xscale < -maxint )
		xscale =  float(-8192.0/maxint);	
		
	if( 8192.0/yscale > maxint )
		yscale =  float(8192.0/maxint);
	else if( 8192.0/yscale < -maxint )
		yscale =  float(-8192.0/maxint);


	// Fixed-point equivalents
	Sint32 const stx = Sint32((sin(theta)/xscale) * 8192.0);
	Sint32 const ctx = Sint32((cos(theta)/xscale) * 8192.0);
	Sint32 const sty = Sint32((sin(theta)/yscale) * 8192.0);
	Sint32 const cty = Sint32((cos(theta)/yscale) * 8192.0);
	Sint32 const mx = Sint32(px*8192.0); 
	Sint32 const my = Sint32(py*8192.0);

	// Compute a bounding rectangle
	Sint16 xmin=0, xmax=dst->w, ymin=0, ymax=dst->h;
	_calcRect(src, dst, theta, xscale, yscale, px, py, qx, qy, &xmin,&ymin, &xmax,&ymax);	

	// Clip to src surface
	Sint16 sxmin = SPG_clip_xmin(src);
	Sint16 sxmax = SPG_clip_xmax(src);
	Sint16 symin = SPG_clip_ymin(src);
	Sint16 symax = SPG_clip_ymax(src);

	// Some terms in the transform are constant
	Sint32 const dx = xmin - qx;
	Sint32 const ctdx = ctx*dx;
	Sint32 const stdx = sty*dx;
	
	// Lock surfaces... hopfully less than two needs locking!
	if ( SDL_MUSTLOCK(src) && _SPG_lock )
		if ( SDL_LockSurface(src) < 0 )
			return r;
	if ( SDL_MUSTLOCK(dst) && _SPG_lock ){
		if ( SDL_LockSurface(dst) < 0 ){
			if ( SDL_MUSTLOCK(src) && _SPG_lock )
				SDL_UnlockSurface(src);
			return r;
		}
	}
	
	
	// Use the correct bpp
	if( src->format->BytesPerPixel == dst->format->BytesPerPixel  &&  src->format->BytesPerPixel != 3 && !(flags&SPG_TSAFE) ){
		switch( src->format->BytesPerPixel ){
			case 1: { /* Assuming 8-bpp */
				TRANSFORM(Uint8, 1)
			}
			break;
			case 2: { /* Probably 15-bpp or 16-bpp */
				TRANSFORM(Uint16, 2)
			}
			break;
			case 4: { /* Probably 32-bpp */
				TRANSFORM(Uint32, 4)
			}
			break;
		}
	}else{
		TRANSFORM_GENERIC
	}


	// Unlock surfaces
	if ( SDL_MUSTLOCK(src) && _SPG_lock )
		SDL_UnlockSurface(src);
	if ( SDL_MUSTLOCK(dst) && _SPG_lock )
		SDL_UnlockSurface(dst);


	//Return the bounding rectangle
	r.x=xmin; r.y=ymin; r.w=xmax-xmin; r.h=ymax-ymin;
	return r;
}


SDL_Rect SPG_transformAA(SDL_Surface *src, SDL_Surface *dst, float angle, float xscale, float yscale ,Uint16 px, Uint16 py, Uint16 qx, Uint16 qy, Uint8 flags)
{
	Sint32 dy, sx, sy;
	Sint16 x, y, rx, ry;
	SDL_Rect r;
	r.x = r.y = r.w = r.h = 0;

	float theta = float(angle*PI/180.0);  /* Convert to radians.  */


	// Here we use 18.13 fixed point integer math
	// Sint32 should have 31 usable bits and one for sign
	// 2^13 = 8192

	// Check scales
	Sint32 maxint = Sint32(pow(2.0, sizeof(Sint32)*8.0 - 1 - 13));  // 2^(31-13)
	
	if( xscale == 0 || yscale == 0)
		return r;
		
	if( 8192.0/xscale > maxint )
		xscale =  float(8192.0/maxint);
	else if( 8192.0/xscale < -maxint )
		xscale =  float(-8192.0/maxint);	
		
	if( 8192.0/yscale > maxint )
		yscale =  float(8192.0/maxint);
	else if( 8192.0/yscale < -maxint )
		yscale =  float(-8192.0/maxint);


	// Fixed-point equivalents
	Sint32 const stx = Sint32((sin(theta)/xscale) * 8192.0);
	Sint32 const ctx = Sint32((cos(theta)/xscale) * 8192.0);
	Sint32 const sty = Sint32((sin(theta)/yscale) * 8192.0);
	Sint32 const cty = Sint32((cos(theta)/yscale) * 8192.0);
	Sint32 const mx = Sint32(px*8192.0); 
	Sint32 const my = Sint32(py*8192.0);

	// Compute a bounding rectangle
	Sint16 xmin=0, xmax=dst->w, ymin=0, ymax=dst->h;
	_calcRect(src, dst, theta, xscale, yscale, px, py, qx, qy, &xmin,&ymin, &xmax,&ymax);	

	// Clip to src surface
	Sint16 sxmin = SPG_clip_xmin(src);
	Sint16 sxmax = SPG_clip_xmax(src);
	Sint16 symin = SPG_clip_ymin(src);
	Sint16 symax = SPG_clip_ymax(src);

	// Some terms in the transform are constant
	Sint32 const dx = xmin - qx;
	Sint32 const ctdx = ctx*dx;
	Sint32 const stdx = sty*dx;
	
	// Lock surfaces... hopfully less than two needs locking!
	if ( SDL_MUSTLOCK(src) && _SPG_lock )
		if ( SDL_LockSurface(src) < 0 )
			return r;
	if ( SDL_MUSTLOCK(dst) && _SPG_lock ){
		if ( SDL_LockSurface(dst) < 0 ){
			if ( SDL_MUSTLOCK(src) && _SPG_lock )
				SDL_UnlockSurface(src);
			return r;
		}
	}
	
	
	// Use the correct bpp
	if( src->format->BytesPerPixel == dst->format->BytesPerPixel  &&  src->format->BytesPerPixel != 3 && !(flags&SPG_TSAFE) ){
		switch( src->format->BytesPerPixel ){
			case 1: { /* Assuming 8-bpp */
				//TRANSFORM_AA(Uint8, 1)
				TRANSFORM_GENERIC_AA
			}
			break;
			case 2: { /* Probably 15-bpp or 16-bpp */
				TRANSFORM_AA(Uint16, 2)
			}
			break;
			case 4: { /* Probably 32-bpp */
				TRANSFORM_AA(Uint32, 4)
			}
			break;
		}
	}else{
		TRANSFORM_GENERIC_AA
	}


	// Unlock surfaces
	if ( SDL_MUSTLOCK(src) && _SPG_lock )
		SDL_UnlockSurface(src);
	if ( SDL_MUSTLOCK(dst) && _SPG_lock )
		SDL_UnlockSurface(dst);

	//Return the bounding rectangle
	r.x=xmin; r.y=ymin; r.w=xmax-xmin; r.h=ymax-ymin;
	return r;
}


SDL_Rect SPG_TransformSurface(SDL_Surface *src, SDL_Surface *dst, float angle, float xscale, float yscale, Uint16 px, Uint16 py, Uint16 qx, Uint16 qy, Uint8 flags)
{
	if(flags&SPG_TTMAP)
		return SPG_transform_tmap(src, dst, angle, xscale, yscale, qx, qy);
	else{
		if(flags&SPG_TAA)
			return SPG_transformAA(src, dst, angle, xscale, yscale, px, py, qx, qy, flags);
		else
			return SPG_transformNorm(src, dst, angle, xscale, yscale, px, py, qx, qy, flags);
	}
}


//==================================================================================
// Same as SPG_TransformSurface() but returns an surface with the result
//==================================================================================
SDL_Surface *SPG_Transform(SDL_Surface *src, Uint32 bcol, float angle, float xscale, float yscale, Uint8 flags)
{
	float theta = float(angle*PI/180.0);  /* Convert to radians.  */
	
	// Compute a bounding rectangle
	Sint16 xmin=0, xmax=0, ymin=0, ymax=0;
	_calcRect(src, NULL, theta, xscale, yscale, 0, 0, 0, 0, &xmin,&ymin, &xmax,&ymax);	

	Sint16 w = xmax-xmin+1; 
	Sint16 h = ymax-ymin+1;
	
	Sint16 qx = -xmin;
	Sint16 qy = -ymin;

	SDL_Surface *dest;
	dest = SDL_CreateRGBSurface(SDL_SWSURFACE, w, h, src->format->BitsPerPixel, src->format->Rmask, src->format->Gmask, src->format->Bmask, src->format->Amask);
	if(!dest)
		return NULL;
		
	SPG_Fill(dest,bcol);  //Set background color
	
	SPG_TransformSurface(src, dest, angle, xscale, yscale, 0, 0, qx, qy, flags);

	return dest;
}


//==================================================================================
// Rotate using texture mapping
//==================================================================================
SDL_Rect SPG_transform_tmap(SDL_Surface *src, SDL_Surface *dst, float angle, float xscale, float yscale, Uint16 qx, Uint16 qy)
{	
	double rad;
	double a=(SPG_clip_xmax(src) - SPG_clip_xmin(src))/2.0;
	double b=(SPG_clip_ymax(src) - SPG_clip_ymin(src))/2.0;
	
	double cosv, sinv;
	
	//Get an exact value if possible
	if(angle==0.0 || angle==360.0){
		cosv=1; sinv=0;	
	}
	else if(angle==90.0){
		cosv=0; sinv=1;
	}
	else if(angle==180.0){
		cosv=-1; sinv=0;
	}
	else if(angle==270.0){
		cosv=0; sinv=-1;
	}
	else{ //Oh well
		rad=angle*(PI/180.0); //Deg => rad
		cosv=cos(rad); sinv=sin(rad);
	}		
	
	//Precalculate as much as possible
	double acosv=a*cosv*xscale, bcosv=b*cosv*yscale;
	double asinv=a*sinv*xscale, bsinv=b*sinv*yscale;
	
	
	/* Do the maths */
	Sint16 xt[4],yt[4];
	
	xt[0] = Sint16((-acosv+bsinv)+qx);
	yt[0] = Sint16((-asinv-bcosv)+qy);
	
	xt[1] = Sint16((acosv+bsinv)+qx);
	yt[1] = Sint16((asinv-bcosv)+qy);

	xt[2] = Sint16((-acosv-bsinv)+qx);
	yt[2] = Sint16((-asinv+bcosv)+qy);
	
	xt[3] = Sint16((acosv-bsinv)+qx);
	yt[3] = Sint16((asinv+bcosv)+qy);
	
	
	//Use a texture mapped rectangle
	SPG_QuadTex(dst,xt[0],yt[0],xt[1],yt[1],xt[2],yt[2],xt[3],yt[3],src, SPG_clip_xmin(src),SPG_clip_ymin(src), SPG_clip_xmax(src),SPG_clip_ymin(src), SPG_clip_xmin(src),SPG_clip_ymax(src), SPG_clip_xmax(src),SPG_clip_ymax(src));
		
	//Or maybe two trigons...
	//SPG_TexturedTrigon(dest,xt[0],yt[0],xt[1],yt[1],xt[2],yt[2],src, SPG_clip_xmin(src),SPG_clip_ymin(src), SPG_clip_xmax(src),SPG_clip_ymin(src), SPG_clip_xmin(src),SPG_clip_ymax(src));
	//SPG_TexturedTrigon(dest,xt[3],yt[3],xt[1],yt[1],xt[2],yt[2],src, SPG_clip_xmax(src),SPG_clip_ymax(src), SPG_clip_xmax(src),SPG_clip_ymin(src), SPG_clip_xmin(src),SPG_clip_ymax(src));
	
	//For debug
	//SPG_Trigon(dest,xt[0],yt[0],xt[1],yt[1],xt[2],yt[2],SDL_MapRGB(dest->format,255,0,0));
	//SPG_Trigon(dest,xt[3],yt[3],xt[1],yt[1],xt[2],yt[2],SDL_MapRGB(dest->format,0,255,0));
	
	Sint16 xmax=xt[0], xmin=xt[0];
	xmax= (xmax>xt[1])? xmax : xt[1];
	xmin= (xmin<xt[1])? xmin : xt[1];
	xmax= (xmax>xt[2])? xmax : xt[2];
	xmin= (xmin<xt[2])? xmin : xt[2];
	xmax= (xmax>xt[3])? xmax : xt[3];
	xmin= (xmin<xt[3])? xmin : xt[3];
	
	Sint16 ymax=yt[0], ymin=yt[0];
	ymax= (ymax>yt[1])? ymax : yt[1];
	ymin= (ymin<yt[1])? ymin : yt[1];
	ymax= (ymax>yt[2])? ymax : yt[2];
	ymin= (ymin<yt[2])? ymin : yt[2];
	ymax= (ymax>yt[3])? ymax : yt[3];
	ymin= (ymin<yt[3])? ymin : yt[3];
	
	SDL_Rect r;
	r.x=xmin; r.y=ymin; r.w=xmax-xmin+1; r.h=ymax-ymin+1;
	return r;	
}



//==================================================================================
// Simpler functions
//==================================================================================

#ifdef _SPG_C_ONLY
SDL_Surface* SPG_Rotate(SDL_Surface *src, float angle, Uint32 bcol)
{
   return SPG_Transform(src, bcol, angle, 1.0, 1.0, 0);
}

SDL_Surface* SPG_RotateAA(SDL_Surface *src, float angle, Uint32 bcol)
{
   return SPG_Transform(src, bcol, angle, 1.0, 1.0, SPG_TAA);
}

SDL_Surface* SPG_Scale(SDL_Surface *src, float xscale, float yscale, Uint32 bcol)
{	
	return SPG_Transform(src, bcol, 0, xscale, yscale, 0);
}

SDL_Surface* SPG_ScaleAA(SDL_Surface *src, float xscale, float yscale, Uint32 bcol)
{	
	return SPG_Transform(src, bcol, 0, xscale, yscale, SPG_TAA);
}
#endif

