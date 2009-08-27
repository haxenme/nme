#ifndef PIXEL_H
#define PIXEL_H

// The order or RGB or BGR is determined to the primary surface's
//  native order - this allows most transfers to be donw without swapping R & B
// When rendering from a source to a dest, the source is swapped to match in
//  the blending code.

extern int sgC0Shift;
extern int sgC1Shift;
extern int sgC2Shift;
extern bool sgC0IsRed;
 
typedef unsigned char Uint8;

struct ARGB
{
   inline void Set(int inVal) { ival = inVal; }

   inline void SetRGB(int inVal)
   {
      c0 = (inVal>>16) & 0xff;
      c1 = (inVal>>8) & 0xff;
      c2 = (inVal) & 0xff;
		a = 255;
   }
   inline void SetRGBA(int inVal)
   {
      c0 = (inVal>>16) & 0xff;
      c1 = (inVal>>8) & 0xff;
      c2 = (inVal) & 0xff;
		a = (inVal>>24);
   }

   inline void SetRGBNative(int inVal)
   {
      c0 = (inVal>>sgC0Shift) & 0xff;
      c1 = (inVal>>sgC1Shift) & 0xff;
      c2 = (inVal>>sgC2Shift) & 0xff;
		a = 255;
   }
   inline void SetRGBANative(int inVal)
   {
      c0 = (inVal>>sgC0Shift) & 0xff;
      c1 = (inVal>>sgC1Shift) & 0xff;
      c2 = (inVal>>sgC2Shift) & 0xff;
		a = (inVal>>24);
   }


	inline void SetSwapRGB(const ARGB &inRGB)
	{
		c0 = inRGB.c2;
		c1 = inRGB.c1;
		c2 = inRGB.c0;
	}
	inline void SetSwapRGBA(const ARGB &inRGB)
	{
		c0 = inRGB.c2;
		c1 = inRGB.c1;
		c2 = inRGB.c0;
		a = inRGB.a;
	}


	template<bool SWAP_RB,bool DEST_ALPHA>
   inline void Blend(const ARGB &inVal)
   {
		int A = inVal.a;
		if (A>5)
		{
			// Replace if input is full, or we are empty
			if (A>254 || (DEST_ALPHA && a<5) )
			{
				if (SWAP_RB)
				{
					if (DEST_ALPHA)
				      SetSwapRGBA(inVal);
					else
				      SetSwapRGB(inVal);
				}
				else
				   ival = inVal.ival;
			}
			// Our alpha is implicitly 256 ...
			if (!DEST_ALPHA)
			{
				int f = 256-A;
				if (SWAP_RB)
				{
				   c0 = (A*inVal.c0 + f*c0)>>8;
				   c1 = (A*inVal.c1 + f*c1)>>8;
				   c2 = (A*inVal.c2 + f*c2)>>8;
				}
				else
				{
				   c0 = (A*inVal.c2 + f*c0)>>8;
				   c1 = (A*inVal.c1 + f*c1)>>8;
				   c2 = (A*inVal.c0 + f*c2)>>8;
				}
			}
			else
			{
				int alpha16 = ((a + A)<<8) - a*A;
				int f = (255-A) * a;
				A<<=8;
				if (SWAP_RB)
				{
				   c0 = (A*inVal.c0 + f*c0)/alpha16;
				   c1 = (A*inVal.c1 + f*c1)/alpha16;
				   c2 = (A*inVal.c2 + f*c2)/alpha16;
				}
				else
				{
				   c0 = (A*inVal.c2 + f*c0)/alpha16;
				   c1 = (A*inVal.c1 + f*c1)/alpha16;
				   c2 = (A*inVal.c0 + f*c2)/alpha16;
				}
				a = alpha16>>8;
			}
		}
   }


   union
   {
      struct { Uint8 c0,c1,c2,a; };
      int  ival;
   };
};




#endif
