#ifndef STAGE_VIDEO_H
#define STAGE_VIDEO_H

#include <ExternalInterface.h>

namespace nme
{


class StageVideo : public Object
{
protected:
   AutoGCRoot mOwner;

public:
   StageVideo();
   void setOwner(value inOwner);

   virtual void play(const char *inUrl, double inStart, double inLength) = 0;
   virtual void seek(double inTime) = 0;
   virtual void setPan(double x, double y) = 0;
   virtual void setZoom(double x, double y) = 0;
   virtual void setSoundTransform(double x, double y) = 0;
   virtual void setViewport(double x, double y, double width, double height) = 0;
   virtual double getTime() = 0;
   virtual void pause() = 0;
   virtual void resume() = 0;
   virtual void togglePause() = 0;
   virtual void destroy() = 0;
};


}

#endif
