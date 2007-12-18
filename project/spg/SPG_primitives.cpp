/*
    SPriG v0.9
    by Jonathan Dearborn 12/10/07
*/



/*
*	SDL Graphics Extension
*	Drawing primitives
*
*	Started 990815 (split from sge_draw 010611)
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

/*
*  Some of this code is taken from the "Introduction to SDL" and
*  John Garrison's PowerPak
*/

#include <math.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include "SPriG.h"


void _SetPixel(SDL_Surface *surface, Sint16 x, Sint16 y, Uint32 color);
void _PutPixelAlpha(SDL_Surface *surface, Sint16 x, Sint16 y, Uint32 color, Uint8 alpha);

/* Global for SPG_Lock (defined in SPG_surface) */
extern bool _SPG_lock;

#define SWAP(x,y,temp) temp=x;x=y;y=temp



void SPG_PixelPattern(SDL_Surface *surface, SDL_Rect target, bool* pattern, Uint32* colors)
{
    if ( SDL_MUSTLOCK(surface) && _SPG_lock )
    {
        if ( SDL_LockSurface(surface) < 0 )
        {
            return;
        }
    }

    int x = target.x, y = target.y;
    int ox = x, oy = y;
    int w = target.w, h = target.h, wh = w*h;
    int xw = x+w, yh = y+h;
    Uint32 color;



            switch (surface->format->BytesPerPixel)
            {
            case 1:   /* Assuming 8-bpp */
            for (int i = 0; i < wh; i++)
            {
                color = colors[i];
                if (pattern[i] && x>=SPG_clip_xmin(surface) && x<=SPG_clip_xmax(surface) && y>=SPG_clip_ymin(surface) && y<=SPG_clip_ymax(surface))
                {
                    *((Uint8 *)surface->pixels + y*surface->pitch + x) = color;
                }
                
                x++;
                if (x >= xw)
                {
                    x = ox;
                    y++;
                    if (y >= yh)
                        break;
                }
            }
            break;

            case 2:   /* Probably 15-bpp or 16-bpp */
            for (int i = 0; i < wh; i++)
            {
                color = colors[i];
                if (pattern[i] && x>=SPG_clip_xmin(surface) && x<=SPG_clip_xmax(surface) && y>=SPG_clip_ymin(surface) && y<=SPG_clip_ymax(surface))
                {
                    *((Uint16 *)surface->pixels + y*surface->pitch/2 + x) = color;
                }
                
                x++;
                if (x >= xw)
                {
                    x = ox;
                    y++;
                    if (y >= yh)
                        break;
                }
            }
            break;

            case 3:   /* Slow 24-bpp mode, usually not used */
            for (int i = 0; i < wh; i++)
            {
                color = colors[i];
                if (pattern[i] && x>=SPG_clip_xmin(surface) && x<=SPG_clip_xmax(surface) && y>=SPG_clip_ymin(surface) && y<=SPG_clip_ymax(surface))
                {
                    Uint8 *pix = (Uint8 *)surface->pixels + y * surface->pitch + x*3;

                    /* Gack - slow, but endian correct */
                    *(pix+surface->format->Rshift/8) = color>>surface->format->Rshift;
                    *(pix+surface->format->Gshift/8) = color>>surface->format->Gshift;
                    *(pix+surface->format->Bshift/8) = color>>surface->format->Bshift;
                    *(pix+surface->format->Ashift/8) = color>>surface->format->Ashift;
                }
                
                x++;
                if (x >= xw)
                {
                    x = ox;
                    y++;
                    if (y >= yh)
                        break;
                }
            }
            break;

            case 4:   /* Probably 32-bpp */
            for (int i = 0; i < wh; i++)
            {
                color = colors[i];
                if (pattern[i] && x>=SPG_clip_xmin(surface) && x<=SPG_clip_xmax(surface) && y>=SPG_clip_ymin(surface) && y<=SPG_clip_ymax(surface))
                {
                    *((Uint32 *)surface->pixels + y*surface->pitch/4 + x) = color;
                }
                
                x++;
                if (x >= xw)
                {
                    x = ox;
                    y++;
                    if (y >= yh)
                        break;
                }
            }
            break;
            }
        


    

    if ( SDL_MUSTLOCK(surface) && _SPG_lock )
    {
        SDL_UnlockSurface(surface);
    }
}



void SPG_PixelPatternBlend(SDL_Surface *surface, SDL_Rect target, bool* pattern, Uint32* colors, Uint8* pixelAlpha)
{
    if ( SDL_MUSTLOCK(surface) && _SPG_lock )
    {
        if ( SDL_LockSurface(surface) < 0 )
        {
            return;
        }
    }

    int x = target.x, y = target.y;
    int ox = x, oy = y;
    int w = target.w, h = target.h, wh = w*h;
    int xw = x+w, yh = y+h;
    Uint32 color;
    Uint8 alpha;
    Uint32 Rmask = surface->format->Rmask, Gmask = surface->format->Gmask, Bmask = surface->format->Bmask, Amask = surface->format->Amask;
    Uint32 R,G,B,A=SDL_ALPHA_OPAQUE;

    for (int i = 0; i < wh; i++)
    {
        if (pattern[i] && x>=SPG_clip_xmin(surface) && x<=SPG_clip_xmax(surface) && y>=SPG_clip_ymin(surface) && y<=SPG_clip_ymax(surface))
        {
            color = colors[i];
            alpha = pixelAlpha[i];

            switch (surface->format->BytesPerPixel)
            {
            case 1:   /* Assuming 8-bpp */
            {
                if ( alpha == SDL_ALPHA_OPAQUE )
                {
                    *((Uint8 *)surface->pixels + y*surface->pitch + x) = color;
                }
                else
                {
                    Uint8 *pixel = (Uint8 *)surface->pixels + y*surface->pitch + x;

                    Uint8 dR = surface->format->palette->colors[*pixel].r;
                    Uint8 dG = surface->format->palette->colors[*pixel].g;
                    Uint8 dB = surface->format->palette->colors[*pixel].b;
                    Uint8 sR = surface->format->palette->colors[color].r;
                    Uint8 sG = surface->format->palette->colors[color].g;
                    Uint8 sB = surface->format->palette->colors[color].b;

                    dR = dR + ((sR-dR)*alpha >> 8);
                    dG = dG + ((sG-dG)*alpha >> 8);
                    dB = dB + ((sB-dB)*alpha >> 8);

                    *pixel = SDL_MapRGB(surface->format, dR, dG, dB);
                }
            }
            break;

            case 2:   /* Probably 15-bpp or 16-bpp */
            {
                if ( alpha == SDL_ALPHA_OPAQUE )
                {
                    *((Uint16 *)surface->pixels + y*surface->pitch/2 + x) = color;
                }
                else
                {
                    Uint16 *pixel = (Uint16 *)surface->pixels + y*surface->pitch/2 + x;
                    Uint32 dc = *pixel;

                    R = ((dc & Rmask) + (( (color & Rmask) - (dc & Rmask) ) * alpha >> 8)) & Rmask;
                    G = ((dc & Gmask) + (( (color & Gmask) - (dc & Gmask) ) * alpha >> 8)) & Gmask;
                    B = ((dc & Bmask) + (( (color & Bmask) - (dc & Bmask) ) * alpha >> 8)) & Bmask;
                    if ( Amask )
                        A = ((dc & Amask) + (( (color & Amask) - (dc & Amask) ) * alpha >> 8)) & Amask;

                    *pixel= R | G | B | A;
                }
            }
            break;

            case 3:   /* Slow 24-bpp mode, usually not used */
            {
                Uint8 *pix = (Uint8 *)surface->pixels + y * surface->pitch + x*3;
                Uint8 rshift8=surface->format->Rshift/8;
                Uint8 gshift8=surface->format->Gshift/8;
                Uint8 bshift8=surface->format->Bshift/8;
                Uint8 ashift8=surface->format->Ashift/8;


                if ( alpha == SDL_ALPHA_OPAQUE )
                {
                    *(pix+rshift8) = color>>surface->format->Rshift;
                    *(pix+gshift8) = color>>surface->format->Gshift;
                    *(pix+bshift8) = color>>surface->format->Bshift;
                    *(pix+ashift8) = color>>surface->format->Ashift;
                }
                else
                {
                    Uint8 dR, dG, dB, dA=0;
                    Uint8 sR, sG, sB, sA=0;

                    pix = (Uint8 *)surface->pixels + y * surface->pitch + x*3;

                    dR = *((pix)+rshift8);
                    dG = *((pix)+gshift8);
                    dB = *((pix)+bshift8);
                    dA = *((pix)+ashift8);

                    sR = (color>>surface->format->Rshift)&0xff;
                    sG = (color>>surface->format->Gshift)&0xff;
                    sB = (color>>surface->format->Bshift)&0xff;
                    sA = (color>>surface->format->Ashift)&0xff;

                    dR = dR + ((sR-dR)*alpha >> 8);
                    dG = dG + ((sG-dG)*alpha >> 8);
                    dB = dB + ((sB-dB)*alpha >> 8);
                    dA = dA + ((sA-dA)*alpha >> 8);

                    *((pix)+rshift8) = dR;
                    *((pix)+gshift8) = dG;
                    *((pix)+bshift8) = dB;
                    *((pix)+ashift8) = dA;
                }
            }
            break;

            case 4:   /* Probably 32-bpp */
            {
                if ( alpha == SDL_ALPHA_OPAQUE )
                {
                    *((Uint32 *)surface->pixels + y*surface->pitch/4 + x) = color;
                }
                else
                {
                    Uint32 *pixel = (Uint32 *)surface->pixels + y*surface->pitch/4 + x;
                    Uint32 dc = *pixel;
                    R = color & Rmask;
                    G = color & Gmask;
                    B = color & Bmask;
                    A = 0;


                    switch (_SPG_draw_state[0])
                    {
                    case SPG_COMBINE_ALPHA:  // Blend and combine src and dest alpha, SLOW IMPLEMENTATION
                        R = ((dc & Rmask) + (( R - (dc & Rmask) ) * alpha >> 8)) & Rmask;
                        G = ((dc & Gmask) + (( G - (dc & Gmask) ) * alpha >> 8)) & Gmask;
                        B = ((dc & Bmask) + (( B - (dc & Bmask) ) * alpha >> 8)) & Bmask;
                        if (Amask)
                            A = ((((dc & Amask) >> surface->format->Ashift) + alpha) >> 1) << surface->format->Ashift;
                        break;
                    case SPG_DEST_ALPHA:  // Blend and keep dest alpha
                        R = ((dc & Rmask) + (( R - (dc & Rmask) ) * alpha >> 8)) & Rmask;
                        G = ((dc & Gmask) + (( G - (dc & Gmask) ) * alpha >> 8)) & Gmask;
                        B = ((dc & Bmask) + (( B - (dc & Bmask) ) * alpha >> 8)) & Bmask;
                        if (Amask)
                            A = (dc & Amask);
                        break;
                    case SPG_SRC_ALPHA:  // Blend and keep src alpha
                        R = ((dc & Rmask) + (( R - (dc & Rmask) ) * alpha >> 8)) & Rmask;
                        G = ((dc & Gmask) + (( G - (dc & Gmask) ) * alpha >> 8)) & Gmask;
                        B = ((dc & Bmask) + (( B - (dc & Bmask) ) * alpha >> 8)) & Bmask;
                        if (Amask)
                            A = (alpha << surface->format->Ashift);
                        break;
                    case SPG_COPY_SRC_ALPHA: // Direct copy with src alpha
                        if (Amask)
                            A = (alpha << surface->format->Ashift);
                        break;
                    case SPG_COPY_DEST_ALPHA: // Direct copy with dest alpha
                        if (Amask)
                            A = (dc & Amask);
                        break;
                    case SPG_COPY_COMBINE_ALPHA: // Direct copy with combined alpha, SLOW IMPLEMENTATION
                        if (Amask)
                            A = ((((dc & Amask) >> surface->format->Ashift) + alpha) >> 1) << surface->format->Ashift;
                        break;
                    case SPG_COPY_NO_ALPHA:  // Direct copy, alpha opaque
                        break;
                    case SPG_COPY_ALPHA_ONLY:  // Direct copy of just the alpha
                        R = dc & Rmask;
                        G = dc & Gmask;
                        B = dc & Bmask;
                        if(Amask)
                            A = (alpha << surface->format->Ashift);
                        break;
                    case SPG_COMBINE_ALPHA_ONLY:  // Blend of just the alpha
                        R = dc & Rmask;
                        G = dc & Gmask;
                        B = dc & Bmask;
                        if(Amask)
                            A = ((((dc & Amask) >> surface->format->Ashift) + alpha) >> 1) << surface->format->Ashift;
                        break;
                    }

                    *pixel = R | G | B | A;
                }
            }
            break;
            }
        }


        x++;
        if (x >= xw)
        {
            x = ox;
            y++;
            if (y >= yh)
                break;
        }

    }

    if ( SDL_MUSTLOCK(surface) && _SPG_lock )
    {
        SDL_UnlockSurface(surface);
    }
}







/**********************************************************************************/
/**                             Line functions                                   **/
/**********************************************************************************/

//==================================================================================
// Internal draw horizontal line
//==================================================================================
void _HLine(SDL_Surface *Surface, Sint16 x1, Sint16 x2, Sint16 y, Uint32 Color)
{
    if (x1>x2)
    {
        Sint16 tmp=x1;
        x1=x2;
        x2=tmp;
    }

    //Do the clipping
#if SDL_VERSIONNUM(SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_PATCHLEVEL) < \
    SDL_VERSIONNUM(1, 1, 5)
    if (y<Surface->clip_miny || y>Surface->clip_maxy || x1>Surface->clip_maxx || x2<Surface->clip_minx)
        return;
    if (x1<Surface->clip_minx)
        x1=Surface->clip_minx;
    if (x2>Surface->clip_maxx)
        x2=Surface->clip_maxx;
#endif

    SDL_Rect l;
    l.x=x1;
    l.y=y;
    l.w=x2-x1+1;
    l.h=1;

    SDL_FillRect(Surface, &l, Color);
}

//==================================================================================
// Draw horizontal line
//==================================================================================
void SPG_LineH(SDL_Surface *Surface, Sint16 x1, Sint16 x2, Sint16 y, Uint32 Color)
{
    if (x1>x2)
    {
        Sint16 tmp=x1;
        x1=x2;
        x2=tmp;
    }

    //Do the clipping
#if SDL_VERSIONNUM(SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_PATCHLEVEL) < \
    SDL_VERSIONNUM(1, 1, 5)
    if (y<Surface->clip_miny || y>Surface->clip_maxy || x1>Surface->clip_maxx || x2<Surface->clip_minx)
        return;
    if (x1<Surface->clip_minx)
        x1=Surface->clip_minx;
    if (x2>Surface->clip_maxx)
        x2=Surface->clip_maxx;
#endif

    SDL_Rect l;
    l.x=x1;
    l.y=y;
    l.w=x2-x1+1;
    l.h=1;

    SDL_FillRect(Surface, &l, Color);
}


//==================================================================================
// Internal draw horizontal line (alpha)
//==================================================================================
void _HLineAlpha(SDL_Surface *Surface, Sint16 x1, Sint16 x2, Sint16 y, Uint32 Color, Uint8 alpha)
{
    Uint8 lock = _SPG_lock;
    _SPG_lock = 0;

    SPG_RectFilledBlend(Surface, x1,y,x2,y, Color, alpha);

    _SPG_lock = lock;
}

//==================================================================================
// Draw horizontal line (alpha)
//==================================================================================
void SPG_LineHBlend(SDL_Surface *Surface, Sint16 x1, Sint16 x2, Sint16 y, Uint32 Color, Uint8 alpha)
{
    SPG_RectFilledBlend(Surface, x1,y,x2,y, Color, alpha);
}



//==================================================================================
// Internal draw vertical line
//==================================================================================
void _VLine(SDL_Surface *Surface, Sint16 x, Sint16 y1, Sint16 y2, Uint32 Color)
{
    if (y1>y2)
    {
        Sint16 tmp=y1;
        y1=y2;
        y2=tmp;
    }

    //Do the clipping
#if SDL_VERSIONNUM(SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_PATCHLEVEL) < \
    SDL_VERSIONNUM(1, 1, 5)
    if (x<Surface->clip_minx || x>Surface->clip_maxx || y1>Surface->clip_maxy || y2<Surface->clip_miny)
        return;
    if (y1<Surface->clip_miny)
        y1=Surface->clip_miny;
    if (y2>Surface->clip_maxy)
        y2=Surface->clip_maxy;
#endif

    SDL_Rect l;
    l.x=x;
    l.y=y1;
    l.w=1;
    l.h=y2-y1+1;

    SDL_FillRect(Surface, &l, Color);
}

//==================================================================================
// Draw vertical line
//==================================================================================
void SPG_LineV(SDL_Surface *Surface, Sint16 x, Sint16 y1, Sint16 y2, Uint32 Color)
{
    if (y1>y2)
    {
        Sint16 tmp=y1;
        y1=y2;
        y2=tmp;
    }

    //Do the clipping
#if SDL_VERSIONNUM(SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_PATCHLEVEL) < \
    SDL_VERSIONNUM(1, 1, 5)
    if (x<Surface->clip_minx || x>Surface->clip_maxx || y1>Surface->clip_maxy || y2<Surface->clip_miny)
        return;
    if (y1<Surface->clip_miny)
        y1=Surface->clip_miny;
    if (y2>Surface->clip_maxy)
        y2=Surface->clip_maxy;
#endif

    SDL_Rect l;
    l.x=x;
    l.y=y1;
    l.w=1;
    l.h=y2-y1+1;

    SDL_FillRect(Surface, &l, Color);
}




//==================================================================================
// Internal draw vertical line (alpha - no update)
//==================================================================================
void _VLineAlpha(SDL_Surface *Surface, Sint16 x, Sint16 y1, Sint16 y2, Uint32 Color, Uint8 alpha)
{
    Uint8 lock = _SPG_lock;
    _SPG_lock = 0;
    SPG_RectFilledBlend(Surface, x,y1,x,y2, Color, alpha);
    _SPG_lock = lock;
}

//==================================================================================
// Draw vertical line (alpha)
//==================================================================================
void SPG_LineVBlend(SDL_Surface *Surface, Sint16 x, Sint16 y1, Sint16 y2, Uint32 Color, Uint8 alpha)
{
    SPG_RectFilledBlend(Surface, x,y1,x,y2, Color, alpha);
}




//==================================================================================
// Performs Callback at each line point. (From PowerPak)
//==================================================================================
void SPG_LineFn(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 Color, void Callback(SDL_Surface *Surf, Sint16 X, Sint16 Y, Uint32 Color))
{
    Sint16 dx, dy, sdx, sdy, x, y, px, py;

    dx = x2 - x1;
    dy = y2 - y1;

    sdx = (dx < 0) ? -1 : 1;
    sdy = (dy < 0) ? -1 : 1;

    dx = sdx * dx + 1;
    dy = sdy * dy + 1;

    x = y = 0;

    px = x1;
    py = y1;

    if (dx >= dy)
    {
        for (x = 0; x < dx; x++)
        {
            Callback(Surface, px, py, Color);

            y += dy;
            if (y >= dx)
            {
                y -= dx;
                py += sdy;
            }
            px += sdx;
        }
    }
    else
    {
        for (y = 0; y < dy; y++)
        {
            Callback(Surface, px, py, Color);

            x += dx;
            if (x >= dy)
            {
                x -= dy;
                px += sdx;
            }
            py += sdy;
        }
    }
}




//==================================================================================
// Line clipping
// Standard Cohen-Sutherland algorithm (from gfxPrimitives)
//==================================================================================
#define CLIP_LEFT_EDGE   0x1
#define CLIP_RIGHT_EDGE  0x2
#define CLIP_BOTTOM_EDGE 0x4
#define CLIP_TOP_EDGE    0x8
#define CLIP_INSIDE(a)   (!a)
#define CLIP_REJECT(a,b) (a&b)
#define CLIP_ACCEPT(a,b) (!(a|b))

int clipEncode(Sint16 x, Sint16 y, Sint16 left, Sint16 top, Sint16 right, Sint16 bottom)
{
    int code = 0;

    if (x < left)
        code |= CLIP_LEFT_EDGE;
    else if (x > right)
        code |= CLIP_RIGHT_EDGE;

    if (y < top)
        code |= CLIP_TOP_EDGE;
    else if (y > bottom)
        code |= CLIP_BOTTOM_EDGE;

    return code;
}

int clipLine(SDL_Surface *dst, Sint16 *x1, Sint16 *y1, Sint16 *x2, Sint16 *y2)
{
    int code1, code2;
    bool draw = false;

    Sint16 tmp;
    float m;

    /* Get clipping boundary */
    Sint16 left, right, top, bottom;
    left = SPG_clip_xmin(dst);
    right = SPG_clip_xmax(dst);
    top = SPG_clip_ymin(dst);
    bottom = SPG_clip_ymax(dst);

    while (true)
    {
        code1 = clipEncode(*x1, *y1, left, top, right, bottom);
        code2 = clipEncode(*x2, *y2, left, top, right, bottom);

        if (CLIP_ACCEPT(code1, code2))
        {
            draw = true;
            break;
        }
        else if (CLIP_REJECT(code1, code2))
            break;
        else
        {
            if (CLIP_INSIDE(code1))
            {
                tmp = *x2;
                *x2 = *x1;
                *x1 = tmp;
                tmp = *y2;
                *y2 = *y1;
                *y1 = tmp;
                tmp = code2;
                code2 = code1;
                code1 = tmp;
            }
            if (*x2 != *x1)
                m = (*y2 - *y1) / float(*x2 - *x1);
            else
                m = 1.0;


            if (code1 & CLIP_LEFT_EDGE)
            {
                *y1 += Sint16( (left - *x1) * m );
                *x1 = left;
            }
            else if (code1 & CLIP_RIGHT_EDGE)
            {
                *y1 += Sint16( (right - *x1) * m );
                *x1 = right;
            }
            else if (code1 & CLIP_BOTTOM_EDGE)
            {
                if (*x2 != *x1)
                {
                    *x1 += Sint16( (bottom - *y1) / m );
                }
                *y1 = bottom;
            }
            else if (code1 & CLIP_TOP_EDGE)
            {
                if (*x2 != *x1)
                {
                    *x1 += Sint16( (top - *y1) / m );
                }
                *y1 = top;
            }
        }
    }

    return draw;
}


//==================================================================================
// Draws a line
//==================================================================================
void _Line(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color)
{
    if ( !clipLine(surface, &x1, &y1, &x2, &y2) )
        return;

    Sint16 dx, dy, sdx, sdy, x, y;

    dx = x2 - x1;
    dy = y2 - y1;

    sdx = (dx < 0) ? -1 : 1;
    sdy = (dy < 0) ? -1 : 1;

    dx = sdx * dx + 1;
    dy = sdy * dy + 1;

    x = y = 0;

    Sint16 pixx = surface->format->BytesPerPixel;
    Sint16 pixy = surface->pitch;
    Uint8 *pixel = (Uint8*)surface->pixels + y1*pixy + x1*pixx;

    pixx *= sdx;
    pixy *= sdy;

    if (dx < dy)
    {
        Sint32 tmp = dx;
        dx = dy;
        dy = Sint16(tmp);
        tmp = pixx;
        pixx = pixy;
        pixy = tmp;
    }

    switch (surface->format->BytesPerPixel)
    {
    case 1:
    {
        for (x=0; x < dx; x++)
        {
            *pixel = color;

            y += dy;
            if (y >= dx)
            {
                y -= dx;
                pixel += pixy;
            }
            pixel += pixx;
        }
    }
    break;

    case 2:
    {
        for (x=0; x < dx; x++)
        {
            *(Uint16*)pixel = color;

            y += dy;
            if (y >= dx)
            {
                y -= dx;
                pixel += pixy;
            }
            pixel += pixx;
        }
    }
    break;

    case 3:
    {
        Uint8 rshift8 = surface->format->Rshift/8;
        Uint8 gshift8 = surface->format->Gshift/8;
        Uint8 bshift8 = surface->format->Bshift/8;
        Uint8 ashift8 = surface->format->Ashift/8;

        Uint8 R = (color>>surface->format->Rshift)&0xff;
        Uint8 G = (color>>surface->format->Gshift)&0xff;
        Uint8 B = (color>>surface->format->Bshift)&0xff;
        Uint8 A = (color>>surface->format->Ashift)&0xff;

        for (x=0; x < dx; x++)
        {
            *(pixel+rshift8) = R;
            *(pixel+gshift8) = G;
            *(pixel+bshift8) = B;
            *(pixel+ashift8) = A;

            y += dy;
            if (y >= dx)
            {
                y -= dx;
                pixel += pixy;
            }
            pixel += pixx;
        }
    }
    break;

    case 4:
    {
        for (x=0; x < dx; x++)
        {
            *(Uint32*)pixel = color;

            y += dy;
            if (y >= dx)
            {
                y -= dx;
                pixel += pixy;
            }
            pixel += pixx;
        }
    }
    break;
    }
}

void SPG_Line(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 Color)
{
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        if (SDL_LockSurface(Surface) < 0)
            return;
    }

    /* Draw the line */
    _Line(Surface, x1,y1, x2,y2, Color);

    /* unlock the display */
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }
}




//==================================================================================
// A quick hack to get alpha working with callbacks
//==================================================================================
Uint8 _SPG_alpha_hack = 0;
void callback_alpha_hack(SDL_Surface *surf, Sint16 x, Sint16 y, Uint32 color)
{
    _PutPixelAlpha(surf,x,y,color,_SPG_alpha_hack);
}

//==================================================================================
// Draws a line (alpha)
//==================================================================================
void _LineAlpha(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 Color, Uint8 alpha)
{
    _SPG_alpha_hack = alpha;

    /* Draw the line */
    SPG_LineFn(Surface, x1, y1, x2, y2, Color, callback_alpha_hack);
}

void SPG_LineBlend(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 Color, Uint8 alpha)
{
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
        if (SDL_LockSurface(Surface) < 0)
            return;

    _LineAlpha(Surface, x1,  y1, x2, y2, Color, alpha);

    /* unlock the display */
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }

}



//==================================================================================
// Anti-aliased line
// From SDL_gfxPrimitives written by A. Schiffler (aschiffler@home.com)
//==================================================================================
#define AAbits 8
#define AAlevels 256  /* 2^AAbits */
void _AALineAlpha(SDL_Surface *dst, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color, Uint8 alpha)
{

    Uint32 erracc=0, erradj;
    Uint32 erracctmp, wgt;
    Sint16 tmp, y0p1, x0pxdir;
    Uint8 a;

    /* Keep on working with 32bit numbers */
    Sint32 xx0=x1;
    Sint32 yy0=y1;
    Sint32 xx1=x2;
    Sint32 yy1=y2;

    /* Reorder points if required */
    if (yy0 > yy1)
    {
        SWAP(yy0, yy1, tmp);
        SWAP(xx0, xx1, tmp);
    }

    /* Calculate distance */
    Sint16 dx = xx1 - xx0;
    Sint16 dy = yy1 - yy0;

    /* Adjust for negative dx and set xdir */
    Sint16 xdir = 1;
    if (dx < 0)
    {
        xdir=-1;
        dx=(-dx);
    }

    /* Check for special cases */
    if (dx==0 || dy==0 || dx==dy)
    {
        if (alpha==SDL_ALPHA_OPAQUE)
            _Line(dst,x1,y1,x2,y2,color);
        else
            _LineAlpha(dst,x1,y1,x2,y2,color,alpha);
        return;
    }

    float alpha_pp = float(alpha)/255;  /* Used to calculate alpha level if alpha != 255 */

    Uint32 intshift    = 32 - AAbits;   /* # of bits by which to shift erracc to get intensity level */

    /* Draw the initial pixel in the foreground color */
    if (alpha==SDL_ALPHA_OPAQUE)
        _SetPixel(dst,x1,y1, color);
    else
        _PutPixelAlpha(dst,x1,y1, color, alpha);

    /* x-major or y-major? */
    if (dy > dx)
    {

        /* y-major.  Calculate 16-bit fixed point fractional part of a pixel that
        X advances every time Y advances 1 pixel, truncating the result so that
        we won't overrun the endpoint along the X axis */
        erradj = ((dx << 16) / dy)<<16;

        /* draw all pixels other than the first and last */
        x0pxdir=xx0+xdir;
        while (--dy)
        {
            erracctmp = erracc;
            erracc += erradj;
            if (erracc <= erracctmp)
            {
                /* rollover in error accumulator, x coord advances */
                xx0=x0pxdir;
                x0pxdir += xdir;
            }
            yy0++;			/* y-major so always advance Y */

            /* the AAbits most significant bits of erracc give us the intensity
            weighting for this pixel, and the complement of the weighting for
            the paired pixel. */
            wgt = (erracc >> intshift) & 255;

            a = Uint8(255-wgt);
            if (alpha != SDL_ALPHA_OPAQUE)
                a = Uint8(a*alpha_pp);

            _PutPixelAlpha(dst,xx0,yy0,color,a);

            a = Uint8(wgt);
            if (alpha != SDL_ALPHA_OPAQUE)
                a = Uint8(a*alpha_pp);

            _PutPixelAlpha(dst,x0pxdir,yy0,color,a);
        }
    }
    else
    {

        /* x-major line.  Calculate 16-bit fixed-point fractional part of a pixel
        that Y advances each time X advances 1 pixel, truncating the result so
        that we won't overrun the endpoint along the X axis. */
        erradj = ((dy << 16) / dx)<<16;

        /* draw all pixels other than the first and last */
        y0p1=yy0+1;
        while (--dx)
        {

            erracctmp = erracc;
            erracc += erradj;
            if (erracc <= erracctmp)
            {
                /* Accumulator turned over, advance y */
                yy0=y0p1;
                y0p1++;
            }
            xx0 += xdir;  /* x-major so always advance X */

            /* the AAbits most significant bits of erracc give us the intensity
            weighting for this pixel, and the complement of the weighting for
            the paired pixel. */
            wgt = (erracc >> intshift) & 255;

            a = Uint8(255-wgt);
            if (alpha != SDL_ALPHA_OPAQUE)
                a = Uint8(a*alpha_pp);

            _PutPixelAlpha(dst,xx0,yy0,color,a);

            a = Uint8(wgt);
            if (alpha != SDL_ALPHA_OPAQUE)
                a = Uint8(a*alpha_pp);

            _PutPixelAlpha(dst,xx0,y0p1,color,a);
        }
    }

    /* Draw final pixel, always exactly intersected by the line and doesn't
    need to be weighted. */
    if (alpha==SDL_ALPHA_OPAQUE)
        _SetPixel(dst,x2,y2, color);
    else
        _PutPixelAlpha(dst,x2,y2, color, alpha);

}

void SPG_LineAABlend(SDL_Surface *dst, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color, Uint8 alpha)
{
    /* Lock surface */
    if ( SDL_MUSTLOCK(dst) && _SPG_lock )
        if ( SDL_LockSurface(dst) < 0 )
            return;

    _AALineAlpha(dst,x1,y1,x2,y2,color, alpha);

    /* unlock the display */
    if (SDL_MUSTLOCK(dst) && _SPG_lock)
    {
        SDL_UnlockSurface(dst);
    }

}



//==================================================================================
// Draws a multicolored line
//==================================================================================
void SPG_LineMultiFn(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint32 color2, void Callback(SDL_Surface *Surf, Sint16 X, Sint16 Y, Uint32 Color))
{
    Sint16 dx, dy, sdx, sdy, x, y, px, py;

    dx = x2 - x1;
    dy = y2 - y1;

    sdx = (dx < 0) ? -1 : 1;
    sdy = (dy < 0) ? -1 : 1;

    dx = sdx * dx + 1;
    dy = sdy * dy + 1;

    x = y = 0;

    px = x1;
    py = y1;

    Uint8 r1 = (color1 & surface->format->Rmask);
    Uint8 g1 = (color1 & surface->format->Gmask);
    Uint8 b1 = (color1 & surface->format->Bmask);
    Uint8 r2 = (color2 & surface->format->Rmask);
    Uint8 g2 = (color2 & surface->format->Gmask);
    Uint8 b2 = (color2 & surface->format->Bmask);

    /* We use fixedpoint math for the color fading */
    Sint32 R = r1<<16;
    Sint32 G = g1<<16;
    Sint32 B = b1<<16;
    Sint32 rstep;
    Sint32 gstep;
    Sint32 bstep;

    if (dx >= dy)
    {
        rstep = Sint32((r2-r1)<<16) / Sint32(dx);
        gstep = Sint32((g2-g1)<<16) / Sint32(dx);
        bstep = Sint32((b2-b1)<<16) / Sint32(dx);

        for (x = 0; x < dx; x++)
        {
            Callback(surface, px, py, SDL_MapRGB(surface->format, Uint8(R>>16), Uint8(G>>16), Uint8(B>>16)) );

            y += dy;
            if (y >= dx)
            {
                y -= dx;
                py += sdy;
            }
            px += sdx;

            R += rstep;
            G += gstep;
            B += bstep;
        }
    }
    else
    {
        rstep = Sint32((r2-r1)<<16) / Sint32(dy);
        gstep = Sint32((g2-g1)<<16) / Sint32(dy);
        bstep = Sint32((b2-b1)<<16) / Sint32(dy);

        for (y = 0; y < dy; y++)
        {
            Callback(surface, px, py, SDL_MapRGB(surface->format, Uint8(R>>16), Uint8(G>>16), Uint8(B>>16)) );

            x += dx;
            if (x >= dy)
            {
                x -= dy;
                px += sdx;
            }
            py += sdy;

            R += rstep;
            G += gstep;
            B += bstep;
        }
    }
}

void SPG_LineMulti(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint32 color2)
{
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        if (SDL_LockSurface(Surface) < 0)
            return;
    }

    /* Draw the line */
    SPG_LineMultiFn(Surface, x1,y1, x2,y2, color1, color2, _SetPixel);

    /* unlock the display */
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }

}

void SPG_LineMultiBlend(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint8 alpha1, Uint32 color2, Uint8 alpha2)
{
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
        if (SDL_LockSurface(Surface) < 0)
            return;

    _SPG_alpha_hack = alpha1;

    /* Draw the line */
    SPG_LineMultiFn(Surface, x1,y1, x2,y2, color1, color2, callback_alpha_hack);

    /* unlock the display */
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }

}


//==================================================================================
// Draws a anti-aliased multicolored line
//==================================================================================
void _AAmcLineAlpha(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint8 alpha1, Uint32 color2, Uint8 alpha2)
{
    Uint8 r1 = (color1 & surface->format->Rmask);
    Uint8 g1 = (color1 & surface->format->Gmask);
    Uint8 b1 = (color1 & surface->format->Bmask);

    Uint8 r2 = (color2 & surface->format->Rmask);
    Uint8 g2 = (color2 & surface->format->Gmask);
    Uint8 b2 = (color2 & surface->format->Bmask);

    Uint32 erracc=0, erradj;
    Uint32 erracctmp, wgt;
    Sint16 tmp, y0p1, x0pxdir;
    Uint8 a;

    /* Keep on working with 32bit numbers */
    Sint32 xx0=x1;
    Sint32 yy0=y1;
    Sint32 xx1=x2;
    Sint32 yy1=y2;

    /* Reorder points if required */
    if (yy0 > yy1)
    {
        SWAP(yy0, yy1, tmp);
        SWAP(xx0, xx1, tmp);

        SWAP(r1, r2, a);
        SWAP(g1, g2, a);
        SWAP(b1, b2, a);
    }

    /* Calculate distance */
    Sint16 dx = xx1 - xx0;
    Sint16 dy = yy1 - yy0;

    /* Adjust for negative dx and set xdir */
    Sint16 xdir=1;
    if (dx < 0)
    {
        xdir=-1;
        dx=(-dx);
    }

    /* Check for special cases */
    if (dx==0 || dy==0  || dx==dy)
    {
        SPG_LineMultiBlend(surface, x1, y1, x2, y2, color1, alpha1, color2, alpha2);
        return;
    }

    /* We use fixedpoint math for the color fading */
    Sint32 R = r1<<16;
    Sint32 G = g1<<16;
    Sint32 B = b1<<16;
    Sint32 rstep;
    Sint32 gstep;
    Sint32 bstep;

    // CHANGE
    int alpha = alpha1;
    float alpha_pp = float(alpha)/255;  /* Used to calculate alpha level if alpha != 255 */
    Uint32 intshift    = 32 - AAbits;   /* # of bits by which to shift erracc to get intensity level */

    if (alpha1==SDL_ALPHA_OPAQUE)
        _SetPixel(surface,x1,y1, SDL_MapRGB(surface->format, r1, g1, b1) );  /* Draw the initial pixel in the foreground color */
    else
        _PutPixelAlpha(surface,x1,y1, SDL_MapRGB(surface->format, r1, g1, b1), alpha);

    /* x-major or y-major? */
    if (dy > dx)
    {

        /* y-major.  Calculate 16-bit fixed point fractional part of a pixel that
        X advances every time Y advances 1 pixel, truncating the result so that
        we won't overrun the endpoint along the X axis */
        erradj = ((dx << 16) / dy)<<16;

        rstep = Sint32((r2-r1)<<16) / Sint32(dy);
        gstep = Sint32((g2-g1)<<16) / Sint32(dy);
        bstep = Sint32((b2-b1)<<16) / Sint32(dy);

        /* draw all pixels other than the first and last */
        x0pxdir=xx0+xdir;
        while (--dy)
        {
            R += rstep;
            G += gstep;
            B += bstep;

            erracctmp = erracc;
            erracc += erradj;
            if (erracc <= erracctmp)
            {
                /* rollover in error accumulator, x coord advances */
                xx0=x0pxdir;
                x0pxdir += xdir;
            }
            yy0++;			/* y-major so always advance Y */

            /* the AAbits most significant bits of erracc give us the intensity
            weighting for this pixel, and the complement of the weighting for
            the paired pixel. */
            wgt = (erracc >> intshift) & 255;

            a = Uint8(255-wgt);
            if (alpha != 255)
                a = Uint8(a*alpha_pp);

            _PutPixelAlpha(surface,xx0,yy0,SDL_MapRGB(surface->format, Uint8(R>>16), Uint8(G>>16), Uint8(B>>16)),a);

            a = Uint8(wgt);
            if (alpha != 255)
                a = Uint8(a*alpha_pp);

            _PutPixelAlpha(surface,x0pxdir,yy0,SDL_MapRGB(surface->format, Uint8(R>>16), Uint8(G>>16), Uint8(B>>16)),a);
        }
    }
    else
    {

        /* x-major line.  Calculate 16-bit fixed-point fractional part of a pixel
        that Y advances each time X advances 1 pixel, truncating the result so
        that we won't overrun the endpoint along the X axis. */
        erradj = ((dy << 16) / dx)<<16;

        rstep = Sint32((r2-r1)<<16) / Sint32(dx);
        gstep = Sint32((g2-g1)<<16) / Sint32(dx);
        bstep = Sint32((b2-b1)<<16) / Sint32(dx);

        /* draw all pixels other than the first and last */
        y0p1=yy0+1;
        while (--dx)
        {
            R += rstep;
            G += gstep;
            B += bstep;

            erracctmp = erracc;
            erracc += erradj;
            if (erracc <= erracctmp)
            {
                /* Accumulator turned over, advance y */
                yy0=y0p1;
                y0p1++;
            }
            xx0 += xdir;  /* x-major so always advance X */

            /* the AAbits most significant bits of erracc give us the intensity
            weighting for this pixel, and the complement of the weighting for
            the paired pixel. */
            wgt = (erracc >> intshift) & 255;

            a = Uint8(255-wgt);
            if (alpha != 255)
                a = Uint8(a*alpha_pp);

            _PutPixelAlpha(surface,xx0,yy0,SDL_MapRGB(surface->format, Uint8(R>>16), Uint8(G>>16), Uint8(B>>16)),a);

            a = Uint8(wgt);
            if (alpha != 255)
                a = Uint8(a*alpha_pp);

            _PutPixelAlpha(surface,xx0,y0p1,SDL_MapRGB(surface->format, Uint8(R>>16), Uint8(G>>16), Uint8(B>>16)),a);
        }
    }

    /* Draw final pixel, always exactly intersected by the line and doesn't
    need to be weighted. */
    if (alpha==SDL_ALPHA_OPAQUE)
        _SetPixel(surface,x2,y2, SDL_MapRGB(surface->format,r2, g2, b2));
    else
        _PutPixelAlpha(surface,x2,y2, SDL_MapRGB(surface->format,r2, g2, b2), alpha);

}

void SPG_LineMultiAABlend(SDL_Surface *dst, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color1, Uint8 alpha1, Uint32 color2, Uint8 alpha2)
{
    if ( SDL_MUSTLOCK(dst) && _SPG_lock )
        if ( SDL_LockSurface(dst) < 0 )
            return;

    _AAmcLineAlpha(dst, x1, y1, x2, y2, color1, alpha1, color2, alpha2);

    if (SDL_MUSTLOCK(dst) && _SPG_lock)
        SDL_UnlockSurface(dst);

}




/**********************************************************************************/
/**                           Figure functions                                   **/
/**********************************************************************************/

//==================================================================================
// Draws a rectangle
//==================================================================================
void SPG_Rect(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color)
{
    _HLine(Surface,x1,x2,y1,color);
    _HLine(Surface,x1,x2,y2,color);
    _VLine(Surface,x1,y1,y2,color);
    _VLine(Surface,x2,y1,y2,color);
}



//==================================================================================
// Draws a rectangle (alpha)
//==================================================================================
void SPG_RectBlend(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color, Uint8 alpha)
{
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
        if (SDL_LockSurface(Surface) < 0)
            return;

    _HLineAlpha(Surface,x1,x2,y1,color,alpha);
    _HLineAlpha(Surface,x1,x2,y2,color,alpha);
    _VLineAlpha(Surface,x1,y1,y2,color,alpha);
    _VLineAlpha(Surface,x2,y1,y2,color,alpha);

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }
}



//==================================================================================
// Draws a filled rectangle
//==================================================================================
void SPG_RectFilled(SDL_Surface *Surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color)
{
    Sint16 tmp;
    if (x1>x2)
    {
        tmp=x1;
        x1=x2;
        x2=tmp;
    }
    if (y1>y2)
    {
        tmp=y1;
        y1=y2;
        y2=tmp;
    }

#if SDL_VERSIONNUM(SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_PATCHLEVEL) < \
    SDL_VERSIONNUM(1, 1, 5)
    if (x2<Surface->clip_minx || x1>Surface->clip_maxx || y2<Surface->clip_miny || y1>Surface->clip_maxy)
        return;
    if (x1 < Surface->clip_minx)
        x1=Surface->clip_minx;
    if (x2 > Surface->clip_maxx)
        x2=Surface->clip_maxx;
    if (y1 < Surface->clip_miny)
        y1=Surface->clip_miny;
    if (y2 > Surface->clip_maxy)
        y2=Surface->clip_maxy;
#endif

    SDL_Rect area;
    area.x=x1;
    area.y=y1;
    area.w=x2-x1+1;
    area.h=y2-y1+1;

    SDL_FillRect(Surface,&area,color);

}



//==================================================================================
// Draws a filled rectangle (alpha)
//==================================================================================
void SPG_RectFilledBlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 color, Uint8 alpha)
{

    if ( alpha == SDL_ALPHA_OPAQUE )
    {
        SPG_RectFilled(surface,x1,y1,x2,y2,color);
        return;
    }

    /* Fix coords */
    Sint16 tmp;
    if (x1>x2)
    {
        tmp=x1;
        x1=x2;
        x2=tmp;
    }
    if (y1>y2)
    {
        tmp=y1;
        y1=y2;
        y2=tmp;
    }

    /* Clipping */
    if (x2<SPG_clip_xmin(surface) || x1>SPG_clip_xmax(surface) || y2<SPG_clip_ymin(surface) || y1>SPG_clip_ymax(surface))
        return;
    if (x1 < SPG_clip_xmin(surface))
        x1 = SPG_clip_xmin(surface);
    if (x2 > SPG_clip_xmax(surface))
        x2 = SPG_clip_xmax(surface);
    if (y1 < SPG_clip_ymin(surface))
        y1 = SPG_clip_ymin(surface);
    if (y2 > SPG_clip_ymax(surface))
        y2 = SPG_clip_ymax(surface);

    Uint32 Rmask = surface->format->Rmask, Gmask = surface->format->Gmask, Bmask = surface->format->Bmask, Amask = surface->format->Amask;
    Uint32 R,G,B,A=0;
    Sint16 x,y;




    if (SDL_MUSTLOCK(surface) && _SPG_lock)
        if (SDL_LockSurface(surface) < 0)
            return;

    switch (surface->format->BytesPerPixel)
    {
    case 1:   /* Assuming 8-bpp */
    {
        Uint8 *row, *pixel;
        Uint8 dR, dG, dB;

        Uint8 sR = surface->format->palette->colors[color].r;
        Uint8 sG = surface->format->palette->colors[color].g;
        Uint8 sB = surface->format->palette->colors[color].b;

        for (y = y1; y<=y2; y++)
        {
            row = (Uint8 *)surface->pixels + y*surface->pitch;
            for (x = x1; x <= x2; x++)
            {
                pixel = row + x;

                dR = surface->format->palette->colors[*pixel].r;
                dG = surface->format->palette->colors[*pixel].g;
                dB = surface->format->palette->colors[*pixel].b;

                dR = dR + ((sR-dR)*alpha >> 8);
                dG = dG + ((sG-dG)*alpha >> 8);
                dB = dB + ((sB-dB)*alpha >> 8);

                *pixel = SDL_MapRGB(surface->format, dR, dG, dB);
            }
        }
    }
    break;

    case 2:   /* Probably 15-bpp or 16-bpp */
    {
        Uint16 *row, *pixel;
        Uint32 dR=(color & Rmask),dG=(color & Gmask),dB=(color & Bmask),dA=(color & Amask);

        for (y = y1; y<=y2; y++)
        {
            row = (Uint16 *)surface->pixels + y*surface->pitch/2;
            for (x = x1; x <= x2; x++)
            {
                pixel = row + x;

                R = ((*pixel & Rmask) + (( dR - (*pixel & Rmask) ) * alpha >> 8)) & Rmask;
                G = ((*pixel & Gmask) + (( dG - (*pixel & Gmask) ) * alpha >> 8)) & Gmask;
                B = ((*pixel & Bmask) + (( dB - (*pixel & Bmask) ) * alpha >> 8)) & Bmask;
                if ( Amask )
                    A = ((*pixel & Amask) + (( dA - (*pixel & Amask) ) * alpha >> 8)) & Amask;

                *pixel= SDL_MapRGBA(surface->format, R, G, B, A);
            }
        }
    }
    break;

    case 3:   /* Slow 24-bpp mode, usually not used */
    {
        Uint8 *row,*pix;
        Uint8 dR, dG, dB, dA;
        Uint8 rshift8=surface->format->Rshift/8;
        Uint8 gshift8=surface->format->Gshift/8;
        Uint8 bshift8=surface->format->Bshift/8;
        Uint8 ashift8=surface->format->Ashift/8;

        Uint8 sR = (color>>surface->format->Rshift)&0xff;
        Uint8 sG = (color>>surface->format->Gshift)&0xff;
        Uint8 sB = (color>>surface->format->Bshift)&0xff;
        Uint8 sA = (color>>surface->format->Ashift)&0xff;

        for (y = y1; y<=y2; y++)
        {
            row = (Uint8 *)surface->pixels + y * surface->pitch;
            for (x = x1; x <= x2; x++)
            {
                pix = row + x*3;

                dR = *((pix)+rshift8);
                dG = *((pix)+gshift8);
                dB = *((pix)+bshift8);
                dA = *((pix)+ashift8);

                dR = dR + ((sR-dR)*alpha >> 8);
                dG = dG + ((sG-dG)*alpha >> 8);
                dB = dB + ((sB-dB)*alpha >> 8);
                dA = dA + ((sA-dA)*alpha >> 8);

                *((pix)+rshift8) = dR;
                *((pix)+gshift8) = dG;
                *((pix)+bshift8) = dB;
                *((pix)+ashift8) = dA;
            }
        }

    }
    break;

    case 4:   /* Probably 32-bpp */
    {
        Uint32 *row, *pixel;
        Uint32 dR=(color & Rmask),dG=(color & Gmask),dB=(color & Bmask),dA=(color & Amask);

        switch (_SPG_draw_state[0])
        {
        case SPG_COMBINE_ALPHA:  // Blend and combine src and dest alpha, SLOW IMPLEMENTATION
            dA=((alpha << surface->format->Ashift) & Amask);  // correct
            for (y = y1; y<=y2; y++)
            {
                row = (Uint32 *)surface->pixels + y*surface->pitch/4;
                for (x = x1; x <= x2; x++)
                {
                    pixel = row + x;

                    R = ((*pixel & Rmask) + (( dR - (*pixel & Rmask) ) * alpha >> 8)) & Rmask;
                    G = ((*pixel & Gmask) + (( dG - (*pixel & Gmask) ) * alpha >> 8)) & Gmask;
                    B = ((*pixel & Bmask) + (( dB - (*pixel & Bmask) ) * alpha >> 8)) & Bmask;
                    if ( Amask )
                        A = ((((*pixel & Amask) >> surface->format->Ashift) + alpha) >> 1) << surface->format->Ashift;

                    *pixel= R | G | B | A;
                }
            }
            break;
        case SPG_DEST_ALPHA:  // Blend and keep dest alpha
            for (y = y1; y<=y2; y++)
            {
                row = (Uint32 *)surface->pixels + y*surface->pitch/4;
                for (x = x1; x <= x2; x++)
                {
                    pixel = row + x;

                    R = ((*pixel & Rmask) + (( dR - (*pixel & Rmask) ) * alpha >> 8)) & Rmask;
                    G = ((*pixel & Gmask) + (( dG - (*pixel & Gmask) ) * alpha >> 8)) & Gmask;
                    B = ((*pixel & Bmask) + (( dB - (*pixel & Bmask) ) * alpha >> 8)) & Bmask;
                    if ( Amask )
                        A = (*pixel & Amask);


                    *pixel= R | G | B | A;
                }
            }

            break;
        case SPG_SRC_ALPHA:  // Blend and keep src alpha
            if (Amask)
                A = (alpha << surface->format->Ashift);
            else
                A = SDL_ALPHA_OPAQUE;
            for (y = y1; y<=y2; y++)
            {
                row = (Uint32 *)surface->pixels + y*surface->pitch/4;
                for (x = x1; x <= x2; x++)
                {
                    pixel = row + x;

                    R = ((*pixel & Rmask) + (( dR - (*pixel & Rmask) ) * alpha >> 8)) & Rmask;
                    G = ((*pixel & Gmask) + (( dG - (*pixel & Gmask) ) * alpha >> 8)) & Gmask;
                    B = ((*pixel & Bmask) + (( dB - (*pixel & Bmask) ) * alpha >> 8)) & Bmask;

                    *pixel= R | G | B | A;  // A is src alpha here
                }
            }

            break;
        case SPG_COPY_SRC_ALPHA: // Direct copy with src alpha
            if (Amask)
                A = (alpha << surface->format->Ashift);
            else
                A = SDL_ALPHA_OPAQUE;
            for (y = y1; y<=y2; y++)
            {
                row = (Uint32 *)surface->pixels + y*surface->pitch/4;
                for (x = x1; x <= x2; x++)
                {
                    pixel = row + x;

                    *pixel= dR | dG | dB | A;  // A is src alpha here
                }
            }
            break;
        case SPG_COPY_DEST_ALPHA: // Direct copy with dest alpha
            for (y = y1; y<=y2; y++)
            {
                row = (Uint32 *)surface->pixels + y*surface->pitch/4;
                for (x = x1; x <= x2; x++)
                {
                    pixel = row + x;

                    *pixel= dR | dG | dB | (*pixel & Amask);
                }
            }
            break;
        case SPG_COPY_COMBINE_ALPHA: // Direct copy with combined alpha
            for (y = y1; y<=y2; y++)
            {
                row = (Uint32 *)surface->pixels + y*surface->pitch/4;
                for (x = x1; x <= x2; x++)
                {
                    pixel = row + x;
                    if (Amask)
                        A = ((((*pixel & Amask) >> surface->format->Ashift) + alpha) >> 1) << surface->format->Ashift;

                    *pixel= dR | dG | dB | A;
                }
            }
            break;
        case SPG_COPY_NO_ALPHA:  // Direct copy, alpha opaque
            SPG_RectFilled(surface,x1,y1,x2,y2,color);
            break;
        case SPG_COPY_ALPHA_ONLY:  // Direct copy of just the alpha
            for (y = y1; y<=y2; y++)
            {
                row = (Uint32 *)surface->pixels + y*surface->pitch/4;
                for (x = x1; x <= x2; x++)
                {
                    pixel = row + x;
                    R = *pixel & Rmask;
                    G = *pixel & Gmask;
                    B = *pixel & Bmask;
                    if(Amask)
                        A = (alpha << surface->format->Ashift);
                    
                    *pixel= dR | dG | dB | A;
                }
            }
            break;
        case SPG_COMBINE_ALPHA_ONLY:  // Blend of just the alpha
            for (y = y1; y<=y2; y++)
            {
                row = (Uint32 *)surface->pixels + y*surface->pitch/4;
                for (x = x1; x <= x2; x++)
                {
                    pixel = row + x;
                    R = *pixel & Rmask;
                    G = *pixel & Gmask;
                    B = *pixel & Bmask;
                    if(Amask)
                        A = ((((*pixel & Amask) >> surface->format->Ashift) + alpha) >> 1) << surface->format->Ashift;
                    
                    *pixel= dR | dG | dB | A;
                }
            }
            break;
        }


    }
    break;
    }

    if (SDL_MUSTLOCK(surface) && _SPG_lock)
    {
        SDL_UnlockSurface(surface);
    }

}





//==================================================================================
// Performs Callback at each ellipse point.
// (from Allegro)
//==================================================================================
void SPG_EllipseFn(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color, void Callback(SDL_Surface *Surf, Sint16 X, Sint16 Y, Uint32 Color) )
{
    int ix, iy;
    int h, i, j, k;
    int oh, oi, oj, ok;

    if (rx < 1)
        rx = 1;

    if (ry < 1)
        ry = 1;

    h = i = j = k = 0xFFFF;

    if (rx > ry)
    {
        ix = 0;
        iy = rx * 64;

        do
        {
            oh = h;
            oi = i;
            oj = j;
            ok = k;

            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * ry) / rx;
            k = (i * ry) / rx;

            if (((h != oh) || (k != ok)) && (h < oi))
            {
                Callback(Surface, x+h, y+k, color);
                if (h)
                    Callback(Surface, x-h, y+k, color);
                if (k)
                {
                    Callback(Surface, x+h, y-k, color);
                    if (h)
                        Callback(Surface, x-h, y-k, color);
                }
            }

            if (((i != oi) || (j != oj)) && (h < i))
            {
                Callback(Surface, x+i, y+j, color);
                if (i)
                    Callback(Surface, x-i, y+j, color);
                if (j)
                {
                    Callback(Surface, x+i, y-j, color);
                    if (i)
                        Callback(Surface, x-i, y-j, color);
                }
            }

            ix = ix + iy / rx;
            iy = iy - ix / rx;

        }
        while (i > h);
    }
    else
    {
        ix = 0;
        iy = ry * 64;

        do
        {
            oh = h;
            oi = i;
            oj = j;
            ok = k;

            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * rx) / ry;
            k = (i * rx) / ry;

            if (((j != oj) || (i != oi)) && (h < i))
            {
                Callback(Surface, x+j, y+i, color);
                if (j)
                    Callback(Surface, x-j, y+i, color);
                if (i)
                {
                    Callback(Surface, x+j, y-i, color);
                    if (j)
                        Callback(Surface, x-j, y-i, color);
                }
            }

            if (((k != ok) || (h != oh)) && (h < oi))
            {
                Callback(Surface, x+k, y+h, color);
                if (k)
                    Callback(Surface, x-k, y+h, color);
                if (h)
                {
                    Callback(Surface, x+k, y-h, color);
                    if (k)
                        Callback(Surface, x-k, y-h, color);
                }
            }

            ix = ix + iy / ry;
            iy = iy - ix / ry;

        }
        while (i > h);
    }
}




//==================================================================================
// Draws an ellipse
//==================================================================================
void SPG_Ellipse(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color)
{
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        if (SDL_LockSurface(Surface) < 0)
            return;
    }

    SPG_EllipseFn(Surface, x, y, rx, ry, color, _SetPixel);

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }


}




//==================================================================================
// Draws an ellipse (alpha)
//==================================================================================
void SPG_EllipseBlend(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color, Uint8 alpha)
{
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
        if (SDL_LockSurface(Surface) < 0)
            return;

    _SPG_alpha_hack = alpha;
    SPG_EllipseFn(Surface, x, y, rx, ry, color, callback_alpha_hack);

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }
}




//==================================================================================
// Draws a filled ellipse
//==================================================================================
void SPG_EllipseFilled(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color)
{
    int ix, iy;
    int h, i, j, k;
    int oh, oi, oj, ok;

    if (rx < 1)
        rx = 1;

    if (ry < 1)
        ry = 1;

    oh = oi = oj = ok = 0xFFFF;

    if (rx > ry)
    {
        ix = 0;
        iy = rx * 64;

        do
        {
            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * ry) / rx;
            k = (i * ry) / rx;

            if ((k!=ok) && (k!=oj))
            {
                if (k)
                {
                    _HLine(Surface,x-h,x+h,y-k,color);
                    _HLine(Surface,x-h,x+h,y+k,color);
                }
                else
                    _HLine(Surface,x-h,x+h,y,color);
                ok=k;
            }

            if ((j!=oj) && (j!=ok) && (k!=j))
            {
                if (j)
                {
                    _HLine(Surface,x-i,x+i,y-j,color);
                    _HLine(Surface,x-i,x+i,y+j,color);
                }
                else
                    _HLine(Surface,x-i,x+i,y,color);
                oj=j;
            }

            ix = ix + iy / rx;
            iy = iy - ix / rx;

        }
        while (i > h);
    }
    else
    {
        ix = 0;
        iy = ry * 64;

        do
        {
            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * rx) / ry;
            k = (i * rx) / ry;

            if ((i!=oi) && (i!=oh))
            {
                if (i)
                {
                    _HLine(Surface,x-j,x+j,y-i,color);
                    _HLine(Surface,x-j,x+j,y+i,color);
                }
                else
                    _HLine(Surface,x-j,x+j,y,color);
                oi=i;
            }

            if ((h!=oh) && (h!=oi) && (i!=h))
            {
                if (h)
                {
                    _HLine(Surface,x-k,x+k,y-h,color);
                    _HLine(Surface,x-k,x+k,y+h,color);
                }
                else
                    _HLine(Surface,x-k,x+k,y,color);
                oh=h;
            }

            ix = ix + iy / ry;
            iy = iy - ix / ry;

        }
        while (i > h);
    }

}





//==================================================================================
// Draws a filled ellipse (alpha)
//==================================================================================
void SPG_EllipseFilledBlend(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color, Uint8 alpha)
{
    int ix, iy;
    int h, i, j, k;
    int oh, oi, oj, ok;

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
        if (SDL_LockSurface(Surface) < 0)
            return;

    if (rx < 1)
        rx = 1;

    if (ry < 1)
        ry = 1;

    oh = oi = oj = ok = 0xFFFF;

    if (rx > ry)
    {
        ix = 0;
        iy = rx * 64;

        do
        {
            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * ry) / rx;
            k = (i * ry) / rx;

            if ((k!=ok) && (k!=oj))
            {
                if (k)
                {
                    _HLineAlpha(Surface,x-h,x+h,y-k,color, alpha);
                    _HLineAlpha(Surface,x-h,x+h,y+k,color, alpha);
                }
                else
                    _HLineAlpha(Surface,x-h,x+h,y,color, alpha);
                ok=k;
            }

            if ((j!=oj) && (j!=ok) && (k!=j))
            {
                if (j)
                {
                    _HLineAlpha(Surface,x-i,x+i,y-j,color, alpha);
                    _HLineAlpha(Surface,x-i,x+i,y+j,color, alpha);
                }
                else
                    _HLineAlpha(Surface,x-i,x+i,y,color, alpha);
                oj=j;
            }

            ix = ix + iy / rx;
            iy = iy - ix / rx;

        }
        while (i > h);
    }
    else
    {
        ix = 0;
        iy = ry * 64;

        do
        {
            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * rx) / ry;
            k = (i * rx) / ry;

            if ((i!=oi) && (i!=oh))
            {
                if (i)
                {
                    _HLineAlpha(Surface,x-j,x+j,y-i,color, alpha);
                    _HLineAlpha(Surface,x-j,x+j,y+i,color, alpha);
                }
                else
                    _HLineAlpha(Surface,x-j,x+j,y,color, alpha);
                oi=i;
            }

            if ((h!=oh) && (h!=oi) && (i!=h))
            {
                if (h)
                {
                    _HLineAlpha(Surface,x-k,x+k,y-h,color, alpha);
                    _HLineAlpha(Surface,x-k,x+k,y+h,color, alpha);
                }
                else
                    _HLineAlpha(Surface,x-k,x+k,y,color, alpha);
                oh=h;
            }

            ix = ix + iy / ry;
            iy = iy - ix / ry;

        }
        while (i > h);
    }

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }

}

void SPG_EllipseFilledAABlend(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 color, Uint8 alpha)
{
    int ix, iy;
    int h, i, j, k;
    int oh, oi, oj, ok;

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
        if (SDL_LockSurface(Surface) < 0)
            return;

    if (rx < 1)
        rx = 1;

    if (ry < 1)
        ry = 1;

    oh = oi = oj = ok = 0xFFFF;

    if (rx > ry)
    {
        ix = 0;
        iy = rx * 64;

        do
        {
            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * ry) / rx;
            k = (i * ry) / rx;

            if ((k!=ok) && (k!=oj))
            {
                if (k)
                {
                    _HLineAlpha(Surface,x-h,x+h,y-k,color, alpha);
                    _HLineAlpha(Surface,x-h,x+h,y+k,color, alpha);
                }
                else
                    _HLineAlpha(Surface,x-h,x+h,y,color, alpha);
                ok=k;
            }

            if ((j!=oj) && (j!=ok) && (k!=j))
            {
                if (j)
                {
                    _HLineAlpha(Surface,x-i,x+i,y-j,color, alpha);
                    _HLineAlpha(Surface,x-i,x+i,y+j,color, alpha);
                }
                else
                    _HLineAlpha(Surface,x-i,x+i,y,color, alpha);
                oj=j;
            }

            ix = ix + iy / rx;
            iy = iy - ix / rx;

        }
        while (i > h);
    }
    else
    {
        ix = 0;
        iy = ry * 64;

        do
        {
            h = (ix + 32) >> 6;
            i = (iy + 32) >> 6;
            j = (h * rx) / ry;
            k = (i * rx) / ry;

            if ((i!=oi) && (i!=oh))
            {
                if (i)
                {
                    _HLineAlpha(Surface,x-j,x+j,y-i,color, alpha);
                    _HLineAlpha(Surface,x-j,x+j,y+i,color, alpha);
                }
                else
                    _HLineAlpha(Surface,x-j,x+j,y,color, alpha);
                oi=i;
            }

            if ((h!=oh) && (h!=oi) && (i!=h))
            {
                if (h)
                {
                    _HLineAlpha(Surface,x-k,x+k,y-h,color, alpha);
                    _HLineAlpha(Surface,x-k,x+k,y+h,color, alpha);
                }
                else
                    _HLineAlpha(Surface,x-k,x+k,y,color, alpha);
                oh=h;
            }

            ix = ix + iy / ry;
            iy = iy - ix / ry;

        }
        while (i > h);
    }

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }

}



//==================================================================================
// Draws an anti-aliased ellipse (alpha)
// Some of this code is taken from "TwinLib" (http://www.twinlib.org) written by
// Nicolas Roard (nicolas@roard.com)
//==================================================================================
void SPG_EllipseAABlend(SDL_Surface *surface, Sint16 xc, Sint16 yc, Sint16 rx, Sint16 ry, Uint32 color, Uint8 alpha)
{
    /* Sanity check */
    if (rx < 1)
        rx = 1;
    if (ry < 1)
        ry = 1;

    int a2 = rx * rx;
    int b2 = ry * ry;

    int ds = 2 * a2;
    int dt = 2 * b2;

    int dxt = int (a2 / sqrt((double)(a2 + b2)));

    int t = 0;
    int s = -2 * a2 * ry;
    int d = 0;

    Sint16 x = xc;
    Sint16 y = yc - ry;

    Sint16 xs, ys, dyt;
    float cp, is, ip, imax = 1.0;

    Uint8 s_alpha, p_alpha;
    float alpha_pp = float(alpha)/255;

    /* Lock surface */
    if ( SDL_MUSTLOCK(surface) && _SPG_lock )
        if ( SDL_LockSurface(surface) < 0 )
            return;

    /* "End points" */
    _PutPixelAlpha(surface, x, y, color, alpha);
    _PutPixelAlpha(surface, 2*xc-x, y, color, alpha);

    _PutPixelAlpha(surface, x, 2*yc-y, color, alpha);
    _PutPixelAlpha(surface, 2*xc-x, 2*yc-y, color, alpha);

    int i;

    for (i = 1; i <= dxt; i++)
    {
        x--;
        d += t - b2;

        if (d >= 0)
            ys = y - 1;
        else if ((d - s - a2) > 0)
        {
            if ((2 * d - s - a2) >= 0)
                ys = y + 1;
            else
            {
                ys = y;
                y++;
                d -= s + a2;
                s += ds;
            }
        }
        else
        {
            y++;
            ys = y + 1;
            d -= s + a2;
            s += ds;
        }

        t -= dt;

        /* Calculate alpha */
        cp = float(abs(d)) / abs(s);
        is = float( cp * imax + 0.1 );
        ip = float( imax - is + 0.2 );

        /* Overflow check */
        if ( is > 1.0 )
            is = 1.0;
        if ( ip > 1.0 )
            ip = 1.0;

        /* Calculate alpha level */
        s_alpha = Uint8(is*255);
        p_alpha = Uint8(ip*255);
        if ( alpha != 255 )
        {
            s_alpha = Uint8(s_alpha*alpha_pp);
            p_alpha = Uint8(p_alpha*alpha_pp);
        }


        /* Upper half */
        _PutPixelAlpha(surface, x, y, color, p_alpha);
        _PutPixelAlpha(surface, 2*xc-x, y, color, p_alpha);

        _PutPixelAlpha(surface, x, ys, color, s_alpha);
        _PutPixelAlpha(surface, 2*xc-x, ys, color, s_alpha);


        /* Lower half */
        _PutPixelAlpha(surface, x, 2*yc-y, color, p_alpha);
        _PutPixelAlpha(surface, 2*xc-x, 2*yc-y, color, p_alpha);

        _PutPixelAlpha(surface, x, 2*yc-ys, color, s_alpha);
        _PutPixelAlpha(surface, 2*xc-x, 2*yc-ys, color, s_alpha);
    }

    dyt = abs(y - yc);

    for (i = 1; i <= dyt; i++)
    {
        y++;
        d -= s + a2;

        if (d <= 0)
            xs = x + 1;
        else if ((d + t - b2) < 0)
        {
            if ((2 * d + t - b2) <= 0)
                xs = x - 1;
            else
            {
                xs = x;
                x--;
                d += t - b2;
                t -= dt;
            }
        }
        else
        {
            x--;
            xs = x - 1;
            d += t - b2;
            t -= dt;
        }

        s += ds;

        /* Calculate alpha */
        cp = float(abs(d)) / abs(t);
        is = float( cp * imax + 0.1 );
        ip = float( imax - is + 0.2 );

        /* Overflow check */
        if ( is > 1.0 )
            is = 1.0;
        if ( ip > 1.0 )
            ip = 1.0;

        /* Calculate alpha level */
        s_alpha = Uint8(is*255);
        p_alpha = Uint8(ip*255);
        if ( alpha != 255 )
        {
            s_alpha = Uint8(s_alpha*alpha_pp);
            p_alpha = Uint8(p_alpha*alpha_pp);
        }


        /* Upper half */
        _PutPixelAlpha(surface, x, y, color, p_alpha);
        _PutPixelAlpha(surface, 2*xc-x, y, color, p_alpha);

        _PutPixelAlpha(surface, xs, y, color, s_alpha);
        _PutPixelAlpha(surface, 2*xc-xs, y, color, s_alpha);


        /* Lower half*/
        _PutPixelAlpha(surface, x, 2*yc-y, color, p_alpha);
        _PutPixelAlpha(surface, 2*xc-x, 2*yc-y, color, p_alpha);

        _PutPixelAlpha(surface, xs, 2*yc-y, color, s_alpha);
        _PutPixelAlpha(surface, 2*xc-xs, 2*yc-y, color, s_alpha);
    }

    /* unlock surface */
    if (SDL_MUSTLOCK(surface) && _SPG_lock)
    {
        SDL_UnlockSurface(surface);
    }

}







//==================================================================================
// Draws a filled anti-aliased ellipse
// This is just a quick hack...
//==================================================================================
void SPG_EllipseFilledAA(SDL_Surface *surface, Sint16 xc, Sint16 yc, Sint16 rx, Sint16 ry, Uint32 color)
{
    /* Sanity check */
    if (rx < 1)
        rx = 1;
    if (ry < 1)
        ry = 1;

    int a2 = rx * rx;
    int b2 = ry * ry;

    int ds = 2 * a2;
    int dt = 2 * b2;

    int dxt = int (a2 / sqrt((double)(a2 + b2)));

    int t = 0;
    int s = -2 * a2 * ry;
    int d = 0;

    Sint16 x = xc;
    Sint16 y = yc - ry;

    Sint16 xs, ys, dyt;
    float cp, is, ip, imax = 1.0;


    /* Lock surface */
    if ( SDL_MUSTLOCK(surface) && _SPG_lock )
        if ( SDL_LockSurface(surface) < 0 )
            return;

    /* "End points" */
    _SetPixel(surface, x, y, color);
    _SetPixel(surface, 2*xc-x, y, color);

    _SetPixel(surface, x, 2*yc-y, color);
    _SetPixel(surface, 2*xc-x, 2*yc-y, color);

    /* unlock surface */
    if (SDL_MUSTLOCK(surface) && _SPG_lock)
        SDL_UnlockSurface(surface);

    _VLine(surface, x, y+1, 2*yc-y-1, color);

    int i;

    for (i = 1; i <= dxt; i++)
    {
        x--;
        d += t - b2;

        if (d >= 0)
            ys = y - 1;
        else if ((d - s - a2) > 0)
        {
            if ((2 * d - s - a2) >= 0)
                ys = y + 1;
            else
            {
                ys = y;
                y++;
                d -= s + a2;
                s += ds;
            }
        }
        else
        {
            y++;
            ys = y + 1;
            d -= s + a2;
            s += ds;
        }

        t -= dt;

        /* Calculate alpha */
        cp = (float) abs(d) / abs(s);
        is = cp * imax;
        ip = imax - is;


        /* Lock surface */
        if ( SDL_MUSTLOCK(surface) && _SPG_lock )
            if ( SDL_LockSurface(surface) < 0 )
                return;

        /* Upper half */
        _PutPixelAlpha(surface, x, y, color, Uint8(ip*255));
        _PutPixelAlpha(surface, 2*xc-x, y, color, Uint8(ip*255));

        _PutPixelAlpha(surface, x, ys, color, Uint8(is*255));
        _PutPixelAlpha(surface, 2*xc-x, ys, color, Uint8(is*255));


        /* Lower half */
        _PutPixelAlpha(surface, x, 2*yc-y, color, Uint8(ip*255));
        _PutPixelAlpha(surface, 2*xc-x, 2*yc-y, color, Uint8(ip*255));

        _PutPixelAlpha(surface, x, 2*yc-ys, color, Uint8(is*255));
        _PutPixelAlpha(surface, 2*xc-x, 2*yc-ys, color, Uint8(is*255));

        /* unlock surface */
        if (SDL_MUSTLOCK(surface) && _SPG_lock)
            SDL_UnlockSurface(surface);


        /* Fill */
        _VLine(surface, x, y+1, 2*yc-y-1, color);
        _VLine(surface, 2*xc-x, y+1, 2*yc-y-1, color);
        _VLine(surface, x, ys+1, 2*yc-ys-1, color);
        _VLine(surface, 2*xc-x, ys+1, 2*yc-ys-1, color);
    }

    dyt = abs(y - yc);

    for (i = 1; i <= dyt; i++)
    {
        y++;
        d -= s + a2;

        if (d <= 0)
            xs = x + 1;
        else if ((d + t - b2) < 0)
        {
            if ((2 * d + t - b2) <= 0)
                xs = x - 1;
            else
            {
                xs = x;
                x--;
                d += t - b2;
                t -= dt;
            }
        }
        else
        {
            x--;
            xs = x - 1;
            d += t - b2;
            t -= dt;
        }

        s += ds;

        /* Calculate alpha */
        cp = (float) abs(d) / abs(t);
        is = cp * imax;
        ip = imax - is;


        /* Lock surface */
        if ( SDL_MUSTLOCK(surface) && _SPG_lock )
            if ( SDL_LockSurface(surface) < 0 )
                return;

        /* Upper half */
        _PutPixelAlpha(surface, x, y, color, Uint8(ip*255));
        _PutPixelAlpha(surface, 2*xc-x, y, color, Uint8(ip*255));

        _PutPixelAlpha(surface, xs, y, color, Uint8(is*255));
        _PutPixelAlpha(surface, 2*xc-xs, y, color, Uint8(is*255));


        /* Lower half*/
        _PutPixelAlpha(surface, x, 2*yc-y, color, Uint8(ip*255));
        _PutPixelAlpha(surface, 2*xc-x, 2*yc-y, color, Uint8(ip*255));

        _PutPixelAlpha(surface, xs, 2*yc-y, color, Uint8(is*255));
        _PutPixelAlpha(surface, 2*xc-xs, 2*yc-y, color, Uint8(is*255));

        /* unlock surface */
        if (SDL_MUSTLOCK(surface) && _SPG_lock)
            SDL_UnlockSurface(surface);

        /* Fill */
        _HLine(surface, x+1, 2*xc-x-1, y, color);
        _HLine(surface, xs+1, 2*xc-xs-1, y, color);
        _HLine(surface, x+1, 2*xc-x-1, 2*yc-y, color);
        _HLine(surface, xs+1, 2*xc-xs-1, 2*yc-y, color);
    }

}







//==================================================================================
// Performs Callback at each circle point.
//==================================================================================
void SPG_CircleFn(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color, void Callback(SDL_Surface *Surf, Sint16 X, Sint16 Y, Uint32 Color))
{
    Sint16 cx = 0;
    Sint16 cy = r;
    Sint16 df = 1 - r;
    Sint16 d_e = 3;
    Sint16 d_se = -2 * r + 5;

    do
    {
        Callback(Surface, x+cx, y+cy, color);
        Callback(Surface, x-cx, y+cy, color);
        Callback(Surface, x+cx, y-cy, color);
        Callback(Surface, x-cx, y-cy, color);
        Callback(Surface, x+cy, y+cx, color);
        Callback(Surface, x+cy, y-cx, color);
        Callback(Surface, x-cy, y+cx, color);
        Callback(Surface, x-cy, y-cx, color);

        if (df < 0)
        {
            df += d_e;
            d_e += 2;
            d_se += 2;
        }
        else
        {
            df += d_se;
            d_e += 2;
            d_se += 4;
            cy--;
        }

        cx++;

    }
    while (cx <= cy);

}




//==================================================================================
// Draws a circle
//==================================================================================
void SPG_Circle(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color)
{
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        if (SDL_LockSurface(Surface) < 0)
            return;
    }

    SPG_CircleFn(Surface, x, y, r, color, _SetPixel);

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }
}



//==================================================================================
// Draws a circle (alpha)
//==================================================================================
void SPG_CircleBlend(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color, Uint8 alpha)
{
    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
        if (SDL_LockSurface(Surface) < 0)
            return;

    _SPG_alpha_hack = alpha;
    SPG_CircleFn(Surface, x, y, r, color, callback_alpha_hack);

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }

}




//==================================================================================
// Draws a filled circle
//==================================================================================
void SPG_CircleFilled(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color)
{
    Sint16 cx = 0;
    Sint16 cy = r;
    bool draw=true;
    Sint16 df = 1 - r;
    Sint16 d_e = 3;
    Sint16 d_se = -2 * r + 5;

    do
    {
        if (draw)
        {
            _HLine(Surface,x-cx,x+cx,y+cy,color);
            _HLine(Surface,x-cx,x+cx,y-cy,color);
            draw=false;
        }
        if (cx!=cy)
        {
            if (cx)
            {
                _HLine(Surface,x-cy,x+cy,y-cx,color);
                _HLine(Surface,x-cy,x+cy,y+cx,color);
            }
            else
                _HLine(Surface,x-cy,x+cy,y,color);
        }

        if (df < 0)
        {
            df += d_e;
            d_e += 2;
            d_se += 2;
        }
        else
        {
            df += d_se;
            d_e += 2;
            d_se += 4;
            cy--;
            draw=true;
        }
        cx++;
    }
    while (cx <= cy);

}



//==================================================================================
// Draws a filled circle (alpha)
//==================================================================================
void SPG_CircleFilledBlend(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color, Uint8 alpha)
{
    Sint16 cx = 0;
    Sint16 cy = r;
    bool draw=true;
    Sint16 df = 1 - r;
    Sint16 d_e = 3;
    Sint16 d_se = -2 * r + 5;

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
        if (SDL_LockSurface(Surface) < 0)
            return;

    do
    {
        if (draw)
        {
            _HLineAlpha(Surface,x-cx,x+cx,y+cy,color, alpha);
            _HLineAlpha(Surface,x-cx,x+cx,y-cy,color, alpha);
            draw=false;
        }
        if (cx!=cy)
        {
            if (cx)
            {
                _HLineAlpha(Surface,x-cy,x+cy,y-cx,color, alpha);
                _HLineAlpha(Surface,x-cy,x+cy,y+cx,color, alpha);
            }
            else
                _HLineAlpha(Surface,x-cy,x+cy,y,color, alpha);
        }

        if (df < 0)
        {
            df += d_e;
            d_e += 2;
            d_se += 2;
        }
        else
        {
            df += d_se;
            d_e += 2;
            d_se += 4;
            cy--;
            draw=true;
        }
        cx++;
    }
    while (cx <= cy);

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }

}



void SPG_CircleFilledAABlend(SDL_Surface *Surface, Sint16 x, Sint16 y, Sint16 r, Uint32 color, Uint8 alpha)
{
    Sint16 cx = 0;
    Sint16 cy = r;
    bool draw=true;
    Sint16 df = 1 - r;
    Sint16 d_e = 3;
    Sint16 d_se = -2 * r + 5;

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
        if (SDL_LockSurface(Surface) < 0)
            return;

    do
    {
        if (draw)
        {
            _HLineAlpha(Surface,x-cx,x+cx,y+cy,color, alpha);
            _HLineAlpha(Surface,x-cx,x+cx,y-cy,color, alpha);
            draw=false;
        }
        if (cx!=cy)
        {
            if (cx)
            {
                _HLineAlpha(Surface,x-cy,x+cy,y-cx,color, alpha);
                _HLineAlpha(Surface,x-cy,x+cy,y+cx,color, alpha);
            }
            else
                _HLineAlpha(Surface,x-cy,x+cy,y,color, alpha);
        }

        if (df < 0)
        {
            df += d_e;
            d_e += 2;
            d_se += 2;
        }
        else
        {
            df += d_se;
            d_e += 2;
            d_se += 4;
            cy--;
            draw=true;
        }
        cx++;
    }
    while (cx <= cy);

    if (SDL_MUSTLOCK(Surface) && _SPG_lock)
    {
        SDL_UnlockSurface(Surface);
    }

}









//==================================================================================
// Draws a bezier line
//==================================================================================
/* Macro to do the line... 'function' is the line drawing routine */
#define DO_BEZIER(function)\
	/*
*  Note:
I don't think there is any great performance win in translating this to fixed-point integer math,
*  most of the time is spent in the line drawing routine.
*/\
float x = float(x1), y = float(y1);\
float xp = x, yp = y;\
float delta;\
float dx, d2x, d3x;\
float dy, d2y, d3y;\
float a, b, c;\
int i;\
int n = 1;\
Sint16 xmax=x1, ymax=y1, xmin=x1, ymin=y1;\
\
/* compute number of iterations */\
if(level < 1)\
level=1;\
if(level >= 15)\
level=15; \
while (level-- > 0)\
n*= 2;\
delta = float( 1.0 / float(n) );\
\
/* compute finite differences */\
/* a, b, c are the coefficient of the polynom in t defining the parametric curve */\
/* The computation is done independently for x and y */\
a = float(-x1 + 3*x2 - 3*x3 + x4);\
b = float(3*x1 - 6*x2 + 3*x3);\
c = float(-3*x1 + 3*x2);\
\
d3x = 6 * a * delta*delta*delta;\
d2x = d3x + 2 * b * delta*delta;\
dx = a * delta*delta*delta + b * delta*delta + c * delta;\
\
a = float(-y1 + 3*y2 - 3*y3 + y4);\
b = float(3*y1 - 6*y2 + 3*y3);\
c = float(-3*y1 + 3*y2);\
\
d3y = 6 * a * delta*delta*delta;\
d2y = d3y + 2 * b * delta*delta;\
dy = a * delta*delta*delta + b * delta*delta + c * delta;\
\
if (SDL_MUSTLOCK(surface) && _SPG_lock) {\
if (SDL_LockSurface(surface) < 0)\
return;\
}\
\
/* iterate */\
for (i = 0; i < n; i++) {\
x += dx; dx += d2x; d2x += d3x;\
y += dy; dy += d2y; d2y += d3y;\
if(Sint16(xp) != Sint16(x) || Sint16(yp) != Sint16(y)){\
function;\
}\
xp = x; yp = y;\
}\
\
/* unlock the display */\
if (SDL_MUSTLOCK(surface) && _SPG_lock) {\
SDL_UnlockSurface(surface);\
}\


//==================================================================================
// Draws a bezier line
//==================================================================================
void SPG_Bezier(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2,Sint16 x3, Sint16 y3, Sint16 x4, Sint16 y4, int level, Uint32 color)
{
DO_BEZIER(_Line(surface, Sint16(xp),Sint16(yp), Sint16(x),Sint16(y), color));
}

//==================================================================================
// Draws a bezier line (RGB)
//==================================================================================
void SPG_Bezier(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2,Sint16 x3, Sint16 y3, Sint16 x4, Sint16 y4, int level, Uint8 R, Uint8 G, Uint8 B)
{
SPG_Bezier(surface,x1,y1,x2,y2,x3,y3,x4,y4,level, SDL_MapRGB(surface->format,R,G,B));
}


//==================================================================================
// Draws a bezier line (alpha)
//==================================================================================
void SPG_BezierBlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2,Sint16 x3, Sint16 y3, Sint16 x4, Sint16 y4, int level, Uint32 color, Uint8 alpha)
{
_SPG_alpha_hack = alpha;

DO_BEZIER(SPG_LineFn(surface, Sint16(xp),Sint16(yp), Sint16(x),Sint16(y), color, callback_alpha_hack));
}


//==================================================================================
// Draws an AA bezier line (alpha)
//==================================================================================
void SPG_BezierAABlend(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2,Sint16 x3, Sint16 y3, Sint16 x4, Sint16 y4, int level, Uint32 color, Uint8 alpha)
{
Uint8 lock = _SPG_lock;
_SPG_lock = 0;

if (SDL_MUSTLOCK(surface) && lock)
if (SDL_LockSurface(surface) < 0)
return;

DO_BEZIER(SPG_LineAABlend(surface, Sint16(xp),Sint16(yp), Sint16(x),Sint16(y), color, alpha));

if (SDL_MUSTLOCK(surface) && lock) {
SDL_UnlockSurface(surface);
}
_SPG_lock = lock;
}


//==================================================================================
// Draws an AA bezier line
//==================================================================================
void SPG_BezierAA(SDL_Surface *surface, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2,Sint16 x3, Sint16 y3, Sint16 x4, Sint16 y4, int level, Uint32 color)
{
SPG_BezierAABlend(surface, x1,y1, x2,y2, x3,y3, x4,y4, level, color, SDL_ALPHA_OPAQUE);
}


