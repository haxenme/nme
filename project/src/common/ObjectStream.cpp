#include <nme/ObjectStream.h>
#include <map>

namespace nme
{

class ObjectEncoder : public ObjectStreamOut
{
   enum { PARENT_TOO = 0x0001 };

   std::map<Object *,int> encodedObjects;
public:
   ObjectEncoder(int inFlags) : ObjectStreamOut(inFlags & PARENT_TOO)
   {
   }

   void addObject(Object *inObj)
   {
   }

};

ObjectStreamOut *ObjectStreamOut::createEncoder(int inFlags)
{
   return new ObjectEncoder(inFlags);
}



class ObjectDecoder : public ObjectStreamIn
{
public:
   ObjectDecoder(const unsigned char *inPtr, int inLength,int inFlags) 
      : ObjectStreamIn(inPtr, inLength)
   {
   }

   Object *decodeObject()
   {
      return 0;
   }

   void linkAbstract(Object *inObject)
   {
   }

};




ObjectStreamIn *ObjectStreamIn::createDecoder(const unsigned char *inPtr, int inLength,int inFlags)
{
   return new ObjectDecoder(inPtr, inLength, inFlags);
}




}

