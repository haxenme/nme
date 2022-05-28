#include <nme/Object.h>
#include <nme/NmeApi.h>
#include <nme/ImageBuffer.h>
#include <nme/NmeCffi.h>
#include <Camera.h>
#include <ByteArray.h>

#ifdef ANDROID
#include <android/log.h>
#endif

using namespace nme;

namespace nme
{
static int _id_on_error;
static int _id_init_frame;
static int _id_init_frame_fmt;
static int _id_on_frame;
static int _id_width;
static int _id_height;
static int _id_frameId;
static int _id_depth_width;
static int _id_depth_height;
static int _id_depth_data;

extern vkind gDataPointer;

using namespace nme;

void InitCamera()
{
    _id_on_error = val_id("_on_error");
    _id_init_frame = val_id("_init_frame");
    _id_init_frame_fmt = val_id("_init_frame_fmt");
    _id_on_frame = val_id("_on_frame");
    _id_width = val_id("width");
    _id_height = val_id("height");
    _id_frameId = val_id("frameId");
    _id_depth_width = val_id("depthWidth");
    _id_depth_height = val_id("depthHeight");
    _id_depth_data = val_id("depthData");
}


}


ImageBuffer *valueToImageBuffer(value inBmp)
{
   #ifndef HXCPP_JS_PRIME
   if (val_is_kind(inBmp,gObjectKind) )
   {
       Object *obj = (Object *)val_to_kind(inBmp,gObjectKind);
       if (obj)
          return obj->asImageBuffer();
   }
   #endif
   return 0;
}



// --- Camera --------------------

namespace nme
{

Camera::Camera() : status(camInit), buffer(0), width(0), height(0), pixelFormat(pfBGRA)
{
   frameId = 0;
}



bool Camera::setError(const std::string &inError)
{
   printf(" -> %s\n", inError.c_str() );
   error = inError;
   status = camError;
   return false;
}

FrameBuffer *Camera::getReadBuffer()
{
  lock();
  FrameBuffer *result = 0;
  for(int i=0;i<3;i++)
  {
     FrameBuffer &test = frameBuffers[i];
     if (test.age>=0)
     {
        if (result==0 || test.age>result->age)
           result = &test;
     }
  }
  unlock();
  return result;
}

void FrameBuffer::clear()
{
   width = 0;
   height = 0;
   stride = 0;
   data.resize(0);
   depthWidth = 0;
   depthHeight = 0;
   depth.resize(0);
   age = -1;
}

FrameBuffer *Camera::getWriteBuffer()
{
  lock();
  FrameBuffer *result = 0;
  for(int i=0;i<3;i++)
  {
     FrameBuffer &test = frameBuffers[i];
     if (result==0 || test.age<result->age)
        result = &test;
  }
  result->clear();
  unlock();
  return result;
}


void Camera::syncUpdate(value handler)
{
   if (status==camError)
   {
      val_ocall1(handler, _id_on_error, alloc_string_len(error.c_str(), error.size()) );
   }
   else if (status==camRunning && !buffer)
   {
      alloc_field(handler, _id_width, alloc_int(width));
      alloc_field(handler, _id_height, alloc_int(height));
      value bmp = pixelFormat==pfBGRA ? val_ocall0(handler, _id_init_frame) :
                                        val_ocall1(handler, _id_init_frame_fmt, alloc_int(pixelFormat) );
      buffer = valueToImageBuffer(bmp);
      //printf("Got image buffer %p %p (%d)\n", bmp, buffer, buffer ? buffer->Format() : 0);
   }
}


void Camera::onPoll(value handler)
{
   syncUpdate(handler);

   if (status==camRunning && buffer)
   {
      lock();
      FrameBuffer *frameBuffer = getReadBuffer();
      unlock();

      if (frameBuffer)
      {
         copyFrame(buffer,frameBuffer);
         depthWidth = frameBuffer->depthWidth;
         depthHeight = frameBuffer->depthHeight;
         std::swap(depth, frameBuffer->depth);
         releaseFrameBuffer(frameBuffer);

         alloc_field_numeric(handler, _id_depth_width, depthWidth );
         alloc_field_numeric(handler, _id_depth_height, depthHeight );
         if (depth.empty())
            alloc_field(handler, _id_depth_data, alloc_null() );
         else
         {
            value ptr = alloc_abstract(gDataPointer, &depth[0]);
            alloc_field(handler, _id_depth_data, ptr);
         }

         onFrame(handler);
      }
   }
}

void Camera::onFrame(value handler)
{
   val_ocall0(handler, _id_on_frame);
}

} // end namespace nme

value nme_camera_create(value inName)
{
   HxString name = valToHxString(inName);

   #if defined(__APPLE__) || defined(HX_WINDOWS) || defined(HX_LINUX)
   Camera *camera = CreateCamera(name.c_str());
   return ObjectToAbstract(camera);
   #else
   return alloc_null();
   #endif
}
DEFINE_PRIM(nme_camera_create,1);

value nme_camera_on_poll(value inCamera,value inHandler)
{
   Camera *camera;
   if (AbstractToObject(inCamera,camera))
      camera->onPoll(inHandler);
   return alloc_null();
}
DEFINE_PRIM(nme_camera_on_poll,2);

value nme_camera_close(value inCamera)
{
   Camera *camera;
   if (AbstractToObject(inCamera,camera))
      delete camera;
   return alloc_null();
}
DEFINE_PRIM(nme_camera_close,1);



void nme_camera_get_depth(value inCamera,value outBytes)
{
   Camera *camera;
   if (AbstractToObject(inCamera,camera))
   {
      ByteArray byteArray(outBytes);
      unsigned char *bytes = byteArray.Bytes();
      int size = byteArray.Size();
      if (camera->depth.size()>0 && size>=camera->depth.size()*4)
      {
         memcpy(bytes, &camera->depth[0], camera->depth.size()*4);
      }
   }
}
DEFINE_PRIME2v(nme_camera_get_depth);





