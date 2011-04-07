#ifndef NME_BYTE_ARRAY_H
#define NME_BYTE_ARRAY_H

#include "Object.h"
#include "QuickVec.h"
#include "Utils.h"

namespace nme
{


struct ByteArray : public Object
{
	QuickVec<unsigned char> mBytes;
   static ByteArray *FromFile(const OSChar *inFilename);
   #ifdef HX_WINDOWS
   static ByteArray *FromFile(const char *inFilename);
   #endif
};

#ifdef ANDROID
ByteArray *AndroidGetAssetBytes(const char *);
#endif

}

#endif
