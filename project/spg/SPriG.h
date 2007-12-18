/*
    SPriG v0.9
    by Jonathan Dearborn 12/10/07
    
    (consolidated header file for simplicity and ease of installation...)
    Includes:
      sge_internal.h
      sge_config.h - version and language, see below...
      sge_surface.h
      sge_primitives.h
      sge_blib.h
      sge_rotation.h
    
    
*/

#ifndef _SPRIG_H__
#define _SPRIG_H__


//#include "sge_config.h"
#define SPG_VER 0090
#define _SPG_C_AND_CPP  // undef this if you're compiling for C


/*
*	SDL Graphics Extension
*
*	Started 990815
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


#include "SDL.h"



// sge_internal.h

/*
*	SDL Graphics Extension
*	SGE internal header
*
*	Started 000627
*
*	License: LGPL v2+ (see the file LICENSE)
*	(c)2000-2003 Anders Lindström
*/

/*********************************************************************
 *  This library is free software; you can redistribute it and/or    *
 *  modify it under the terms of the GNU Library General Public      *
 *  License as published by the Free Software Foundation; either     *
 *  version 2 of the License, or (at your option) any later version. *
 *********************************************************************/





/*
*  C compatibility
*  Thanks to Ohbayashi Ippei (ohai@kmc.gr.jp) for this clever hack!
*/
#ifdef _SPG_C_AND_CPP
	#ifdef __cplusplus
		#define _SPG_C           /* use extern "C" on base functions */
	#else
		#define _SPG_C_ONLY       /* remove overloaded functions */
		#define _SPG_NO_CLASSES  /* no C++ classes */
	#endif
#endif


/*
*  This is traditional
*/
#ifndef PI
	#define PI 3.1415926535
#endif


/*
*  Bit flags
*/
#define SPG_FLAG0 0x00
#define SPG_FLAG1 0x01
#define SPG_FLAG2 0x02
#define SPG_FLAG3 0x04
#define SPG_FLAG4 0x08
#define SPG_FLAG5 0x10
#define SPG_FLAG6 0x20
#define SPG_FLAG7 0x40
#define SPG_FLAG8 0x80


/*
*  Define the right alpha values 
*  (they were flipped in SDL 1.1.5+)
*  That means alpha is now a measure of opacity
*/
#ifndef SDL_ALPHA_OPAQUE
	#define SDL_ALPHA_OPAQUE 255
#endif
#ifndef SDL_ALPHA_TRANSPARENT
	#define SDL_ALPHA_TRANSPARENT 0
#endif


/*
*  Older versions of SDL don't have SDL_VERSIONNUM
*/
#ifndef SDL_VERSIONNUM
	#define SDL_VERSIONNUM(X, Y, Z)      \
		(X)*1000 + (Y)*100 + (Z)
#endif


/*
*  Older versions of SDL don't have SDL_CreateRGBSurface
*/
#ifndef SDL_AllocSurface
	#define SDL_CreateRGBSurface  SDL_AllocSurface
#endif


/*
*  Macro to get clipping
*/
#if SDL_VERSIONNUM(SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_PATCHLEVEL) >= \
    SDL_VERSIONNUM(1, 1, 5)
	#define SPG_clip_xmin(pnt) pnt->clip_rect.x
	#define SPG_clip_xmax(pnt) pnt->clip_rect.x + pnt->clip_rect.w-1
	#define SPG_clip_ymin(pnt) pnt->clip_rect.y
	#define SPG_clip_ymax(pnt) pnt->clip_rect.y + pnt->clip_rect.h-1
#else
	#define SPG_clip_xmin(pnt) pnt->clip_minx
	#define SPG_clip_xmax(pnt) pnt->clip_maxx
	#define SPG_clip_ymin(pnt) pnt->clip_miny
	#define SPG_clip_ymax(pnt) pnt->clip_maxy
#endif


/*
*  Macro to get the smallest bounding box from two (SDL_Rect) rectangles
*/
#define SPG_RectUnion(dst_rect, rect1, rect2)\
	dst_rect.x = (rect1.x < rect2.x)? rect1.x:rect2.x;\
	dst_rect.y = (rect1.y < rect2.y)? rect1.y:rect2.y;\
	dst_rect.w = (rect1.x + rect1.w > rect2.x + rect2.w)? rect1.x + rect1.w - dst_rect.x : rect2.x + rect2.w - dst_rect.x;\
	dst_rect.h = (rect1.y + rect1.h > rect2.y + rect2.h)? rect1.y + rect1.h - dst_rect.y : rect2.y + rect2.h - dst_rect.y;


/*
*  We need to use alpha sometimes but older versions of SDL don't have
*  alpha support.
*/
#if SDL_VERSIONNUM(SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_PATCHLEVEL) >= \
    SDL_VERSIONNUM(1, 1, 5)
	#define SPG_MapRGBA SDL_MapRGBA
	#define SPG_GetRGBA SDL_GetRGBA
#else
	#define SPG_MapRGBA(fmt, r, g, b, a) SDL_MapRGB(fmt, r, g, b)
	#define SPG_GetRGBA(pixel, fmt, r, g, b, a) SDL_GetRGB(pixel, fmt, r, g, b)
#endif


/*
*  Some compilers use a special export keyword
*  Thanks to Seung Chan Lim (limsc@maya.com or slim@djslim.com) to pointing this out
*  (From SDL)
*/
#ifndef DECLSPEC
	#ifdef __BEOS__
		#if defined(__GNUC__)
			#define DECLSPEC __declspec(dllexport)
		#else
			#define DECLSPEC __declspec(export)
		#endif
	#else
		#ifdef WIN32
			#define DECLSPEC __declspec(dllexport)
		#else
			#define DECLSPEC
		#endif
	#endif
#endif







/*********************************************************************
 *  This library is free software; you can redistribute it and/or    *
 *  modify it under the terms of the GNU Library General Public      *
 *  License as published by the Free Software Foundation; either     *
 *  version 2 of the License, or (at your option) any later version. *
 *********************************************************************/


extern bool _SPG_lock;
extern bool _SPG_blit_surface_alpha;
extern Uint8 _SPG_draw_state[];

// default = 0
#define SPG_DEST_ALPHA 0
#define SPG_SRC_ALPHA 1
#define SPG_COMBINE_ALPHA 2
#define SPG_COPY_NO_ALPHA 3
#define SPG_COPY_SRC_ALPHA 4
#define SPG_COPY_DEST_ALPHA 5
#define SPG_COPY_COMBINE_ALPHA 6
#define SPG_COPY_ALPHA_ONLY 7
#define SPG_COMBINE_ALPHA_ONLY 8

// Alternate names:
#define SPG_SRC_MASK 4
#define SPG_DEST_MASK 5


/* Transformation flags */
#define SPG_TAA SPG_FLAG1
#define SPG_TSAFE SPG_FLAG2
#define SPG_TTMAP SPG_FLAG3


#ifdef _SPG_C // BOTH C and C++
extern "C" {
#endif


// MISC
DECLSPEC void SPG_Lock(bool enable);
DECLSPEC Uint8 SPG_GetLock();
DECLSPEC void SPG_PushState(int state);
DECLSPEC int SPG_PopState();
DECLSPEC void SPG_BlitSurfaceAlpha(bool enable);
DECLSPEC bool SPG_GetBlitSurfaceAlpha();


// PALETTE

DECLSPEC void SPG_Fader(SDL_Surface *surface, Uint8 sR,Uint8 sG,Uint8 sB, Uint8 dR,Uint8 dG,Uint8 dB,Uint32 *ctab,int start, int stop);
DECLSPEC void SPG_AlphaFader(Uint8 sR,Uint8 sG,Uint8 sB,Uint8 sA, Uint8 dR,Uint8 dG,Uint8 dB,Uint8 dA, Uint32 *ctab,int start, int stop);
DECLSPEC void SPG_SetupRainbowPalette(SDL_Surface *surface,Uint32 *ctab,int intensity, int start, int stop);
DECLSPEC void SPG_SetupBWPalette(SDL_Surface *surface,Uint32 *ctab,int start, int stop);


// SURFACE

DECLSPEC int SPG_Blit(SDL_Surface *Src, SDL_Rect* srcRect, SDL_Surface *Dest, SDL_Rect* destRect);
DECLSPEC SDL_Rect SPG_TransformSurface(SDL_Surface *src, SDL_Surface *dst, float angle, float xscale, float yscale, Uint16 px, Uint16 py, Uint16 qx, Uint16 qy, Uint8 flags);
DECLSPEC SDL_Surface* SPG_Transform(SDL_Surface *src, Uint32 bcol, float angle, float xscale, float yscale, Uint8 flags);

DECLSPEC Uint32 SPG_GetPixel(SDL_Surface *surface, Sint16 x, Sint16 y);


// DRAWING

DECLSPEC void SPG_FloodFill(SDL_Surface *dst, Sint16 x, Sint16 y, Uint32 color);

DECLSPEC void SPG_Pixel(SDL_Surface *surface, Sint16 x, Sint16 y, Uint32 color);
DECLSPEC void SPG_PixelBlend(SDL_Surface *surface, Sint16 x, Sint16 y, Uint32 color, Uint8 alpha);
DECLSPEC void SPG_PixelPattern(SDL_Surface *surface, SDL_Rect target, bool* pattern, Uint32* colors);
DECLSPEC void SPG_PixelPatternBlend(SDL_Surface *surface, SDL_Rect target, bool* pattern, Uint32* colors, Uint8* pixelAlpha);


// PRIMITIVES

DECLSPEC void SPG_LineH(SDL_Surface *surface, Sint16 x1, Sint16 x2, Sint16 y, Uint32 Color);
DECLSPEC void SPG_LineHBlend(SDL_Surface *surface, Sint16 x1, Sint16 x2, Sint16 y, Uint32 color, Uint8 alpha);

DECLSPEC void SPG_LineV(SDL_Surface *surface, Sint16 x, Sint16 y1, Sint16 y2, Uint32 Color);
DECLSPEC void SPG_LineVBlend(SDL_Surface *surface, Sint16 x, Sint16 y1, Sint16 y2, Uint32 color, Uint8 alpha);

DECLSPEC void SPG_LineFn(SDL_Surface *surface, Sint16 X1, Sint16 Y1, Sint16 X2, Sint16 Y2, Uint32 Color, void Callback(SDL_Surface *Surf, Sint16 X, Sint16 Y, Uint32 Color));
DECLSPEC void SPG_Line(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 Color);
DECLSPEC void SPG_LineBlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color, Uint8 alpha);

// INLINED DECLSPEC void SPG_LineAA(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color);
DECLSPEC void SPG_LineAABlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color, Uint8 alpha);

DECLSPEC void SPG_LineMultiFn(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint32 color2, void Callback(SDL_Surface *Surf, Sint16 X, Sint16 Y, Uint32 Color));
DECLSPEC void SPG_LineMulti(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint32 color2);
// INLINED DECLSPEC void SPG_LineMultiBlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint8 alpha1, Uint32 color2, Uint8 alpha2);

DECLSPEC void SPG_LineMultiAA(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint32 color2);
DECLSPEC void SPG_LineMultiAABlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint8 alpha1, Uint32 color2, Uint8 alpha2);

DECLSPEC void SPG_LineFade(SDL_Surface *dest,Sint16 x1,Sint16 x2,Sint16 y, Uint32 color1, Uint32 color2);
DECLSPEC void SPG_LineTex(SDL_Surface *dest,Sint16 x1,Sint16 x2,Sint16 y,SDL_Surface *source,Sint16 sx1,Sint16 sy1,Sint16 sx2,Sint16 sy2);


DECLSPEC void SPG_Rect(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color);
DECLSPEC void SPG_RectBlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color, Uint8 alpha);

DECLSPEC void SPG_RectFilled(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color);
DECLSPEC void SPG_RectFilledBlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color, Uint8 alpha);


DECLSPEC void SPG_EllipseFn(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color, void Callback(SDL_Surface *Surf, Sint16 X, Sint16 Y, Uint32 Color));
DECLSPEC void SPG_Ellipse(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color);
DECLSPEC void SPG_EllipseBlend(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color, Uint8 alpha);

DECLSPEC void SPG_EllipseFilled(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color);
DECLSPEC void SPG_EllipseFilledBlend(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color, Uint8 alpha);

// INLINED DECLSPEC void SPG_EllipseAA(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color);
DECLSPEC void SPG_EllipseAABlend(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color, Uint8 alpha);

DECLSPEC void SPG_EllipseFilledAA(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color);
DECLSPEC void SPG_EllipseFilledAABlend(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color, Uint8 alpha);


DECLSPEC void SPG_CircleFn(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color, void Callback(SDL_Surface *Surf, Sint16 X, Sint16 Y, Uint32 Color));
DECLSPEC void SPG_Circle(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color);
DECLSPEC void SPG_CircleBlend(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color, Uint8 alpha);

DECLSPEC void SPG_CircleFilled(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color);
DECLSPEC void SPG_CircleFilledBlend(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color, Uint8 alpha);

// INLINED DECLSPEC void SPG_CircleAA(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color);
// INLINED DECLSPEC void SPG_CircleAABlend(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color, Uint8 alpha);

// INLINED DECLSPEC void SPG_CircleFilledAA(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color);
DECLSPEC void SPG_CircleFilledAABlend(SDL_Surface *surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color, Uint8 alpha);


DECLSPEC void SPG_Bezier(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2,Sint16 x3, Sint16 y3, Sint16 x4, Sint16 y4, int level, Uint32 color);
DECLSPEC void SPG_BezierBlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2,Sint16 x3, Sint16 y3, Sint16 x4, Sint16 y4, int level, Uint32 color, Uint8 alpha);

DECLSPEC void SPG_BezierAA(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2,Sint16 x3, Sint16 y3, Sint16 x4, Sint16 y4, int level, Uint32 color);
DECLSPEC void SPG_BezierAABlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2,Sint16 x3, Sint16 y3, Sint16 x4, Sint16 y4, int level, Uint32 color, Uint8 alpha);


// POLYGONS

DECLSPEC void SPG_Trigon(SDL_Surface *surface,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color);
DECLSPEC void SPG_TrigonBlend(SDL_Surface *surface,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color, Uint8 alpha);

DECLSPEC void SPG_TrigonAA(SDL_Surface *surface,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color);
DECLSPEC void SPG_TrigonAABlend(SDL_Surface *surface,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color, Uint8 alpha);

DECLSPEC void SPG_TrigonFilled(SDL_Surface *surface,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color);
DECLSPEC void SPG_TrigonFilledBlend(SDL_Surface *surface,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color, Uint8 alpha);

DECLSPEC void SPG_TrigonFade(SDL_Surface *surface,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Uint32 color1,Uint32 color2,Uint32 color3);
DECLSPEC void SPG_TrigonTex(SDL_Surface *surface,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,SDL_Surface *source,Sint16 sx1,Sint16 sy1,Sint16 sx2,Sint16 sy2,Sint16 sx3,Sint16 sy3);


DECLSPEC void SPG_QuadTex(SDL_Surface *surface,Sint16 x1,Sint16 y1,Sint16 x2,Sint16 y2,Sint16 x3,Sint16 y3,Sint16 x4,Sint16 y4,SDL_Surface *source,Sint16 sx1,Sint16 sy1,Sint16 sx2,Sint16 sy2,Sint16 sx3,Sint16 sy3,Sint16 sx4,Sint16 sy4);


DECLSPEC int SPG_PolygonFilled(SDL_Surface *surface, Uint16 n, Sint16 *x, Sint16 *y, Uint32 color);
DECLSPEC int SPG_PolygonFilledBlend(SDL_Surface *surface, Uint16 n, Sint16 *x, Sint16 *y, Uint32 color, Uint8 alpha);

DECLSPEC int SPG_PolygonFilledAA(SDL_Surface *surface, Uint16 n, Sint16 *x, Sint16 *y, Uint32 color);
DECLSPEC int SPG_PolygonFilledAABlend(SDL_Surface *surface, Uint16 n, Sint16 *x, Sint16 *y, Uint32 color, Uint8 alpha);

DECLSPEC int SPG_PolygonFade(SDL_Surface *surface, Uint16 n, Sint16 *x, Sint16 *y, Uint32* colors);
DECLSPEC int SPG_PolygonFadeBlend(SDL_Surface *surface, Uint16 n, Sint16 *x, Sint16 *y, Uint32* colors, Uint8 alpha);

DECLSPEC int SPG_PolygonFadeAA(SDL_Surface *surface, Uint16 n, Sint16 *x, Sint16 *y, Uint32* colors);
DECLSPEC int SPG_PolygonFadeAABlend(SDL_Surface *surface, Uint16 n, Sint16 *x, Sint16 *y, Uint32* colors, Uint8 alpha);

#ifdef _SPG_C
}
#endif


#ifdef _SPG_C_ONLY  // C-only (no inline keyword)

DECLSPEC SDL_Surface* SPG_DisplayFormatAlpha(SDL_Surface* surf);
DECLSPEC SDL_Surface* SPG_CreateAlphaSurfaceFrom(void* linearArray, int width, int height, SDL_PixelFormat* format);
DECLSPEC SDL_Rect SPG_MakeRect(int x, int y, int w, int h);
DECLSPEC SDL_Rect SPG_MakeRectRelative(int x, int y, int x2, int y2);
DECLSPEC SDL_Color SPG_ToColor(Uint8 R, Uint8 G, Uint8 B);
DECLSPEC SDL_Color SPG_GetColor(SDL_Surface* Surface, Uint32 Color);

DECLSPEC SDL_Surface *SPG_CreateAlphaSurface(Uint32 flags, int width, int height);
#endif /* _SPG_C_ONLY */



// Include all convenience calls
#include "SPriG_Inline.h"


// OLD HEADER COMMENTS
//#include "sge_surface.h"
/*
*	SDL Graphics Extension
*	Pixel, surface and color functions (header)
*   
*	Started 990815 (split from sge_draw 010611)
*
*	License: LGPL v2+ (see the file LICENSE)
*	(c)1999-2003 Anders Lindström
*/

//#include "sge_primitives.h"
/*
*	SDL Graphics Extension
*	Drawing primitives (header)
*
*	Started 990815 (split from sge_draw 010611)
*
*	License: LGPL v2+ (see the file LICENSE)
*	(c)1999-2003 Anders Lindström
*/



//#include "sge_blib.h"
/*
*	SDL Graphics Extension
*	Johan E. Thelin's BLib (header)
*
*	Started 000428
*
*	License: LGPL v2+ (see the file LICENSE)
*	(c)2000-2003 Anders Lindström & Johan E. Thelin
*/

/*
*	SDL Graphics Extension
*	Rotation routines (header)
*
*	Started 000625
*
*	License: LGPL v2+ (see the file LICENSE)
*	(c)1999-2003 Anders Lindström
*/




#endif /* _SPRIG_H__ */



