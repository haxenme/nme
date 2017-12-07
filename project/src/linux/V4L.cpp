#include <vector>

#include <Camera.h>
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


class V4L : public Camera
{
   HxMutex mutex;
   bool ok;
   int  fd;
   struct v4l2_format fmt;
   void *bufferData[3];
   int   bufferDataLen[3];
   bool streamOn;
   int   videoFormat;

public:
   V4L(const char *inName)
   {
      //printf("V4L %s\n", inName);
      if (!inName || !inName[0] || !strcmp(inName,"default"))
         inName = "/dev/video0";

      streamOn = false;
      for(int i=0;i<3;i++)
         bufferData[i] = 0;

      fd = -1;
      videoFormat = 0;
      openDevice(inName);
      initDevice();
   }


   ~V4L()
   {
      if (streamOn)
      {
         int type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
         if (-1 == xioctl(fd, VIDIOC_STREAMOFF, &type))
         {
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
         printf("xioctl error %s\n", strerror(errno) );
      return r;
   }


   bool initDevice(void)
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

      CLEAR(cropcap);

      cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

      if (0 == xioctl(fd, VIDIOC_CROPCAP, &cropcap))
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
            fmt.fmt.pix.width       = 640; //replace
            fmt.fmt.pix.height      = 480; //replace
            fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;

            if (-1 == xioctl(fd, VIDIOC_S_FMT, &fmt))
               setError("Could not set format");
         }

         int pf = fmt.fmt.pix.pixelformat;
         if (pf!=V4L2_PIX_FMT_YUYV)
         {
            printf("Unknown pixel format %dx%d : %c%c%c%c\n", fmt.fmt.pix.width, fmt.fmt.pix.height, 
                (pf>>24) & 0xff, (pf>>16) & 0xff, (pf>>8)& 0xff, (pf&0xff) );
         }

         videoFormat = pf;

         /* Buggy driver paranoia. */
         min = fmt.fmt.pix.width * 2;
         if (fmt.fmt.pix.bytesperline < min)
                fmt.fmt.pix.bytesperline = min;
         min = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
         if (fmt.fmt.pix.sizeimage < min)
                fmt.fmt.pix.sizeimage = min;
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
   }


   void lock() { mutex.Lock(); }
   void unlock() {  mutex.Unlock(); }

   void onPoll(value handler)
   {
      syncUpdate(handler);

      if (status==camRunning && buffer)
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
                  printf(" - again\n");
               else
                  setError("Retrieving Frame");
            }
            else
            {
               void *data = bufferData[buf.index];

               fillBuffer(data);

               onFrame(handler);

               if (-1 == xioctl(fd, VIDIOC_QBUF, &buf))
                  setError("Could not requeue buffer");
            }
         }
      }
   }

   inline int clamp(int x) { return (x & 0xffffff00) ? ~(x>>24) : x ; }

   void fillBuffer(const void *inData)
   {
      // ImageBuffer  *buffer;

     //printf("Fill %p (%dx%d, %d)\n", inData, buffer->Width(), buffer->Height(), buffer->GetStride() );
     int stride = buffer->GetStride();
     unsigned char *dest = buffer->Edit(0);

     int pairs = width>>1;
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
      }
      buffer->Commit();
   }

};


Camera *CreateCamera(const char *inName)
{
   return new V4L(inName);
}


} // end namespace nme

