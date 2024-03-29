#ifndef NME_CAMERA
#define NME_CAMERA

#include <nme/Object.h>
#include <nme/NmeApi.h>
#include <nme/ImageBuffer.h>
#include <nme/NmeCffi.h>
#include <string>
#include <vector>

namespace nme
{

enum CameraStatus { camInit, camError, camStopped, camRunning };

struct FrameBuffer
{
   FrameBuffer() : width(0), height(0), stride(0), age(-1) { }
   unsigned char *row(int inY) { return &data[inY*stride]; }
   float *depthRow(int inY) { return &depth[inY*depthWidth]; }
   void clear();


   std::vector<unsigned char> data;
   std::vector<unsigned char> mjpegData;
   std::vector<float> depth;

   int depthWidth;
   int depthHeight;

   int width;
   int height;
   int stride;

   int  age;
};

class Camera : public Object
{
public:
   Camera();
   ~Camera() { if (buffer) buffer->DecRef(); }

   void onFrame(value inHandler);
   void syncUpdate(value inHandler);
   virtual void onPoll(value inHandler);

   virtual void copyFrame(ImageBuffer *outBuffer, FrameBuffer *inFrame) { }
   virtual void lock( ) = 0;
   virtual void unlock( ) = 0;
   virtual void releaseFrameBuffer(FrameBuffer *ioBuffer)
   {
      ioBuffer->age = -1;
   }
   FrameBuffer  *getWriteBuffer();
   FrameBuffer  *getReadBuffer();

   bool setError(const std::string &inError);

   inline bool ok() { return status !=camError; }

   virtual int getJpegSize() { return 0; }
   virtual const unsigned char *getJpegData() { return nullptr; }



   CameraStatus status;
   std::string  error;
   int          width;
   int          height;
   int          frameId;
   PixelFormat  pixelFormat;
   FrameBuffer  frameBuffers[3];
   ImageBuffer  *buffer;
   int          depthWidth;
   int          depthHeight;
   std::vector<float> depth;
};

Camera *CreateCamera(const char *inName);


} // end namespace nme

#endif
