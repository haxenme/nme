#include <Graphics.h>
#include <map>

static void CombineCol(double &outScale, double &outOff,  double inPScale, double inPOff,
							  double inCScale, double inCOff)
{
	outScale = inPScale * inCScale;
	outOff = inPScale * inCOff + inPOff;
}

void ColorTransform::Combine(const ColorTransform &inParent, const ColorTransform &inChild)
{
	CombineCol(redScale,redOffset,
				  inParent.redScale,inParent.redOffset,
				  inChild.redScale, inChild.redOffset);
	CombineCol(greenScale,greenOffset,
				  inParent.greenScale,inParent.greenOffset,
				  inChild.greenScale, inChild.greenOffset);
	CombineCol(blueScale,blueOffset,
				  inParent.blueScale,inParent.blueOffset,
				  inChild.blueScale, inChild.blueOffset);
	CombineCol(alphaScale,alphaOffset,
				  inParent.alphaScale,inParent.alphaOffset,
				  inChild.alphaScale, inChild.alphaOffset);
}

static uint8 *sgIdentityLUT = 0;

typedef std::pair<double,double> Trans;
struct LUT
{
	int mLastUsed;
	uint8 mLUT[256];
};
static int sgLUTID = 0;
typedef std::map<Trans,LUT> LUTMap;
static LUTMap sgLUTs;

enum { LUT_CACHE = 256 };

void ColorTransform::TidyCache()
{
	if (sgLUTID>(1<<30))
	{
		sgLUTID = 1;
		sgLUTs.clear();
	}
}


const uint8 *GetLUT(double inScale, double inOffset)
{
	if (inScale==1 && inOffset==0)
	{
		if (sgIdentityLUT==0)
		{
			sgIdentityLUT = new uint8[256];
			for(int i=0;i<256;i++)
				sgIdentityLUT[i] = i;
		}
		return sgIdentityLUT;
	}

	sgLUTID++;

   Trans t(inScale,inOffset);
	LUTMap::iterator it = sgLUTs.find(t);
	if (it!=sgLUTs.end())
	{
       it->second.mLastUsed = sgLUTID;
		 return it->second.mLUT;
	}

	if (sgLUTs.size()>LUT_CACHE)
	{
		int oldest = 0;
		LUTMap::iterator where;
		for(LUTMap::iterator i=sgLUTs.begin(); i!=sgLUTs.end();++i)
		{
			if (i->second.mLastUsed < oldest)
			{
			   oldest = i->second.mLastUsed;
				where = i;
			}
		}
		sgLUTs.erase(where);
	}

	LUT &lut = sgLUTs[t];
	lut.mLastUsed = sgLUTID;
	for(int i=0;i<256;i++)
	{
		double ival = i*inScale + inOffset;
		lut.mLUT[i] = ival < 0 ? 0 : ival>255 ? 255 : (int)ival;
	}
	return lut.mLUT;
}



const uint8 *ColorTransform::GetAlphaLUT() const
{
	return GetLUT(alphaScale,alphaOffset);
}

const uint8 *ColorTransform::GetC0LUT() const
{
	if (gC0IsRed)
	   return GetLUT(redScale,redOffset);
	else
	   return GetLUT(blueScale,blueOffset);
}

const uint8 *ColorTransform::GetC1LUT() const
{
	return GetLUT(greenScale,greenOffset);
}

const uint8 *ColorTransform::GetC2LUT() const
{
	if (gC0IsRed)
	   return GetLUT(blueScale,blueOffset);
	else
	   return GetLUT(redScale,redOffset);
}


