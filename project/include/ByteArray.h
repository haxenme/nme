#ifndef NME_BYTE_ARRAY_H
#define NME_BYTE_ARRAY_H

#include <vector>

namespace nme
{


struct ByteArray : public Object
{
	std::vector<unsigned char> mBytes;
};

}

#endif
