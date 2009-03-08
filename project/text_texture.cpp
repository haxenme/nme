#include <SDL_ttf.h>
#include <map>
#include <string>
#include "texture_buffer.h"
#include <neko.h>


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
         //printf("Found font in %s\n", file_name.c_str());
         font = TTF_OpenFont(file_name.c_str(),inPointSize);
      }
      if (font==0)
         font = TTF_OpenFont(("./fonts/" + fname).c_str(),inPointSize);

      if (font==0)
         font = TTF_OpenFont(("./data/" + fname).c_str(),inPointSize);
   }


   (*sFontMap)[key] = font;
   return font;
}




TextureBuffer *CreateTextTexture(const std::string &inFont,
                               int inPointSize,SDL_Color inColour,
                               const char *inText)
{
   //printf("CreateTextTexture %s/%s\n",inFont.c_str(),inText);
   TTF_Font *font = FindOrCreateFont(inFont,inPointSize);
   //printf("Font = %p\n",font);
   if (!font)
      return 0;

   /* Use SDL_TTF to render our text */
   SDL_Surface *initial = TTF_RenderText_Blended(font, inText, inColour);

   return new TextureBuffer(initial);
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


