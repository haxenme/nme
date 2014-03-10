#ifndef NME_IMAGE_BUFFER_H
#define NME_IMAGE_BUFFER_H

#include "Texture.h"
#include "Pixel.h"

namespace nme
{


enum
{
   surfNotRepeatIfNonPO2    = 0x0001,
   surfUsePremultiliedAlpha = 0x0002,
   surfHasPremultiliedAlpha = 0x0004,
};


class ImageBuffer : public ApiObject
{
protected: // Use 'DecRef'
   virtual       ~ImageBuffer() { };
public:
   virtual unsigned int GetFlags() const = 0;
   virtual void SetFlags(unsigned int inFlags) = 0;

   virtual PixelFormat Format()  const = 0;
   virtual int  Version() const  = 0;
   virtual void OnChanged() = 0;

   virtual int                  Width(int inPlane=0) const =0;
   virtual int                  Height(int inPlane=0) const =0;
   virtual const unsigned char *GetBase(int inPlane=0) const = 0;
   virtual int                  GetStride(int inPlane=0) const = 0;
   virtual unsigned char        *Edit(const Rect *inRect, int inPlane=0) = 0;
   virtual void                 Commit(int inPlane=0) = 0;

   virtual Texture *GetTexture(class HardwareContext *inContext=0,int inPlane=0) = 0;
   virtual void  MakeTextureOnly() = 0;

   ImageBuffer *asImageBuffer() { return this; }


   inline const unsigned char *Row(int inY) const { return GetBase() + GetStride()*inY; }
};


} // end namespace nme

#endif
