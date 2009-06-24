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

 
#include "text.h"
#include "nsdl.h"
#include "nme.h"
#include <SDL_ttf.h>
#include <math.h>

#include <ft2build.h>
#include <freetype/freetype.h>
#include <freetype/ftoutln.h>

#define FT_CEIL(X)	(((X + 63) & -64) / 64)

DEFINE_KIND( k_font );


// TTF_Init() must be called before using this function.
// Remember to call TTF_Quit() when done.
value nme_ttf_shaded( value* args, int nargs )
{
#ifdef NME_TTF
	if ( nargs < 9 ) hx_failure( "not enough parameters passed to function nme_ttf_shaded. expected 9" );
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
#endif
        return alloc_int(0);
}


void delete_font( value font )
{
   if ( val_is_kind( font, k_font ) )
   {
      val_gc( font, NULL );

      #ifdef NME_TTF
      TTF_Font *ttf_font = FONT(font);
      // Since create-or-find is used, no need to do this ...
      // TTF_CloseFont(font);
      #endif
   }
}



value nme_create_font_handle(value inFace,value inSize)
{
   #ifdef NME_TTF
   val_check( inFace, string );
   val_check( inSize, int );

   TTF_Font *font = FindOrCreateFont(val_string(inFace),val_int(inSize));
   if (font==0)
      return val_null;

   value v = alloc_abstract( k_font, font );
   val_gc( v, delete_font );
   return v;
   #else
   return val_null;
   #endif
}

value nme_get_font_metrics(value inFont)
{
   #ifdef NME_TTF
   if (val_is_kind(inFont,k_font))
   {
      TTF_Font *font = FONT(inFont);

      value result = alloc_empty_object();
      alloc_field( result, val_id("height"), alloc_int(TTF_FontHeight(font)));
      alloc_field( result, val_id("ascent"), alloc_int(TTF_FontAscent(font)));
      alloc_field( result, val_id("descent"), alloc_int(TTF_FontDescent(font)));

      // Assume "face" is the first member of the ttf structure
      FT_Face face_ptr = *(FT_Face *)font;
      FT_FaceRec_ &face = *face_ptr;

      FT_Fixed scale = face.size->metrics.y_scale;
      int max_adv = FT_CEIL(FT_MulFix(face.max_advance_width,scale));

      alloc_field( result, val_id("max_x_advance"), alloc_int(max_adv));
      return result;
   }
   #endif

   return val_null;
}


class DebugOutlineIterator : public OutlineIterator
{
public:
    void moveTo(int x,int y) { printf("m %d,%d\n",x,y); }
    void lineTo(int x,int y) { printf("l %d,%d\n",x,y); }
};

static int sAscent = 0;
static int sLastX = 0;
static int sLastY = 0;

static int moveTo( const FT_Vector* to, void *user )
{
   OutlineIterator *oi = (OutlineIterator *)user;
   sLastX = to->x;
   sLastY = to->y;
   oi->moveTo(sLastX,sAscent-sLastY);
   return 0;
}

static int lineTo( const FT_Vector* to, void *user )
{
   OutlineIterator *oi = (OutlineIterator *)user;
   sLastX = to->x;
   sLastY = to->y;
   oi->lineTo(to->x,sAscent-sLastY);
   return 0;
}

static int conicTo( const FT_Vector* c, const FT_Vector *to,void *user )
{
   OutlineIterator *oi = (OutlineIterator *)user;

   double dx1 = to->x - sLastX;
   double dy1 = to->y - sLastY;
   double dx2 = to->x - c->x;
   double dy2 = to->y - c->y;
   int steps = (int)(sqrt(dx1*dx1 + dy1*dy1 + dx2*dx2 + dy2*dy2)*0.01);
   if (steps<2)
   {
      lineTo(to,user);
   }
   else
   {
      double du = 1.0/steps;
      double u = du;
      steps--;
      for(int i=1;i<steps;i++)
      {
         double u1 = 1.0-u;

         double c0=u1*u1;
         double c1=2.0*u*u1;
         double c2=u*u;
         u+=du;
         oi->lineTo( (int)(c0*sLastX + c1*c->x + c2*to->x) ,
                     sAscent-(int)(c0*sLastY + c1*c->y + c2*to->y) );
      }

      lineTo(to,user);
   }

   return 0;
}

static int cubicTo( const FT_Vector* c0, const FT_Vector *c1,
                    const FT_Vector *to,void *user )
{
   // TODO: need a test case....
   return lineTo(to,user);
}

static FT_Outline_Funcs sOutlineFuncs =
   { moveTo, lineTo, conicTo, cubicTo  };



value nme_get_glyph_metrics(value inFont,value inChar)
{
   val_check( inChar, int );
   #ifdef NME_TTF
   if (val_is_kind(inFont,k_font))
   {
      int c = val_int(inChar);
      TTF_Font *font = FONT(inFont);
      int min_x,max_x,min_y,max_y,advance;
      int err = TTF_GlyphMetrics(font,c,&min_x,&max_x,&min_y,&max_y,&advance);
      if (err)
         return val_null;

      value result = alloc_empty_object();
      alloc_field( result, val_id("min_x"), alloc_int(min_x));
      alloc_field( result, val_id("max_x"), alloc_int(max_x));
      alloc_field( result, val_id("width"), alloc_int(max_x-min_x));
      alloc_field( result, val_id("height"), alloc_int(max_y-min_y));
      alloc_field( result, val_id("x_advance"), alloc_int(advance));



      return result;
   }
   #endif
   return val_null;
}

void IterateOutline(value inFont, int inChar, OutlineIterator *inIter)
{
   #ifdef NME_TTF
   if (val_is_kind(inFont,k_font))
   {
      TTF_Font *font = FONT(inFont);

      FT_Face face_ptr = *(FT_Face *)font;
      FT_FaceRec_ &face = *face_ptr;

      sAscent = 64 * TTF_FontAscent(font);

      int err = FT_Load_Char( &face, inChar, FT_LOAD_DEFAULT  );
      if (!err)
      {
         if (face.glyph->format==FT_GLYPH_FORMAT_OUTLINE)
         {
            sOutlineFuncs.shift = 0;
            sOutlineFuncs.delta = 0;
            FT_Outline_Decompose(&face.glyph->outline, &sOutlineFuncs, inIter);
         }
      }
   }
   #endif
}



DEFINE_PRIM_MULT(nme_ttf_shaded);
DEFINE_PRIM(nme_create_font_handle,2);
DEFINE_PRIM(nme_get_font_metrics,1);
DEFINE_PRIM(nme_get_glyph_metrics,2);

int __force_text = 0;
