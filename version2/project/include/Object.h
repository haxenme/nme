#ifndef NME_OBJECT_H
#define NME_OBJECT_H

namespace nme
{

class Object
{
public:
	Object(bool inInitialRef=0) : mRefCount(inInitialRef?1:0) { }
	Object *IncRef() { mRefCount++; return this; }
	void DecRef() { mRefCount--; if (mRefCount<=0) delete this; }

protected:
	virtual ~Object() { }

   int mRefCount;
};

} // end namespace nme


#endif
