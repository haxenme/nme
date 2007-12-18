#ifndef _SPG_INLINE_H__
#define _SPG_INLINE_H__


#include <string.h>  // for memcpy




/* Surface */

#ifdef _SPG_C_ONLY



#define SPG_SetColorkey(surface, color)\
    SDL_SetColorKey(surface, SDL_SRCCOLORKEY, color)

#define SPG_Clamp(value, min, max)\
    ((value < min)? min : (value > max)? max : value)


#define SPG_Draw(source, dest, x, y)\
{\
    SDL_Rect rect;\
    rect.x = x;\
    rect.y = y;\
    SDL_BlitSurface(source, NULL, dest, &rect);\
}

#define SPG_DrawBlit(source, dest, x, y)\
{\
    SDL_Rect rect;\
    rect.x = x;\
    rect.y = y;\
    SPG_Blit(source, NULL, dest, &rect);\
}

#define SPG_SetClip(surface, rect)\
    surface->clip_rect = rect

#define SPG_RestoreClip(surface)\
{\
    surface->clip_rect.x = 0;\
    surface->clip_rect.y = 0;\
    surface->clip_rect.w = surface->w;\
    surface->clip_rect.h = surface->h;\
}



#define SPG_CopySurface(src)\
    SDL_ConvertSurface(src, src->format, SDL_SWSURFACE)

#define SPG_Rotate(src, angle, bcol)\
    SPG_Transform(src, bcol, angle, 1.0, 1.0, 0)

#define SPG_RotateAA(src, angle, bcol)\
    SPG_Transform(src, bcol, angle, 1.0, 1.0, SPG_TAA)

#define SPG_Scale(src, xscale, yscale, bcol)\
    SPG_Transform(src, bcol, 0, xscale, yscale, 0)

#define SPG_ScaleAA(src, xscale, yscale, bcol)\
    SPG_Transform(src, bcol, 0, xscale, yscale, SPG_TAA)

#define SPG_MixAlpha(surface, color, alpha)\
    ((color & (surface->format->Rmask | surface->format->Gmask | surface->format->Bmask)) | (alpha << surface->format->Ashift))

#define SPG_SetSurfaceAlpha(surface, alpha)\
    surface->format->alpha = alpha

#define SPG_Fill(surface, color)\
	SDL_FillRect(surface, NULL, color)

#define SPG_FillAlpha(surface, color, alpha)\
	SDL_FillRect(surface, NULL, SPG_MixAlpha(surface, color, alpha))


#define SPG_Map(surface, r, g, b)\
    SDL_MapRGB(surface->format, r, g, b)

#define SPG_MapAlpha(surface, r, g, b, a)\
    SDL_MapRGBA(surface->format, r, g, b, a)



#define SPG_BlockWrite8(Surface, block, y)\
	memcpy(	(Uint8 *)Surface->pixels + y*Surface->pitch, block, sizeof(Uint8)*Surface->w )
#define SPG_BlockWrite16(Surface, block, y)\
	memcpy(	(Uint16 *)Surface->pixels + y*Surface->pitch/2, block, sizeof(Uint16)*Surface->w )
	
#define SPG_BlockWrite32(Surface, block, y)\
	memcpy(	(Uint32 *)Surface->pixels + y*Surface->pitch/4, block, sizeof(Uint32)*Surface->w )
	

#define SPG_BlockRead8(Surface, block, y)\
	memcpy(	block,(Uint8 *)Surface->pixels + y*Surface->pitch, sizeof(Uint8)*Surface->w )
	
#define SPG_BlockRead16(Surface, block, y)\
	memcpy(	block,(Uint16 *)Surface->pixels + y*Surface->pitch/2, sizeof(Uint16)*Surface->w )
	
#define SPG_BlockRead32(Surface, block, y)\
	memcpy(	block,(Uint32 *)Surface->pixels + y*Surface->pitch/4, sizeof(Uint32)*Surface->w )



#else /* C++ */


inline void SPG_SetColorkey(SDL_Surface* surface, Uint32 color)
{
    SDL_SetColorKey(surface, SDL_SRCCOLORKEY, color);  //transparency
}

inline int SPG_Clamp(int value, int min, int max)
{
    return ((value < min)? min : (value > max)? max : value);
}

inline SDL_Surface* SPG_DisplayFormatAlpha(SDL_Surface* surf)
{
    SDL_Surface* temp = SDL_DisplayFormatAlpha(surf);
    SDL_FreeSurface(surf);
    return temp;
}

inline SDL_Surface* SPG_CreateAlphaSurfaceFrom(void* linearArray, int width, int height, SDL_PixelFormat* format)
{
    SDL_Surface* result = SDL_CreateRGBSurfaceFrom(linearArray, width, height, 32, width*4, format->Rmask, format->Gmask, format->Bmask, format->Amask);
    SDL_SetAlpha(result, SDL_SRCALPHA, SDL_ALPHA_OPAQUE);
    return result;
}

inline void SPG_Draw(SDL_Surface* source, SDL_Surface* dest, int x, int y)
{
    SDL_Rect rect;
    rect.x = x;
    rect.y = y;
    SDL_BlitSurface(source, NULL, dest, &rect);
}

inline void SPG_DrawBlit(SDL_Surface* source, SDL_Surface* dest, int x, int y)
{
    SDL_Rect rect;
    rect.x = x;
    rect.y = y;
    SPG_Blit(source, NULL, dest, &rect);
}

inline void SPG_SetClip(SDL_Surface* surface, SDL_Rect& rect)
{
    surface->clip_rect = rect;
}

inline void SPG_RestoreClip(SDL_Surface* surface)
{
    surface->clip_rect.x = 0;
    surface->clip_rect.y = 0;
    surface->clip_rect.w = surface->w;
    surface->clip_rect.h = surface->h;
}

inline SDL_Rect SPG_MakeRect(int x, int y, int w, int h)
{
    SDL_Rect r;
    r.x = x;
    r.y = y;
    r.w = w;
    r.h = h;
    return r;
}

inline SDL_Rect SPG_MakeRectRelative(int x, int y, int x2, int y2)
{
    SDL_Rect r;
    r.x = x;
    r.y = y;
    r.w = x2 - x;
    r.h = y2 - y;
    return r;
}

inline SDL_Surface* SPG_CreateAlphaSurface(Uint32 flags, int width, int height)
{
    #if SDL_BYTEORDER == SDL_BIG_ENDIAN
        SDL_Surface* result = SDL_CreateRGBSurface(flags,width,height,32, 0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);
    #else
        SDL_Surface* result = SDL_CreateRGBSurface(flags,width,height,32, 0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);
    #endif
    SDL_SetAlpha(result, SDL_SRCALPHA, SDL_ALPHA_OPAQUE);
	return result;
}


inline SDL_Surface* SPG_CopySurface(SDL_Surface *src)
{
	return SDL_ConvertSurface(src, src->format, SDL_SWSURFACE);
}

inline SDL_Surface* SPG_Rotate(SDL_Surface *src, float angle, Uint32 bcol = 0)
{
    return SPG_Transform(src, bcol, angle, 1.0, 1.0, 0);
}

inline SDL_Surface* SPG_RotateAA(SDL_Surface *src, float angle, Uint32 bcol = 0)
{
    return SPG_Transform(src, bcol, angle, 1.0, 1.0, SPG_TAA);
}

inline SDL_Surface* SPG_Scale(SDL_Surface *src, float xscale, float yscale, Uint32 bcol = 0)
{
    return SPG_Transform(src, bcol, 0, xscale, yscale, 0);
}

inline SDL_Surface* SPG_ScaleAA(SDL_Surface *src, float xscale, float yscale, Uint32 bcol = 0)
{
    return SPG_Transform(src, bcol, 0, xscale, yscale, SPG_TAA);
}

inline Uint32 SPG_MixAlpha(SDL_Surface *surface, Uint32 color, Uint8 alpha)
{
    SDL_PixelFormat* format = surface->format;
    return (color & (format->Rmask | format->Gmask | format->Bmask)) | (alpha << format->Ashift);
}

inline void SPG_SetSurfaceAlpha(SDL_Surface* surface, Uint8 alpha)
{
    surface->format->alpha = alpha;
}

inline void SPG_Fill(SDL_Surface *surface, Uint32 color)
{
	SDL_FillRect(surface, NULL, color);
}

inline void SPG_FillAlpha(SDL_Surface *surface, Uint32 color, Uint8 alpha)
{
	SDL_FillRect(surface, NULL, SPG_MixAlpha(surface, color, alpha));
}






inline Uint32 SPG_Map(SDL_Surface* surface, Uint8 r, Uint8 g, Uint8 b)
{
    return SDL_MapRGB(surface->format, r, g, b);
}

inline Uint32 SPG_MapAlpha(SDL_Surface* surface, Uint8 r, Uint8 g, Uint8 b, Uint8 a)
{
    return SDL_MapRGBA(surface->format, r, g, b, a);
}



inline SDL_Color SPG_ToColor(Uint8 R, Uint8 G, Uint8 B)
{
   SDL_Color color;

   color.r = R;
   color.g = G;
   color.b = B;

   return color;
}

inline SDL_Color SPG_GetColor(SDL_Surface *Surface, Uint32 Color)
{
	SDL_Color rgb;
	SDL_GetRGB(Color, Surface->format, &(rgb.r), &(rgb.g), &(rgb.b));

	return(rgb);
}




inline void SPG_BlockWrite8(SDL_Surface *Surface, Uint8 *block, Sint16 y)
{
	memcpy(	(Uint8 *)Surface->pixels + y*Surface->pitch, block, sizeof(Uint8)*Surface->w );
}
inline void SPG_BlockWrite16(SDL_Surface *Surface, Uint16 *block, Sint16 y)
{
	memcpy(	(Uint16 *)Surface->pixels + y*Surface->pitch/2, block, sizeof(Uint16)*Surface->w );
}
inline void SPG_BlockWrite32(SDL_Surface *Surface, Uint32 *block, Sint16 y)
{
	memcpy(	(Uint32 *)Surface->pixels + y*Surface->pitch/4, block, sizeof(Uint32)*Surface->w );
}

inline void SPG_BlockRead8(SDL_Surface *Surface, Uint8 *block, Sint16 y)
{
	memcpy(	block,(Uint8 *)Surface->pixels + y*Surface->pitch, sizeof(Uint8)*Surface->w );
}
inline void SPG_BlockRead16(SDL_Surface *Surface, Uint16 *block, Sint16 y)
{
	memcpy(	block,(Uint16 *)Surface->pixels + y*Surface->pitch/2, sizeof(Uint16)*Surface->w );
}
inline void SPG_BlockRead32(SDL_Surface *Surface, Uint32 *block, Sint16 y)
{
	memcpy(	block,(Uint32 *)Surface->pixels + y*Surface->pitch/4, sizeof(Uint32)*Surface->w );
}




#endif











/* Primitives */

#ifdef _SPG_C_ONLY

#define SPG_LineAA(dst, x1, y1, x2, y2, color)\
	SPG_LineAABlend(dst, x1,y1, x2,y2, color, SDL_ALPHA_OPAQUE)

#define SPG_LineMultiAA(Surface, x1, y1, x2, y2, color1, color2)\
	SPG_LineMultiAABlend(Surface, x1,y1, x2,y2, color1, SDL_ALPHA_OPAQUE, color2, SDL_ALPHA_OPAQUE)

#define SPG_EllipseAA(surface, xc, yc, rx, ry, color)\
	SPG_EllipseAABlend(surface,xc,yc,rx,ry,color, SDL_ALPHA_OPAQUE)

#define SPG_CircleAABlend(surface, xc, yc, r, color, alpha)\
	SPG_EllipseAABlend(surface, xc, yc, r, r, color, alpha)

#define SPG_CircleAA(surface, xc, yc, r, color)\
	SPG_EllipseAABlend(surface,xc,yc,r,r,color, SDL_ALPHA_OPAQUE)

#define SPG_CircleFilledAA(surface, xc, yc, r, color)\
	SPG_EllipseFilledAA(surface, xc, yc, r, r, color)

#else

inline void SPG_LineAA(SDL_Surface *dst, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color)
{
	SPG_LineAABlend(dst, x1,y1, x2,y2, color, SDL_ALPHA_OPAQUE);
}

inline void SPG_LineMultiAA(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint32 color2)
{
	SPG_LineMultiAABlend(Surface, x1,y1, x2,y2, color1, SDL_ALPHA_OPAQUE, color2, SDL_ALPHA_OPAQUE);
}

inline void SPG_EllipseAA(SDL_Surface *surface, Sint16 xc, Sint16 yc, Sint16 rx, Sint16 ry, Uint32 color)
{
	SPG_EllipseAABlend(surface,xc,yc,rx,ry,color, SDL_ALPHA_OPAQUE);
}

inline void SPG_CircleAABlend(SDL_Surface *surface, Sint16 xc, Sint16 yc, Sint16 r, Uint32 color, Uint8 alpha)
{
	SPG_EllipseAABlend(surface, xc, yc, r, r, color, alpha);
}

inline void SPG_CircleAA(SDL_Surface *surface, Sint16 xc, Sint16 yc, Sint16 r, Uint32 color)
{
	SPG_EllipseAABlend(surface,xc,yc,r,r,color, SDL_ALPHA_OPAQUE);
}

inline void SPG_CircleFilledAA(SDL_Surface *surface, Sint16 xc, Sint16 yc, Sint16 r, Uint32 color)
{
	SPG_EllipseFilledAA(surface, xc, yc, r, r, color);
}

#endif





#endif



