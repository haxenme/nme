#include <Font.h>
#include <Utils.h>
#include <map>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_BITMAP_H

FT_Library sgLibrary = 0;







class FreeTypeFont : public FontFace
{
public:
   FreeTypeFont(FT_Face inFace, int inPixelHeight, int inTransform) :
	  mFace(inFace), mPixelHeight(inPixelHeight),mTransform(inTransform)
	{
	}


	~FreeTypeFont()
	{
		FT_Done_Face(mFace);
	}

	bool LoadBitmap(int inChar)
	{
		int idx = FT_Get_Char_Index( mFace, inChar );
		int err = FT_Load_Glyph( mFace, idx, FT_LOAD_DEFAULT  );
		if (err)
			return false;

		FT_Render_Mode mode = FT_RENDER_MODE_NORMAL;
		// mode = FT_RENDER_MODE_MONO;
		if (mFace->glyph->format != FT_GLYPH_FORMAT_BITMAP)
			err = FT_Render_Glyph( mFace->glyph, mode );
		if (err)
			return false;

		if (mTransform & ffBold)
		{
			FT_GlyphSlot_Own_Bitmap(mFace->glyph);
         FT_Bitmap_Embolden(sgLibrary, &mFace->glyph->bitmap, 1<<6, 0);
		}
      return true;
	}


	bool GetGlyphInfo(int inChar, int &outW, int &outH, int &outAdvance,
									int &outOx, int &outOy)
	{
		if (!LoadBitmap(inChar))
			return false;

      outOx = mFace->glyph->bitmap_left;
      outOy = -mFace->glyph->bitmap_top;
      FT_Bitmap &bitmap = mFace->glyph->bitmap;
		outW = bitmap.width;
		outH = bitmap.rows;
		outAdvance = (mFace->glyph->advance.x >> 6);
		return true;
	}


	void RenderGlyph(int inChar,RenderTarget &outTarget)
	{
		if (!LoadBitmap(inChar))
			return;

      FT_Bitmap &bitmap = mFace->glyph->bitmap;
		int w = bitmap.width;
		int h = bitmap.rows;
		if (w>outTarget.mRect.w || h>outTarget.mRect.h)
			return;

		for(int r=0;r<h;r++)
      {
         unsigned char *row = bitmap.buffer + r*bitmap.pitch;
         uint32  *dest = (uint32 *)outTarget.Row(r + outTarget.mRect.y) + outTarget.mRect.x;

         if (bitmap.pixel_mode == FT_PIXEL_MODE_MONO)
         {
            int bit = 0;
            int data = 0;
            for(int x=0;x<outTarget.mRect.w;x++)
            {
               if (!bit)
               {
                  bit = 128;
                  data = *row++;
               }
               *dest++ =  (data & bit) ? 0xffffffff : 0x00000000;
               bit >>= 1;
            }
         }
         else if (bitmap.pixel_mode == FT_PIXEL_MODE_GRAY)
         {
            for(int x=0;x<w;x++)
               *dest ++ = 0xffffff | ( (*row++) << 24 );
         }
      }
	}


	int Height()
	{
		return mFace->size->metrics.height/(1<<6);
	}


	void UpdateMetrics(TextLineMetrics &ioMetrics)
	{
      if (mFace)
		{
			FT_Size_Metrics &metrics = mFace->size->metrics;
			ioMetrics.ascent = std::max( ioMetrics.ascent, (float)metrics.ascender/(1<<6) );
			ioMetrics.descent = std::max( ioMetrics.descent, (float)metrics.descender/(1<<6) );
			ioMetrics.height = std::max( ioMetrics.height, (float)metrics.height/(1<<6) );
		}
	}

	FT_Face  mFace;
	uint32 mTransform;
	int    mPixelHeight;

};


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




FontFace *FontFace::CreateFreeType(const TextFormat &inFormat,double inScale)
{
	if (!sgLibrary)
     FT_Init_FreeType( &sgLibrary );
	if (!sgLibrary)
		return 0;

	FT_Face face = 0;
	std::string str = WideToUTF8(inFormat.font);

	uint32 flags = 0;
	if (inFormat.bold)
		flags |= ffBold;
	if (inFormat.italic)
		flags |= ffItalic;

	face = FindFont(str,flags);
	if (!face)
		return 0;

	int height = (int )(inFormat.size*inScale + 0.5);
	FT_Set_Pixel_Sizes(face,0, height);


	uint32 transform = 0;
	if ( !(face->style_flags & ffBold) && inFormat.bold )
		transform |= ffBold;
	if ( !(face->style_flags & ffItalic) && inFormat.italic )
		transform |= ffItalic;
	return new FreeTypeFont(face,height,transform);
}



#if 0

#define Z(x,y) zone[(y)*w+(x)]
#define Zp(p) zone[(p.y)*w+(p.x)]
#define A(x,y) (*(bitmap.buffer + (y)*bitmap.pitch+(x)))
#define Ap(p) (*(bitmap.buffer + (p.y)*bitmap.pitch+(p.x)))

void SharpenText(FT_Bitmap &bitmap)
{
   enum { BG_THRESH = 32 };
   enum { T_THRESH = 80 };
   enum { FG_THRESH = 160 };
   enum { END_THRESH = 64 };

   int w = bitmap.width;
   int h = bitmap.rows;
   if (w<2 || h<2) return;

   std::vector<int> zone( w*h, -1 );

   static int DX[] = { -1, 0, 1, 0 };
   static int DY[] = { 0, 1, 0, -1 };

   // Allocate "hole zones" so we do not join holes...
   int zone_id = 1;
   for(int y=0;y<h;y++)
   {
      unsigned char *row = bitmap.buffer + y*bitmap.pitch;
      for(int x=0;x<w;x++)
      {
         int z;
         QuickVec<ImagePoint> stack;
         if (x==0 && y==0)
         {
            ImagePoint p;
            z = 0;
            for(p.x=0;p.x<w;p.x++)
            {
               p.y = 0;
               if (Ap(p)<BG_THRESH) { stack.push_back(p); Ap(p) = 0; Zp(p) = z; }
               p.y = h-1;
               if (Ap(p)<BG_THRESH) { stack.push_back(p); Ap(p) = 0; Zp(p) = z; }
            }
            for(p.y=0;p.y<h;p.y++)
            {
               p.x = 0;
               if (Ap(p)<BG_THRESH) { stack.push_back(p); Ap(p) = 0; Zp(p) = z; }
               p.x = w-1;
               if (Ap(p)<BG_THRESH) { stack.push_back(p); Ap(p) = 0; Zp(p) = z; }
            }
         }
         else if (*row<BG_THRESH && Z(x,y)<0 )
         {
            *row = 0;
            z = zone_id++;
            Z(x,y) = z;
            stack.push_back(ImagePoint(x,y));
         }

         while(!stack.empty())
         {
            ImagePoint s = stack.qpop();

            for(int d=0;d<4;d++)
            {
               ImagePoint p(s.x+DX[d], s.y+DY[d]);
               if (p.x>=0 && p.x<w && p.y>=0 && p.y<h && Ap(p)<BG_THRESH && Zp(p)<0)
               {
                  stack.push_back(p);
                  Ap(p) = 0;
                  Zp(p) = z;
               }
            }
         }
         row++;
      }

   }
   for(int thresh = BG_THRESH; thresh< FG_THRESH; )
   {
      int next = FG_THRESH;
      for(int y=0;y<h;y++)
      {
         unsigned char *row = bitmap.buffer + y*bitmap.pitch;
         for(int x=0;x<w;x++)
         {
            unsigned char &r = *row++;
            if (r==thresh)
            {
               int join_neighbour = -1;
               int neighbours = 0;
               int nx = 0;
               int ny = 0;
               int mult_zone = false;

               for(int d=0;d<4;d++)
               {
                  ImagePoint p(x+DX[d], y+DY[d]);
                  int z = (p.x>=0 && p.x<w && p.y>=0 && p.y<h) ? Zp(p) : 0;

                  if (z>=0)
                  {
                     if (join_neighbour>=0)
                        mult_zone = mult_zone || join_neighbour!=z;
                     else
                        join_neighbour = z;
                  }
                  else
                  {
                     if (DX[d]) ny++;
                     else nx++;
                     neighbours++;
                  }
               }
               if (mult_zone)
               {
                  A(x,y) = 255;
                  continue;
               }

               if (join_neighbour>=0 || A(x,y)<FG_THRESH )
               {
                  if ( (nx==2 && ny==0) || (nx==0 && ny==2) || neighbours==0 ||
                       (neighbours==3 && A(x,y)>T_THRESH )  ||
                       (neighbours==1 && A(x,y)>END_THRESH )  )
						{
                     if ( (nx==2 && ny==0) || (nx==0 && ny==2) || neighbours==0)
								A(x,y)=255;
							else
							{
                        A(x,y) += 10;
							   if (next>thresh+10) next = thresh+10;
							}
						}
                  else
                  {
							// Erase point
                     int oval = A(x,y);
                     A(x,y) = 0;
                     Z(x,y) = join_neighbour;
                  }
               }
               else
					{
                  A(x,y) += 10;
						if (next>thresh+10) next = thresh+10;
                  //A(x,y) = 255;
					}

            }
            else if (r>thresh && r<next)
               next = r;
         }
      }
      thresh = next;
   }

   if (0)
      for(int y=0;y<h;y++)
      {
         unsigned char *row = bitmap.buffer + y*bitmap.pitch;
         for(int x=0;x<w;x++)
         {
            if (Z(x,y) > 0)
               *row = 128;
            else if (Z(x,y) == 0)
               *row = 64;
            row++;
         }
      }
};
#endif



