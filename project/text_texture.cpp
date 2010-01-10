#include <map>
#include <string>
#include "texture_buffer.h"
#include <hx/CFFI.h>

#ifdef NME_TTF

#include <SDL_ttf.h>

typedef std::pair<std::string,int> FontDef;

typedef std::map<FontDef,TTF_Font *> FontMap;

//static FontMap sFontMap;
static FontMap *sFontMap = 0;

#ifdef __WIN32__
#include <windows.h>
#include <tchar.h>

bool GetFontFile(const std::string& inName,std::string &outFile)
{
   _TCHAR win_path[2 * MAX_PATH];
   GetWindowsDirectory(win_path, 2*MAX_PATH);
   outFile = std::string(win_path) + "\\Fonts\\" + inName;

   return true;
}


#else
#ifdef __APPLE__
bool GetFontFile(const std::string& inName,std::string &outFile)
{

#ifdef IPHONEOS
#define FONT_BASE "/System/Library/Fonts/Cache/"
#define TIMES_ROMAN "TimesNewRoman.ttf"
#else
#define FONT_BASE "/Library/Fonts/"
#define TIMES_ROMAN "Times New Roman.ttf"
#endif

   if (!strcasecmp(inName.c_str(),"times.ttf"))
      outFile = FONT_BASE TIMES_ROMAN;
   else if (!strcasecmp(inName.c_str(),"arial.ttf"))
      outFile = FONT_BASE "Arial.ttf";
   else if (!strcasecmp(inName.c_str(),"courier.ttf"))
      outFile = FONT_BASE "Courier.ttf";
   else if (!strcasecmp(inName.c_str(),"helvetica.ttf"))
      outFile = FONT_BASE "Helvetica.ttf";
   else
   {
      outFile = FONT_BASE + inName;
      return true;
      //printf("Unfound font: %s\n",inName.c_str());
      return false;
   }

   /*
   char *guess[] = { 
                     "/System/Library/Fonts/Cache/Helvetica.ttf",
                     "/System/Library/Fonts/Cache/Arial.ttf",
                     "/System/Library/Fonts/Cache/Courier.ttf",
                     "/System/Library/Fonts/Cache/TimesNewRoman.ttf",
                     0 };
  for(char **g=guess; *g; g++)
  {
     FILE *f = fopen(*g,"rb");
     
     printf("Looking for font %s %p\n", *g, f);
     if (f)
      fclose(f);
  }
  */

   return true;
}
#else
bool GetFontFile(const std::string& inName,std::string &outFile)
{
   if (!strcasecmp(inName.c_str(),"times.ttf"))
      outFile = "/usr/share/fonts/truetype/freefont/FreeSerif.ttf";
   else if (!strcasecmp(inName.c_str(),"arial.ttf"))
      outFile = "/usr/share/fonts/truetype/freefont/FreeSans.ttf";
   else if (!strcasecmp(inName.c_str(),"courier.ttf"))
      outFile = "/usr/share/fonts/truetype/freefont/FreeMono.ttf";
   else
   {
      //printf("Unfound font: %s\n",inName.c_str());
      return false;
   }

   return true;
}
#endif


#endif

TTF_Font *FindOrCreateFont(const std::string &inFontName,int inPointSize)
{
   std::string fname = inFontName;
   if (fname.find(".")==std::string::npos)
      fname += ".ttf";

   FontDef key(fname,inPointSize);

   if (!sFontMap) sFontMap = new FontMap;
   FontMap::iterator f =  sFontMap->find(key);
   if (f!=sFontMap->end())
      return f->second;

   TTF_Font *font = TTF_OpenFont(fname.c_str(),inPointSize);

   if (font==0 &&
       fname.find("\\")==std::string::npos &&
       fname.find("/")==std::string::npos)
   {
      std::string file_name;
      if (GetFontFile(fname,file_name))
      {
         font = TTF_OpenFont(file_name.c_str(),inPointSize);
         //printf("Found font in %s (%p)\n", file_name.c_str(),font);
      }
      if (font==0)
         font = TTF_OpenFont(("./fonts/" + fname).c_str(),inPointSize);

      if (font==0)
         font = TTF_OpenFont(("./data/" + fname).c_str(),inPointSize);
   }


   (*sFontMap)[key] = font;
   return font;
}

#endif // NME_TTF


TextureBuffer *CreateTextTexture(const std::string &inFont,
                               int inPointSize,SDL_Color inColour,
                               const char *inText)
{
   #ifndef NME_TTF
   return 0;
   #else
   //printf("CreateTextTexture %s/%s\n",inFont.c_str(),inText);
   TTF_Font *font = FindOrCreateFont(inFont,inPointSize);
   //printf("Font = %p\n",font);
   if (!font)
      return 0;

   /* Use SDL_TTF to render our text */
   SDL_Color bg;
   bg.r = bg.g = bg.b = 0;
   SDL_Surface *initial = TTF_RenderText_Shaded(font, inText, inColour, bg);
   if (initial)
       SDL_SetAlpha(initial,SDL_SRCALPHA,255);

   return new TextureBuffer(initial);
   #endif
}


value nme_create_text_texture( value font, value point_size,
                               value colour, value text )
{
   val_check( font, string );
   val_check( point_size, int );
   val_check( colour, int );
   val_check( text, string );

   int icol = val_int(colour);
   SDL_Color col;
   col.r = (icol>>16) & 0xff;
   col.g = (icol>>8) & 0xff;
   col.b = (icol) & 0xff;

   TextureBuffer *result =
         CreateTextTexture( val_string(font), val_int(point_size),
                            col, val_string(text) );
   if (!result)
      return val_null;
   return result->ToValue();
}

DEFINE_PRIM(nme_create_text_texture, 4);

int __force_text_texture = 0;
