#ifndef OBJECT_H
#define OBJECT_H

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


#endif
