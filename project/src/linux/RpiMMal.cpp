/*
Copyright (c) 2018 Raspberry Pi (Trading) Ltd

Decodes a JPEG image into a memory buffer.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the copyright holder nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <poll.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdexcept>
#include <vector>
#include <string.h>

#include <Surface.h>

//#include <interface/vcsm/user-vcsm.h>
#include "bcm_host.h"
#include "interface/mmal/mmal.h"
#include "interface/mmal/util/mmal_default_components.h"
#include "interface/mmal/util/mmal_util_params.h"
#include "interface/mmal/util/mmal_util.h"
#include "interface/mmal/util/mmal_connection.h"
#include "interface/mmal/mmal_queue.h"
#include "interface/vcos/vcos.h"

#include "interface/mmal/vc/mmal_vc_api.h"


using namespace nme;

#define MAX_BUFFERS 2



static void log_format(MMAL_ES_FORMAT_T *format, MMAL_PORT_T *port)
{
   fprintf(stderr,"log_format:\n");
   const char *name_type;

   if(port)
      fprintf(stderr, "%s:%s:%i", port->component->name,
               port->type == MMAL_PORT_TYPE_CONTROL ? "ctr" :
                  port->type == MMAL_PORT_TYPE_INPUT ? "in" :
                  port->type == MMAL_PORT_TYPE_OUTPUT ? "out" : "invalid",
               (int)port->index);

   switch(format->type)
   {
   case MMAL_ES_TYPE_AUDIO: name_type = "audio"; break;
   case MMAL_ES_TYPE_VIDEO: name_type = "video"; break;
   case MMAL_ES_TYPE_SUBPICTURE: name_type = "subpicture"; break;
   default: name_type = "unknown"; break;
   }

   fprintf(stderr, "type: %s, fourcc: %4.4s\n", name_type, (char *)&format->encoding);
   fprintf(stderr, " bitrate: %i, framed: %i\n", format->bitrate,
            !!(format->flags & MMAL_ES_FORMAT_FLAG_FRAMED));
   fprintf(stderr, " extra data: %i, %p\n", format->extradata_size, format->extradata);
   switch(format->type)
   {
   case MMAL_ES_TYPE_AUDIO:
      fprintf(stderr, " samplerate: %i, channels: %i, bps: %i, block align: %i\n",
               format->es->audio.sample_rate, format->es->audio.channels,
               format->es->audio.bits_per_sample, format->es->audio.block_align);
      break;

   case MMAL_ES_TYPE_VIDEO:
      fprintf(stderr, " width: %i, height: %i, (%i,%i,%i,%i)\n",
               format->es->video.width, format->es->video.height,
               format->es->video.crop.x, format->es->video.crop.y,
               format->es->video.crop.width, format->es->video.crop.height);
      fprintf(stderr, " pixel aspect ratio: %i/%i, frame rate: %i/%i\n",
               format->es->video.par.num, format->es->video.par.den,
               format->es->video.frame_rate.num, format->es->video.frame_rate.den);
      break;

   case MMAL_ES_TYPE_SUBPICTURE:
      break;

   default: break;
   }

   if(!port)
      return;

   fprintf(stderr, " buffers num: %i(opt %i, min %i), size: %i(opt %i, min: %i), align: %i\n",
            port->buffer_num, port->buffer_num_recommended, port->buffer_num_min,
            port->buffer_size, port->buffer_size_recommended, port->buffer_size_min,
            port->buffer_alignment_min);
}




static bool isInit = false;
static MMAL_STATUS_T initStatus;
static MMAL_STATUS_T doInit()

{
   if (!isInit)
   {
      isInit = true;

      bcm_host_init();

      initStatus = mmal_vc_init();
   }

   return initStatus;
}

namespace nme
{
class MMalDecoder
{
   bool cleanSem;
   bool debug;
   VCOS_SEMAPHORE_T semaphore;
   MMAL_QUEUE_T *queue;
   MMAL_COMPONENT_T *decoder;
   MMAL_POOL_T *pool_in;
   MMAL_POOL_T *pool_out;
   unsigned int in_count;
   MMAL_BUFFER_HEADER_T *buffer;
   MMAL_STATUS_T status;
   MMAL_VIDEO_FORMAT_T bufferFormat;
   bool firstRun;

public:
   MMalDecoder(bool inDebug)
   {
      cleanSem = false;
      in_count = 0;
      queue = nullptr;
      decoder = nullptr;
      pool_in = nullptr;
      pool_out = nullptr;
      buffer = nullptr;
      status = MMAL_SUCCESS;
      debug = inDebug;
      firstRun = true;
      memset(&bufferFormat,0,sizeof(bufferFormat));

      checkStatus(doInit(), "error initializing");

      if (ok())
      {
         vcos_semaphore_create(&semaphore, "MMalDecoder", 1);
         cleanSem = true;
         checkStatus(  mmal_component_create(MMAL_COMPONENT_DEFAULT_IMAGE_DECODER, &decoder),
            "Could not create mmal decoder");
      }

      if (ok())
      {
         /* Create the decoder component.
          * This specific component exposes 2 ports (1 input and 1 output). Like most components
          * its expects the format of its input port to be set by the client in order for it to
          * know what kind of data it will be fed. */
         /* Enable control port so we can receive events from the component */
         decoder->control->userdata = (MMAL_PORT_USERDATA_T *)this;
         checkStatus( mmal_port_enable(decoder->control, control_callback),
                        "failed to enable control port");
      }

      if (false && ok())
      {
         /* Set the zero-copy parameter on the input port */
         checkStatus(  mmal_port_parameter_set_boolean(decoder->input[0],
                     MMAL_PARAMETER_ZERO_COPY, MMAL_TRUE),
            "failed to set zero copy input" );
      }

      if (ok())
      {
         /* Set the zero-copy parameter on the output port */
         checkStatus( mmal_port_parameter_set_boolean(decoder->output[0],
                     MMAL_PARAMETER_ZERO_COPY, MMAL_TRUE),
            "failed to set zero copy output");
      }

      if (ok())
      {
         /* Set format of video decoder input port */
         MMAL_ES_FORMAT_T *format_in = decoder->input[0]->format;
         format_in->type = MMAL_ES_TYPE_VIDEO;
         format_in->encoding = MMAL_ENCODING_JPEG;
         format_in->es->video.width = 0;
         format_in->es->video.height = 0;
         format_in->es->video.frame_rate.num = 0;
         format_in->es->video.frame_rate.den = 1;
         format_in->es->video.par.num = 1;
         format_in->es->video.par.den = 1;

         checkStatus(mmal_port_format_commit(decoder->input[0]),
                     "failed to commit format");
      }

      if (ok())
      {
         MMAL_ES_FORMAT_T *format_out = decoder->output[0]->format;
         format_out->encoding = MMAL_ENCODING_I420;

         checkStatus( mmal_port_format_commit(decoder->output[0]), "failed to commit format");

         if (ok())
         {
            bufferFormat = format_out->es->video;
            if (debug)
            {
               /* Display the output port format */
               fprintf(stderr, "%s\n", decoder->output[0]->name);
               fprintf(stderr, " type: %i, fourcc: %4.4s\n", format_out->type, (char *)&format_out->encoding);
               fprintf(stderr, " bitrate: %i, framed: %i\n", format_out->bitrate,
                    !!(format_out->flags & MMAL_ES_FORMAT_FLAG_FRAMED));
               fprintf(stderr, " extra data: %i, %p\n", format_out->extradata_size, format_out->extradata);
               fprintf(stderr, " width: %i, height: %i, (%i,%i,%i,%i)\n",
                    format_out->es->video.width, format_out->es->video.height,
                    format_out->es->video.crop.x, format_out->es->video.crop.y,
                    format_out->es->video.crop.width, format_out->es->video.crop.height);
            }
         }
      }

      if (ok())
      {
         /* The format of both ports is now set so we can get their buffer requirements and create
          * our buffer headers. We use the buffer pool API to create these. */
         decoder->input[0]->buffer_num = decoder->input[0]->buffer_num_recommended;
         decoder->input[0]->buffer_size = decoder->input[0]->buffer_size_recommended;
         decoder->output[0]->buffer_num = decoder->output[0]->buffer_num_recommended;
         decoder->output[0]->buffer_size = decoder->output[0]->buffer_size_recommended;
         pool_in = mmal_port_pool_create(decoder->input[0],
                                         decoder->input[0]->buffer_num,
                                         decoder->input[0]->buffer_size);

         /* Create a queue to store our decoded frame(s). The callback we will get when
          * a frame has been decoded will put the frame into this queue. */
         queue = mmal_queue_create();

         /* Store a reference to our context in each port (will be used during callbacks) */
         decoder->input[0]->userdata = (MMAL_PORT_USERDATA_T *)this;
         decoder->output[0]->userdata = (MMAL_PORT_USERDATA_T *)this;

         /* Enable all the input port and the output port.
          * The callback specified here is the function which will be called when the buffer header
          * we sent to the component has been processed. */
         checkStatus( mmal_port_enable(decoder->input[0], input_callback), "failed to enable input port");
      }
      if (ok())
      {
         checkStatus( mmal_port_enable(decoder->output[0], output_callback),"failed to enable output port");
      }

      if (ok())
      {
          pool_out = mmal_port_pool_create(decoder->output[0],
                             decoder->output[0]->buffer_num,
                             decoder->output[0]->buffer_size);
      }

      while(ok() && (buffer = mmal_queue_get(pool_out->queue)) != NULL)
      {
         //printf("Sending buf %p\n", buffer);
         checkStatus( mmal_port_send_buffer(decoder->output[0], buffer),
                      "failed to send output buffer to decoder");
      }

      if (ok())
      {
         /* Component won't start processing data until it is enabled. */
         checkStatus(mmal_component_enable(decoder), "failed to enable decoder component");
      }
   }

   ~MMalDecoder()
   {
      if (cleanSem)
         vcos_semaphore_delete(&semaphore);
      if (pool_in)
      {
         mmal_port_disable(decoder->input[0]);
         mmal_port_pool_destroy(decoder->input[0], pool_in);
      }
      if (pool_out)
      {
         mmal_port_disable(decoder->output[0]);
         mmal_port_pool_destroy(decoder->output[0], pool_out);
      }
      if (decoder)
         mmal_component_destroy(decoder);
      if (queue)
         mmal_queue_destroy(queue);
   }

   bool ok() const { return status==MMAL_SUCCESS; }

   void checkStatus(MMAL_STATUS_T inStatus, const char *inErr)
   {
      status = inStatus;
      if (!ok())
         fprintf(stderr,"Error : %s\n", inErr);
   }

   bool decodeBytes(I420Callback inCallback, void *inUserData, const unsigned char *data, unsigned int dataSize)
   {
      if (!decoder)
         return false;

      bool eos_sent = false;
      bool eos_received = false;
      bool frameDecoded = false;

      int loops = 0;
      /* This is the main processing loop */
      while(ok() && !eos_received)
      {
         /* Wait for buffer headers to be available on either of the decoder ports */
         /* First run - wait for port setup? */
         if (loops>0 || firstRun)
         {
            firstRun = false;
            VCOS_STATUS_T vcos_status = vcos_semaphore_wait_timeout(&semaphore, 1000);
            if (vcos_status != VCOS_SUCCESS)
            {
               fprintf(stderr, "vcos_semaphore_wait_timeout failed - status %d\n", vcos_status);
               loops++;
               if (loops>3)
                  break;
            }
         }
         else
            loops++;

         /* Check for errors - set in callbacks*/
         if (!ok())
            break;

         /* Send data to decode to the input port of the video decoder */
         if (!eos_sent)
         {
            if ((buffer = mmal_queue_get(pool_in->queue)) != NULL)
            {
               unsigned int bytes = std::min(buffer->alloc_size - 128, dataSize);
               buffer->length = bytes;
               buffer->offset = 0;
               memcpy(buffer->data, data, bytes);
               dataSize -= bytes;
               data += bytes;

               if(bytes==0)
                  eos_sent = true;

               buffer->flags = buffer->length ? 0 : MMAL_BUFFER_HEADER_FLAG_EOS;
               buffer->pts = buffer->dts = MMAL_TIME_UNKNOWN;
               if (debug)
                  fprintf(stderr, "sending %i bytes\n", (int)buffer->length);
               checkStatus(mmal_port_send_buffer(decoder->input[0], buffer),"failed to send buffer");
               in_count++;
               if (debug)
                  fprintf(stderr, "Input buffer %p to port %s. in_count %u\n", buffer, decoder->input[0]->name, in_count);
            }
            else
            {
               if (debug)
                  fprintf(stderr,"No input buffer ready\n");
            }
         }

         /* Get our output frames */
         while (!eos_received && ok() && (buffer = mmal_queue_get(queue)) != NULL)
         {
            /* We have a frame, do something with it (why not display it for instance?).
             * Once we're done with it, we release it. It will automatically go back
             * to its original pool so it can be reused for a new video frame.
             */
            eos_received = buffer->flags & MMAL_BUFFER_HEADER_FLAG_EOS;
            if (debug)
               fprintf(stderr,"DQ ==== Buffer %p %d\n", buffer, eos_received);

            if (buffer->cmd)
            {
               if (debug)
                  fprintf(stderr, "received event length %d, %4.4s\n", buffer->length, (char *)&buffer->cmd);
               if (buffer->cmd == MMAL_EVENT_FORMAT_CHANGED)
               {
                  MMAL_EVENT_FORMAT_CHANGED_T *event = mmal_event_format_changed_get(buffer);
                  if (event)
                      bufferFormat = event->format->es->video;
                  if (debug && event)
                  {
                     fprintf(stderr, "----------Port format changed----------\n");
                     log_format(decoder->output[0]->format, decoder->output[0]);
                     fprintf(stderr, "-----------------to---------------------\n");
                     log_format(event->format, 0);
                     fprintf(stderr, " buffers num (opt %i, min %i), size (opt %i, min: %i)\n",
                              event->buffer_num_recommended, event->buffer_num_min,
                              event->buffer_size_recommended, event->buffer_size_min);
                     fprintf(stderr, "----------------------------------------\n");
                  }
                  mmal_buffer_header_release(buffer);
                  mmal_port_disable(decoder->output[0]);

                  //Clear out the queue and release the buffers.
                  while(mmal_queue_length(pool_out->queue) < pool_out->headers_num)
                  {
                     buffer = mmal_queue_wait(queue);
                     mmal_buffer_header_release(buffer);
                  }

                  //Assume we can't reuse the output buffers, so have to disable, destroy
                  //pool, create new pool, enable port, feed in buffers.
                  mmal_port_pool_destroy(decoder->output[0], pool_out);

                  status = mmal_format_full_copy(decoder->output[0]->format, event->format);
                  decoder->output[0]->format->encoding = MMAL_ENCODING_I420;
                  decoder->output[0]->buffer_num = MAX_BUFFERS;
                  decoder->output[0]->buffer_size = decoder->output[0]->buffer_size_recommended;

                  if (status == MMAL_SUCCESS)
                     status = mmal_port_format_commit(decoder->output[0]);
                  if (status != MMAL_SUCCESS && debug)
                  {
                     fprintf(stderr, "commit failed on output - %d\n", status);
                  }

                  mmal_port_enable(decoder->output[0], output_callback);
                  pool_out = mmal_port_pool_create(decoder->output[0], decoder->output[0]->buffer_num, decoder->output[0]->buffer_size);
                  if (debug)
                     fprintf(stderr,"Re-enable output port.\n");
               }
               else
               {
                  if (debug)
                     fprintf(stderr,"Ignore command %d\n", buffer->cmd );
                  mmal_buffer_header_release(buffer);
               }
            }
            else
            {
               if (debug)
                  fprintf(stderr, "decoded frame (flags %x, size %d)\n", buffer->flags, buffer->length);

               HwCallbackFrame frame;
               frame.buffer = buffer->data;
               frame.bufferLength = buffer->length;

               frame.width = bufferFormat.width;
               frame.height = bufferFormat.height;
               frame.cropX = bufferFormat.crop.x;
               frame.cropY = bufferFormat.crop.y;
               frame.cropW = bufferFormat.crop.width;
               frame.cropH = bufferFormat.crop.height;

               inCallback(inUserData, &frame);

               mmal_buffer_header_release(buffer);

               frameDecoded = true;
            }
         }

         /* Send empty buffers to the output port of the decoder */
         while ((buffer = mmal_queue_get(pool_out->queue)) != NULL)
         {
            status = mmal_port_send_buffer(decoder->output[0], buffer);
            checkStatus(status, "failed to send output buffer to decoder");
         }
      }


      return frameDecoded;
   }



   /** Callback from the control port.
    * Component is sending us an event. */
   static void control_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
   {
      MMalDecoder *ctx = (MMalDecoder *)port->userdata;
      char fcc[5] = "";
      *(int *)fcc = buffer->cmd;
      //if (ctx->debug)
         fprintf(stderr,"CONTROL -> %s\n",fcc);

      switch (buffer->cmd)
      {
      case MMAL_EVENT_EOS:
         /* Only sink component generate EOS events */
         break;
      case MMAL_EVENT_ERROR:
         /* Something went wrong. Signal this to the application */
         ctx->status = *(MMAL_STATUS_T *)buffer->data;
         break;
      default:
         break;
      }

      /* Done with the event, recycle it */
      mmal_buffer_header_release(buffer);

      /* Kick the processing thread */
      vcos_semaphore_post(&ctx->semaphore);
   }



   /** Callback from the input port.
    * Buffer has been consumed and is available to be used again. */
   static void input_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
   {
      MMalDecoder *ctx = (MMalDecoder *)port->userdata;

      /* The decoder is done with the data, just recycle the buffer header into its pool */
      mmal_buffer_header_release(buffer);

      /* Kick the processing thread */
      vcos_semaphore_post(&ctx->semaphore);
   }

   /** Callback from the output port.
    * Buffer has been produced by the port and is available for processing. */
   static void output_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
   {
      MMalDecoder *ctx = (MMalDecoder *)port->userdata;

      /* Queue the decoded video frame */
      mmal_queue_put(ctx->queue, buffer);

      /* Kick the processing thread */
      vcos_semaphore_post(&ctx->semaphore);
   }

};
}

namespace nme
{

static int triedAndFailed = 0;
static MMalDecoder *sDecoder = nullptr;

bool RpiHardwareDecodeJPeg(I420Callback inCallback, void *inUserData, const uint8 *inData, unsigned int inDataLen)
{
   if (triedAndFailed>10)
      return false;

   if (!sDecoder)
   {
      sDecoder = new MMalDecoder(false);
      if (!sDecoder->ok())
      {
         triedAndFailed++;
         delete sDecoder;
         sDecoder = 0;
      }
   }

   if (!sDecoder)
      return false;


   // Destroy and try again?
   bool ok =  sDecoder->decodeBytes(inCallback, inUserData, inData,inDataLen);

   if (!ok)
   {
      delete sDecoder;
      sDecoder = 0;
      triedAndFailed++;
      printf("try again..\n");
   }
   else
   {
      triedAndFailed = 0;
   }

   return ok;
}


}

/*
int main(int argc, char **argv)
{
   FILE *source_file = fopen(argv[1], "rb");
   if (!source_file)
      throw std::runtime_error( "Could not open:" + std::string(argv[1]));

   std::vector<unsigned char> buffer;
   fseek(source_file, 0, SEEK_END);
   size_t size = ftell(source_file);
   fseek(source_file, 0, SEEK_SET);
   buffer.resize(size);
   int got = (int)fread( &buffer[0], size, 1, source_file );
   fclose(source_file);
   fprintf(stderr,"source bytes %d/%d\n", (int)size,got);

   MMalDecoder decoder(true);
   for(int i=0;i<1;i++)
       decoder.decodeBytes(0,0,0,&buffer[0], (unsigned int)size );
   fprintf(stderr,"bye.\n");

}
*/


