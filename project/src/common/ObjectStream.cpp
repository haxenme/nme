#include <nme/ObjectStream.h>
#include <Surface.h>
#include <Display.h>
#include <TextField.h>
#include <map>
#include <vector>

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

   void encodeObject(Object *inObj)
   {
      if (encodedObjects.find(inObj)!=encodedObjects.end())
      {
         addInt(encodedObjects[inObj]);
      }
      else
      {
         addInt(encodedObjects.size());
         encodedObjects[inObj] = encodedObjects.size();
         NmeObjectType type = inObj->getObjectType();
         addInt(type);
         inObj->encodeStream(*this);
      }
   }
};

ObjectStreamOut *ObjectStreamOut::createEncoder(int inFlags)
{
   return new ObjectEncoder(inFlags);
}



class ObjectDecoder : public ObjectStreamIn
{
   std::vector<Object *> objects;
public:
   ObjectDecoder(const unsigned char *inPtr, int inLength,int inFlags) 
      : ObjectStreamIn(inPtr, inLength)
   {
   }
   ~ObjectDecoder()
   {
      for(int i=0;i<objects.size();i++)
         objects[i]->DecRef();
   }

   Object *decodeObject()
   {
      int pos = getInt();
      if (pos<objects.size())
         return objects[pos];
      if (pos!=objects.size())
      {
         printf("Object stream mismatch %d!=%d\n", pos, (int)objects.size());
         return 0;
      }

      Object *newObject = 0;
      NmeObjectType type = (NmeObjectType)getInt();
      switch(type)
      {
         case notTilesheet:
            newObject = Tilesheet::fromStream(*this);
            break;

         case notSurface:
            newObject = SimpleSurface::fromStream(*this);
            break;

         case notTextFormat:
            newObject = TextFormat::fromStream(*this);
            break;

         case notDisplayObject:
         case notDisplayObjectContainer:
         case notDirectRenderer:
         case notSimpleButton:
         case notTextField:
            newObject = DisplayObject::fromStream(*this);
            break;

         case notGraphics:
            newObject = Graphics::fromStream(*this);
            break;

         default:
            printf("TODO - decodeObject %d\n", type);
            return 0;
      }

      return newObject;
   }

   void linkAbstract(Object *inObject)
   {
      inObject->IncRef();
      objects.push_back(inObject);
   }

};




ObjectStreamIn *ObjectStreamIn::createDecoder(const unsigned char *inPtr, int inLength,int inFlags)
{
   return new ObjectDecoder(inPtr, inLength, inFlags);
}




}

