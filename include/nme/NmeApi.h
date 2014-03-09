#ifndef NME_NME_API_H
#define NME_NME_API_H

#include "Pixel.h"

namespace nme
{

enum { NME_API_VERSION = 100 };

class NmeApi
{
public:
    virtual int getApiVersion() { return NME_API_VERSION; }
    virtual bool getC0IsRed() { return gC0IsRed; }
};

extern NmeApi gNmeApi;


} // end namespace nme

#endif
