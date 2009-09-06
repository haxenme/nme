#include <Font.h>
#include <Utils.h>
#include <map>

#include <ft2build.h>
#include FT_FREETYPE_H

FT_Library sgLibrary = 0;


Font::Font(FT_Face inFace, int inPixelHeight, bool inInitRef) :
	  Object(inInitRef), mFace(inFace), mPixelHeight(inPixelHeight)
{
	mCurrentSheet = -1;
}


Font::~Font()
{
	for(int i=0;i<mSheets.size();i++)
		mSheets[i]->DecRef();
}


Tile Font::GetGlyph(int inCharacter)
{
   Glyph &glyph = inCharacter < 128 ? mGlyph[inCharacter] : mExtendedGlyph[inCharacter];
	if (glyph.sheet<0)
	{
		int idx = FT_Get_Char_Index( mFace, inCharacter );
		int err = FT_Load_Glyph( mFace, idx, FT_LOAD_DEFAULT  );
		FT_Render_Mode mode = FT_RENDER_MODE_NORMAL; // FT_RENDER_MODE_MONO
		if (err==0 && mFace->glyph->format != FT_GLYPH_FORMAT_BITMAP)
			err = FT_Render_Glyph( mFace->glyph, mode );

      int l = mFace->glyph->bitmap_left;
      int t = mFace->glyph->bitmap_top;
      FT_Bitmap bitmap = mFace->glyph->bitmap;
		int rect_w = bitmap.width;
		int rect_h = bitmap.rows;

		while(1)
		{
			// Allocate new sheet?
			if (mCurrentSheet<0)
			{
				int rows = mPixelHeight > 128 ? 1 : mPixelHeight > 64 ? 2 : mPixelHeight>32 ? 4 : 5;
				int h = 4;
				while(h<mPixelHeight*rows)
					h*=2;
				int w = h;
				while(w<rect_w)
					w*=2;
            TileSheet *sheet = new TileSheet(w,h,true);
				mCurrentSheet = mSheets.size();
				mSheets.push_back(sheet);
			}

			int tid = mSheets[mCurrentSheet]->AllocRect(rect_w,rect_h,-l,-t);
			if (tid>=0)
			{
		      glyph.sheet = mCurrentSheet;
				glyph.tile = tid;
				break;
			}

			// Need new sheet...
			mCurrentSheet = -1;
		}

		printf("Got char %dx%d  +%d,%d\n", bitmap.rows, bitmap.width, l,t);


		// Find bounding rect ...
	}

	Tile result;
	return result;
}






// --- Create font from TextFormat ----------------------------------------------------


#ifdef HX_WINDOWS
#include <windows.h>
#include <tchar.h>

#define strcasecmp stricmp

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


static FT_Face OpenFont(const std::string &inFace, unsigned char inFlags)
{
	FT_Face face = 0;
   FT_New_Face(sgLibrary, inFace.c_str(), 0, &face);
	if (face && inFlags!=0 && face->num_faces>1)
	{
		int n = face->num_faces;
		// Look for other font that may match
      for(int f=1;f<n;f++)
		{
	      FT_Face test = 0;
         FT_New_Face(sgLibrary, inFace.c_str(), f, &test);
			if (test && test->style_flags == inFlags)
         {
				// A goodie!
			   FT_Done_Face(face);
				return test;
			}
			else if (test)
			   FT_Done_Face(test);
		}
		// The original face will have to do...
	}
	return face;
}

enum
{
	ffItalic  = 0x01,
	ffBold    = 0x02,
};


FT_Face FindFont(const std::string &inFontName, unsigned int inFlags)
{
   std::string fname = inFontName;
   if (fname.find(".")==std::string::npos)
      fname += ".ttf";

   FT_Face font = OpenFont(fname,inFlags);

   if (font==0 && fname.find("\\")==std::string::npos && fname.find("/")==std::string::npos)
   {
      std::string file_name;
      if (GetFontFile(fname,file_name))
      {
         //printf("Found font in %s\n", file_name.c_str());
         font = OpenFont(file_name.c_str(),inFlags);
      }
      if (font==0)
         font = OpenFont(("./fonts/" + fname).c_str(),inFlags);

      if (font==0)
         font = OpenFont(("./data/" + fname).c_str(),inFlags);
   }

   return font;
}


struct FontInfo
{
	FontInfo(const TextFormat &inFormat,double inScale)
	{
		name = inFormat.font;
		height = (int )(inFormat.size*inScale + 0.5);
		flags = 0;
		if (inFormat.bold)
			flags |= ffBold;
		if (inFormat.italic)
			flags |= ffItalic;
	}

	bool operator<(const FontInfo &inRHS) const
	{
		if (name < inRHS.name) return true;
		if (name > inRHS.name) return false;
		if (height < inRHS.height) return true;
		if (height > inRHS.height) return false;
		return flags < inRHS.flags;
	}
   std::wstring name;
	int          height;
	unsigned int flags;
};


typedef std::map<FontInfo, FT_Face> FaceMap;
FaceMap sgFaceMap;

Font *Font::Create(TextFormat &inFormat,double inScale,bool inInitRef)
{
	if (!sgLibrary)
     FT_Init_FreeType( &sgLibrary );
	if (!sgLibrary)
		return 0;

	FontInfo info(inFormat,inScale);
	FT_Face face = 0;
	FaceMap::iterator fit = sgFaceMap.find(info);
	if (fit==sgFaceMap.end())
	{
		
		std::string str = WideToUTF8(inFormat.font);
		face = FindFont(str,info.flags);
		if (!face)
			return 0;
		FT_Set_Pixel_Sizes(face,0,info.height);
		sgFaceMap[info] = face;
	}
	else
		face = fit->second;

	return new Font(face,info.height,inInitRef);
}


