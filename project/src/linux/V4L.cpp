#include <vector>

#include <Camera.h>
#include <Surface.h>
#include <Utils.h>
#include <hx/Thread.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <fcntl.h> /* low-level i/o */
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <linux/videodev2.h>

namespace nme
{

#define CLEAR(x) memset(&(x), 0, sizeof(x))

enum V4LAsyncState
{
   v4lUnused,
   v4lWriting,
   v4lReading,
   v4lGood,
};

struct V4LAsyncBuf
{
   std::vector<uint8> i420Buf;
   std::vector<uint8> rgbBuffer;
   std::vector<uint8> jpegBuffer;
   V4LAsyncState      state;
   unsigned int       age;
   V4LAsyncBuf() : state(v4lUnused), age(0) { }
   const unsigned char *setMjpegData(const uint8 *inData, int inLen)
   {
      jpegBuffer.resize(inLen);
      memcpy(&jpegBuffer[0], inData, inLen);
      return &jpegBuffer[0];
   }
};

class V4L : public Camera
{
   HxMutex mutex;
   V4LAsyncBuf asyncBuf[3];
   V4LAsyncBuf *currentWriteBuffer;
   bool ok;
   int  fd;
   struct v4l2_format fmt;
   void *bufferData[3];
   int   bufferDataLen[3];
   bool streamOn;
   // Format produced by the capture device
   int   videoFormat;
   bool  threaded;
   bool  keepAlive;
   bool  mjpegBuffers;
   std::vector<uint8> jpegBuffer;

public:
   V4L(const char *inName)
   {
      std::string deviceName = "/dev/video0";
      std::vector<std::string> attribs;
      mjpegBuffers = false;

      if (inName && inName[0])
      {
         const char *p = inName;
         while(*p)
         {
            const char *p0 = p;
            while(*p && *p!=':')
               p++;

            std::string part(p0,p-p0);
            if (*p==':')
               p++;
            if (part[0]=='/')
               deviceName = part;
            else if (part.size())
               attribs.push_back(part);
         }
      }

      threaded = false;
      keepAlive = true;
      currentWriteBuffer = 0;


      streamOn = false;
      for(int i=0;i<3;i++)
         bufferData[i] = 0;

      fd = -1;
      videoFormat = 0;
      openDevice(deviceName);
      initDevice(attribs);
   }


   ~V4L()
   {
      if (threaded)
      {
         keepAlive = false;
         while(threaded)
            usleep(1000);
      }
      if (streamOn)
      {
         int type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
         if (-1 == xioctl(fd, VIDIOC_STREAMOFF, &type))
         {
            printf("VIDIOC_STREAMOFF error\n");
            // Hmm
         }
      }

      for(int i=0; i<3; i++)
      {
         if (bufferData[i])
         {
             if (-1 == munmap(bufferData[i], bufferDataLen[i]))
             {
                // Hmm
             }
         }
      }

      if (fd>=0)
         close(fd);
   }

   bool openDevice(const std::string &inName)
   {
      struct stat st;

      if (-1 == stat(inName.c_str(), &st))
         return setError("Video device does not exist:" + inName);

      if (!S_ISCHR(st.st_mode))
         return setError("Video source is not device:" + inName);

      fd = open(inName.c_str(), O_RDWR /* required */ | O_NONBLOCK, 0);
      if (-1 == fd)
         return setError("Could not open:" + inName + " " + strerror(errno));

      return true;
   }

   int xioctl(int fh, int request, void *arg, bool inQuiet = false)
   {
      int r;
      do {
         r = ioctl(fh, request, arg);
      } while (-1 == r && EINTR == errno);
      if (r==-1 && !inQuiet)
         printf("xioctl error %d %s\n", request, strerror(errno) );
      return r;
   }


   bool initDevice(const std::vector<std::string> &inAtribs)
   {
      struct v4l2_capability cap;
      struct v4l2_cropcap cropcap;
      struct v4l2_crop crop;
      unsigned int min;

      if (-1 == xioctl(fd, VIDIOC_QUERYCAP, &cap))
      {
         if (EINVAL == errno)
             return setError("Not a V4L2 device");

         return setError("VIDIOC_QUERYCAP");
      }

      if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE))
          return setError("Not a video capture device");
      /* Select video input, video standard and tune here. */

      int reqWidth = 640;
      int reqHeight = 480;
      bool debug = false;
      bool nocrop = false;
      bool mjpeg = false;
      bool yuyv = false;
      int reqFormat = V4L2_PIX_FMT_RGB24;
      for(int i=0;i<inAtribs.size();i++)
      {
         const std::string &attrib  = inAtribs[i];
         if (debug)
            printf("Attrib: %s\n", attrib.c_str());
         if (attrib[0]>='0' && attrib[0]<='9')
         {
            if (attrib=="1080p")
            {
               reqWidth = 1920;
               reqHeight = 1080;
            }
            else if (attrib=="960p")
            {
               reqWidth = 1280;
               reqHeight = 960;
            }
            else if (attrib=="720p")
            {
               reqWidth = 1280;
               reqHeight = 720;
            }
            else if (attrib=="600p")
            {
               reqWidth = 800;
               reqHeight = 600;
            }
            else if (attrib=="480p")
            {
               reqWidth = 640;
               reqHeight = 480;
            }
            else if (attrib=="360p")
            {
               reqWidth = 640;
               reqHeight = 360;
            }
         }
         else if (attrib=="stereo")
         {
            reqWidth *= 2;
         }
         else if (attrib=="debug")
         {
            debug = true;
         }
         else if (attrib=="nocrop")
         {
            nocrop = true;
         }
         else if (attrib=="yuyv")
         {
            yuyv = true;
         }
         else if (attrib=="mjpeg")
         {
            mjpeg = true;
         }
         else if (attrib=="mjpegbuffers")
         {
            mjpeg = true;
            mjpegBuffers = true;
         }
      }

      if (debug)
      {
         printf("Requested size:%dx%d. Supported:\n", reqWidth, reqHeight);
         struct v4l2_fmtdesc fmtdesc;
         CLEAR(fmtdesc);
         fmtdesc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
         while (ioctl(fd,VIDIOC_ENUM_FMT,&fmtdesc) == 0)
         {
            printf(" %s (%08x)\n", fmtdesc.description, fmtdesc.pixelformat);
            fmtdesc.index++;
         }
      }


      CLEAR(cropcap);
      cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

      int cropCapRes =  xioctl(fd, VIDIOC_CROPCAP, &cropcap, true);
      if (cropCapRes==ENODATA || cropCapRes==-1 || nocrop)
      {
         if (debug)
         {
            printf("No scaling, use supported format\n");
            struct v4l2_fmtdesc fmtdesc;
            CLEAR(fmtdesc);
            fmtdesc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
            while (ioctl(fd,VIDIOC_ENUM_FMT,&fmtdesc) == 0)
            {
               printf("%s (%08x)\n", fmtdesc.description, fmtdesc.pixelformat);
               fmtdesc.index++;
            }
         }

         int reqFormat = V4L2_PIX_FMT_RGB24;
         if (mjpeg)
         {
            if (debug)
               printf("Request MJPeg\n");
            reqFormat = V4L2_PIX_FMT_MJPEG;
         }
         else if (yuyv)
         {
            if (debug)
               printf("Request YUY2\n");
            reqFormat = V4L2_PIX_FMT_YUYV;
         }
         else
         {
            bool hasRgb = false;
            bool hasYuyv = false;
            bool hasMjpeg = false;
            struct v4l2_fmtdesc fmtdesc;
            CLEAR(fmtdesc);
            fmtdesc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
            while (ioctl(fd,VIDIOC_ENUM_FMT,&fmtdesc) == 0)
            {
               if (fmtdesc.pixelformat==V4L2_PIX_FMT_RGB24)
                  hasRgb = true;
               else if (fmtdesc.pixelformat==V4L2_PIX_FMT_YUYV)
                  hasYuyv = true;
               else if (fmtdesc.pixelformat==V4L2_PIX_FMT_MJPEG)
                  hasMjpeg = true;
               fmtdesc.index++;
            }
            if (debug)
               printf("Supported rgb:%d yuyv:%d  mjpeg:%d\n", hasRgb, hasYuyv, hasMjpeg);
            if (!hasRgb)
            {
               if (hasYuyv)
                  reqFormat = V4L2_PIX_FMT_YUYV;
            }
         }

         CLEAR(fmt);
         fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
         if (-1 == xioctl(fd, VIDIOC_G_FMT, &fmt))
               setError("Could not get format");
         else
         {
            fmt.fmt.pix.pixelformat = reqFormat;
            fmt.fmt.pix.width = reqWidth;
            fmt.fmt.pix.height = reqHeight;
            if (xioctl(fd,VIDIOC_S_FMT,&fmt)==0)
            {
               videoFormat = fmt.fmt.pix.pixelformat;
            }
            else
            {
               setError("Could not set format.");
            }
         }

         //printf(" video %dx%d, pix=%08x\n", fmt.fmt.pix.width,  fmt.fmt.pix.height, fmt.fmt.pix.pixelformat );

      }
      else if (0 == cropCapRes)
      {
         crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
         crop.c = cropcap.defrect; /* reset to default */

         if (-1 == xioctl(fd, VIDIOC_S_CROP, &crop, true))
         {
            /* Errors ignored. */
         }


         CLEAR(fmt);

         fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
         if (-1 == xioctl(fd, VIDIOC_G_FMT, &fmt))
               setError("Could not get format");

         if (true)
         {
            fmt.fmt.pix.width       = reqWidth; //replace
            fmt.fmt.pix.height      = reqHeight; //replace
            fmt.fmt.pix.pixelformat = mjpeg ? V4L2_PIX_FMT_MJPEG : V4L2_PIX_FMT_YUYV;

            if (-1 == xioctl(fd, VIDIOC_S_FMT, &fmt))
               setError("Could not set format");
            else if (debug)
               printf("Set video format %dx%d %s ok\n", reqWidth, reqHeight, mjpeg?"MJPEG":"YUY2");
         }

         int pf = fmt.fmt.pix.pixelformat;
         if (pf!=V4L2_PIX_FMT_YUYV && pf!=V4L2_PIX_FMT_MJPEG)
         {
            printf("Unknown pixel format %dx%d : %c%c%c%c\n", fmt.fmt.pix.width, fmt.fmt.pix.height, 
                (pf>>24) & 0xff, (pf>>16) & 0xff, (pf>>8)& 0xff, (pf&0xff) );
         }

         videoFormat = pf;

         /* Buggy driver paranoia. */
         /*
         min = fmt.fmt.pix.width * 2;
         if (fmt.fmt.pix.bytesperline < min)
                fmt.fmt.pix.bytesperline = min;
         min = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
         if (fmt.fmt.pix.sizeimage < min)
                fmt.fmt.pix.sizeimage = min;
         */
      }
      else if (cropCapRes==EINVAL)
      {
         setError("cropCat EINVAL");
      }
      else
      {
         //V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE
         printf("Bad cropCat result %d %08x\n", cropCapRes, cropCapRes);
      }


      struct v4l2_requestbuffers req = {0};
      req.count = 3;
      req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      req.memory = V4L2_MEMORY_MMAP;

      if (-1 == xioctl(fd, VIDIOC_REQBUFS, &req))
         return setError("Could not request buffers\n");

      struct v4l2_buffer buf;
      for(int i=0;i<req.count;i++)
      {
         CLEAR(buf);
         buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
         buf.memory = V4L2_MEMORY_MMAP;
         buf.index = i;

         if(-1 == xioctl(fd, VIDIOC_QUERYBUF, &buf))
            return setError("Querying Buffer");

         if (-1 == xioctl(fd, VIDIOC_QBUF, &buf))
            return setError("Could not queue buffer\n");

         bufferDataLen[i] = buf.length;
         bufferData[i] = mmap(0, buf.length, PROT_READ | PROT_WRITE, MAP_SHARED, fd, buf.m.offset);
      }

      if(-1 == xioctl(fd, VIDIOC_STREAMON, &buf.type))
         return setError("Could not start stream");

      width = fmt.fmt.pix.width;
      height = fmt.fmt.pix.height;
      pixelFormat = pfRGB;
      status = camRunning;

      if (videoFormat==V4L2_PIX_FMT_MJPEG)
      {
         threaded = true;
         if (debug)
            printf("Run MJPeg thread\n");

         HxCreateDetachedThread(sThreadLoop,this);
      }
      else
      {
         if (debug)
            printf("Running main thread\n");
      }

      //printf("running %dx%d!\n", width, height);
      return true;
   }


   static void *sThreadLoop(void *thiz)
   {
      ((V4L *)thiz)->threadLoop();
      return nullptr;
   }


   void lock() { mutex.Lock(); }
   void unlock() {  mutex.Unlock(); }

   // At most one buffer will be good after this ...
   V4LAsyncBuf *getOnlyReadBufferLocked()
   {
      V4LAsyncBuf *best = 0;
      for(int i=0;i<3;i++)
      {
         V4LAsyncBuf *a = asyncBuf+i;
         if (a->state==v4lGood)
         {
            if (best)
            {
               if (best->age<a->age)
               {
                  a->state=v4lUnused;
               }
               else
               {
                  best->state = v4lUnused;
                  best = a;
               }
            }
            else
               best = a;
         }
      }
      return best;
   }

   V4LAsyncBuf *getReadBuffer()
   {
      lock();
      V4LAsyncBuf *best = getOnlyReadBufferLocked();
      if (best)
         best->state = v4lReading;
      unlock();
      return best;
   }

   V4LAsyncBuf *getWriteBuffer()
   {
      V4LAsyncBuf *best = 0;
      lock();
      getOnlyReadBufferLocked();
      for(int i=0;i<3;i++)
      {
         V4LAsyncBuf *a = asyncBuf+i;
         if (a->state==v4lUnused)
         {
            best = a;
            break;
         }
      }
      if (best)
         best->state = v4lWriting;
      else
      {
         printf("Could not find write buffer????\n");
         for(int i=0;i<3;i++)
            printf(" %d] state=%d\n", i, asyncBuf[i].state );
      }
      unlock();
      return best;
   }

   void threadLoop()
   {
      while(keepAlive)
      {
         struct timeval tv;
         int r;

         fd_set fds;
         FD_ZERO(&fds);
         FD_SET(fd, &fds);

         /* Timeout. */
         tv.tv_sec = 0;
         tv.tv_usec = 5000;

         r = select(fd + 1, &fds, NULL, NULL, &tv);
         if (-1 == r)
         {
            if (EINTR != errno)
               setError("Error in select");
         }
         else if (0 == r)
         {
            // ok
         }
         else
         {
            struct v4l2_buffer buf = {0};
            buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
            buf.memory = V4L2_MEMORY_MMAP;

            if(-1 == xioctl(fd, VIDIOC_DQBUF, &buf,true))
            {
               if (errno==EAGAIN)
               {
                  //printf(" - again\n");
               }
               else
                  setError("Retrieving Frame");
            }
            else
            {
               void *data = bufferData[buf.index];

               //double  t0 = GetTimeStamp();
               fillBuffer((const unsigned char *)data,(unsigned int)buf.bytesused);
               //printf("Filled : %.3f\n", GetTimeStamp()-t0);

               if (-1 == xioctl(fd, VIDIOC_QBUF, &buf))
                  setError("Could not requeue buffer");
            }
         }
      }

      threaded = false;
   }


   void onPoll(value handler)
   {
      syncUpdate(handler);

      if (status==camRunning && buffer)
      {
         if (threaded)
         {
            V4LAsyncBuf *async = getReadBuffer();
            if (async)
            {
               const uint8 *src = &async->rgbBuffer[0];
               int srcStride = width*3;

               uint8 *dest = buffer->Edit(0);
               int destStride = buffer->GetStride();

               if (srcStride==destStride)
               {
                  memcpy(dest, src, srcStride*height);
               }
               else
               {
                  for(int y=0;y<height;y++)
                  {
                     memcpy(dest, src, srcStride);
                     dest += destStride;
                     src += srcStride;
                  }
               }
               std::swap(jpegBuffer, async->jpegBuffer);
               async->state = v4lUnused;
               buffer->Commit();

               onFrame(handler);
            }
         }
         else
         {
            struct timeval tv;
            int r;

            fd_set fds;
            FD_ZERO(&fds);
            FD_SET(fd, &fds);

            /* Timeout. */
            tv.tv_sec = 0;
            tv.tv_usec = 1;

            r = select(fd + 1, &fds, NULL, NULL, &tv);
            if (-1 == r)
            {
               if (EINTR != errno)
                  setError("Error in select");
            }
            else if (0 == r)
            {
               // ok
            }
            else
            {
               struct v4l2_buffer buf = {0};
               buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
               buf.memory = V4L2_MEMORY_MMAP;

               if(-1 == xioctl(fd, VIDIOC_DQBUF, &buf,true))
               {
                  if (errno==EAGAIN)
                  {
                     //printf(" - again\n");
                  }
                  else
                     setError("Retrieving Frame");
               }
               else
               {
                  void *data = bufferData[buf.index];

                  //double  t0 = GetTimeStamp();
                  fillBuffer((const unsigned char *)data,(unsigned int)buf.bytesused);
                  //printf("Filled : %.3f\n", GetTimeStamp()-t0);



                  onFrame(handler);

                  if (-1 == xioctl(fd, VIDIOC_QBUF, &buf))
                     setError("Could not requeue buffer");
               }
            }
         }
      }
   }

   inline int clamp(int x) { return (x & 0xffffff00) ? ~(x>>24) : x ; }

   static void sOnI420(void *userData, HwCallbackFrame *inFrame)
   {
      ((V4L *)userData)->onI420(inFrame);
   }

   const unsigned char *setMjpegData(const uint8 *inData, int inLen)
   {
      jpegBuffer.resize(inLen);
      memcpy(&jpegBuffer[0], inData, inLen);
      return &jpegBuffer[0];
   }

   void onI420(HwCallbackFrame *inFrame)
   {
      unsigned char *dest = 0;
      int destStride = 0;
      std::vector<uint8> i420Buffer;
      uint8 *i420Buf = 0;

      int stride = inFrame->width;
      int size = (stride * inFrame->height) * 3 / 2;

      if (currentWriteBuffer)
      {
         dest = &currentWriteBuffer->rgbBuffer[0];
         destStride = width*3;
         currentWriteBuffer->i420Buf.resize(size);
         i420Buf = &currentWriteBuffer->i420Buf[0];
      }
      else
      {
         dest = buffer->Edit(0);
         destStride = buffer->GetStride();
         i420Buffer.resize(size);
         i420Buf = &i420Buffer[0];
      }

      const uint8 *l0 = inFrame->buffer + inFrame->cropY*inFrame->width + inFrame->cropX;
      memcpy(i420Buf, inFrame->buffer, size);
      unsigned char *luma0 = &i420Buf[ inFrame->cropY*stride + inFrame->cropX ];
      unsigned char *u0 = &i420Buf[ inFrame->cropY*stride + inFrame->cropX + stride*height ];
      unsigned char *v0 = &i420Buf[ inFrame->cropY*stride + inFrame->cropX + (stride*height)*5/4 ];

      //printf("ON I420 %dx%d %d  (%dx%d)\n", width, height, stride, inFrame->cropX, inFrame->cropY);

      for(int y=0;y<height;y++)
      {
         const uint8 *lx = luma0;
         const uint8 *ux = u0;
         const uint8 *vx = v0;
         uint8 *rgb = dest;
         for(int x=0;x<width;x+=2)
         {
            int y1 = *lx++;
            int y2 = *lx++;
            int u = *ux++ - 128;
            int v = *vx++ - 128;

            int cr = (v*359) >> 8;
            int cg = (u*88 + v*183) >> 8;
            int cb = (u*454) >> 8;

            *rgb++ = clamp(y1 + cr);
            *rgb++ = clamp(y1 - cg);
            *rgb++ = clamp(y1 + cb);

            *rgb++ = clamp(y2 + cr);
            *rgb++ = clamp(y2 - cg);
            *rgb++ = clamp(y2 + cb);
         }
         luma0+=stride;
         if (y&1)
         {
            u0 += stride>>1;
            v0 += stride>>1;
         }
         dest += destStride;
      }
   }

   void fillBuffer(const unsigned char *inData,unsigned int inByteCount)
   {
     static bool shown = false;
      // ImageBuffer  *buffer;

     int stride = 0;
     unsigned char *dest = 0;

     if (threaded)
     {
        currentWriteBuffer = getWriteBuffer();
        if (!currentWriteBuffer)
           return;
        currentWriteBuffer->rgbBuffer.resize( width*height*3 );
        stride = width*3;
        dest = &currentWriteBuffer->rgbBuffer[0];
     }
     else
     {
        //printf("Fill %p (%dx%d, %d)\n", inData, buffer->Width(), buffer->Height(), buffer->GetStride() );
        stride = buffer->GetStride();
        dest = buffer->Edit(0);
     }


     int pairs = width>>1;
     if (videoFormat==V4L2_PIX_FMT_RGB24)
     {
        memcpy(dest, inData, width * height * 3 );
     }
     else if (videoFormat==V4L2_PIX_FMT_MJPEG)
     {
        std::vector<int> byteHacks;
        if (mjpegBuffers)
        {
           if (threaded)
              inData = currentWriteBuffer->setMjpegData(inData,inByteCount);
           else
              inData = setMjpegData(inData, inByteCount);
        }

        //double t0 = GetTimeStamp();
        #ifdef RASPBERRYPI

        // Hack App0 tag, which can be out-of-spec for decoder ...
        if (inByteCount>4)
        {
           unsigned char *d = (unsigned char *)inData;
           int end = inByteCount-10;
           for(int start = 0;start<end;start++)
           {
              if (d[0]==0xff && d[1]==0xd8 && d[2]==0xff && d[3]==0xe0 && d[6]=='A' && d[7]=='V')
              {
                 if (mjpegBuffers)
                    byteHacks.push_back(start+3);
                 //printf("Hack app0 -> app4\n");

                 d[3] =  0xe4;
              }
              d++;
           }
        }

        if (!RpiHardwareDecodeJPeg( sOnI420, this, (const uint8*)inData, inByteCount) )
        {
           printf("hardware failed - use software\n");
           //FILE *f = fopen("dump.jpeg","wb");
           //fwrite(inData, inByteCount, 1, f);
           //fclose(f);
           SoftwareDecodeJPeg( (uint8*)dest, width, height, (const uint8*)inData, inByteCount);
        }
        else
        {
           static bool shown = false;
           if (!shown)
           {
              printf("Using hardware decode\n");
              shown = true;
           }
        }
        unsigned char *d = (unsigned char *)inData;
        for(int i : byteHacks)
           d[i] = 0xe0;

        #else 
        SoftwareDecodeJPeg( (uint8*)dest, width, height, (const uint8*)inData, inByteCount);
        #endif

        //double t = GetTimeStamp()-t0;
        //printf(" decode time: %.2fms\n", t*1000);
     }
     else
        for(int y=0;y<height;y++)
        {
            const unsigned char *s = (unsigned char *)inData + y*width*2;
            unsigned char *rgb =  dest + y*stride;

            if (videoFormat==V4L2_PIX_FMT_YUYV)
            {
               for(int x=0;x<pairs;x++)
               {
                  int y1 = s[0];
                  int u  = s[1]-128;
                  int y2 = s[2];
                  int v  = s[3]-128;

                  int cr = (v*359) >> 8;
                  int cg = (u*88 + v*183) >> 8;
                  int cb = (u*454) >> 8;

                  *rgb++ = clamp(y1 + cr);
                  *rgb++ = clamp(y1 - cg);
                  *rgb++ = clamp(y1 + cb);

                  *rgb++ = clamp(y2 + cr);
                  *rgb++ = clamp(y2 - cg);
                  *rgb++ = clamp(y2 + cb);

                  s+=4;
               }
            }
            else
            {
               if (!shown)
               {
                  printf("fillBuffer - Unknown frame format %dx%d : %08x (yuv=%08x rgb=%08x)\n", width, height,
                          videoFormat, V4L2_PIX_FMT_YUYV,V4L2_PIX_FMT_RGB24);
                  shown = true;
               }
            }
         }

      if (threaded)
      {
         currentWriteBuffer->age = 0;
         for(int i=0;i<3;i++)
            if (&asyncBuf[i]!=currentWriteBuffer)
               asyncBuf[i].age++;
         currentWriteBuffer->state = v4lGood;
         currentWriteBuffer = 0;
      }
      else
      {
         buffer->Commit();
      }
   }

   int getJpegSize()
   {
      return (int)jpegBuffer.size();
   }
   const unsigned char *getJpegData()
   {
      return jpegBuffer.size() ? &jpegBuffer[0] : nullptr;
   }

};


Camera *CreateCamera(const char *inName)
{
   return new V4L(inName);
}


} // end namespace nme

