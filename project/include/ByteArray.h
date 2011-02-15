#ifndef NME_BYTE_ARRAY_H
#define NME_BYTE_ARRAY_H

#include "QuickVec.h"

namespace nme
{


struct ByteArray : public Object
{
	QuickVec<unsigned char> mBytes;
};

#ifdef ANDROID
ByteArray *AndroidGetAssetBytes(const char *);
#endif

}

#endif
