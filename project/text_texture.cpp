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

bool GetFontFile(const char *lpszFontName, std::string& strDisplayName, std::string& strFontFile)
{
   _TCHAR win_path[2 * MAX_PATH];
   GetWindowsDirectory(win_path, 2*MAX_PATH);
   strFontFile = std::string(win_path) + "\\Fonts\\" + lpszFontName + ".ttf";

   strDisplayName = lpszFontName;
   return true;
}


#endif

TTF_Font *FindOrCreateFont(const std::string &inFontName,int inPointSize)
{
   FontDef key(inFontName,inPointSize);

   if (!sFontMap) sFontMap = new FontMap;
   FontMap::iterator f =  sFontMap->find(key);
   if (f!=sFontMap->end())
      return f->second;

   // Look for "." to indicate filename ....
   TTF_Font *font = 0;

#ifdef __WIN32__
   if (inFontName.find(".")==std::string::npos)
   {
      std::string file_name,display_name;
      if (GetFontFile(inFontName.c_str(),display_name,file_name))
      {
         //printf("Found font in %s\n", file_name.c_str());
         font = TTF_OpenFont(file_name.c_str(),inPointSize);
      }
   }
#endif

   if (font==0)
   {
      font = TTF_OpenFont(inFontName.c_str(),inPointSize);
      // printf("Found font %s = %p\n", inFontName.c_str(),font);
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


