#import <AVFoundation/AVFoundation.h>
#include <Camera.h>
#include <pthread.h>

#ifdef IPHONE
 #if (__IPHONE_OS_VERSION_MIN_REQUIRED >=110000)
    #define HAS_DEPTH_CAM
 #endif
#endif

using namespace nme;

namespace nme { class AppleCamera; }


@interface FrameRelay : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate
   #ifdef HAS_DEPTH_CAM
    , AVCaptureDataOutputSynchronizerDelegate
   #endif
>
{
   AppleCamera *mCamera;
}

- (id) initWithCamera:(AppleCamera*)camera;


- (void)captureOutput:(AVCaptureOutput *)captureOutput 
   didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
   fromConnection:(AVCaptureConnection *)connection;

#ifdef HAS_DEPTH_CAM
- (void)dataOutputSynchronizer:(AVCaptureDataOutputSynchronizer *)synchronizer 
didOutputSynchronizedDataCollection:(AVCaptureSynchronizedDataCollection *)synchronizedDataCollection;
#endif

@end



namespace nme
{


class AppleCamera : public Camera
{
   AVCaptureSession *mSession;
   pthread_mutex_t mMutex;


public:
   AVCaptureVideoDataOutput *output;
   #ifdef HAS_DEPTH_CAM
   AVCaptureDepthDataOutput *depthDataOutput;
   #endif

   AppleCamera(const char *inName)
   {
      pthread_mutexattr_t mta;
      pthread_mutexattr_init(&mta);
      pthread_mutexattr_settype(&mta, PTHREAD_MUTEX_RECURSIVE);
      pthread_mutex_init(&mMutex,&mta);


      NSError *error = nil;

      std::string spec(inName);


   //NSLog(@"Devices: %@", disc.devices);


    // Create the session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];


    AVCaptureDevice *device = nil;
    #ifdef HAS_DEPTH_CAM
    bool wantsDepth = false;
    #endif

    if (@available(macOS 10.15, *))
    {
       AVCaptureDevicePosition pos = AVCaptureDevicePositionUnspecified;
       if ( spec.find("front")!=std::string::npos)
          pos = AVCaptureDevicePositionFront;
       else if ( spec.find("back")!=std::string::npos)
          pos = AVCaptureDevicePositionBack;


       AVCaptureDeviceType deviceType =  AVCaptureDeviceTypeBuiltInWideAngleCamera;

       #ifdef HAS_DEPTH_CAM
       if (spec.find("truedepth")!=std::string::npos)
       {
           deviceType = AVCaptureDeviceTypeBuiltInTrueDepthCamera;
           wantsDepth = true;
       }
       #endif

    
       device = [AVCaptureDevice
               defaultDeviceWithDeviceType:deviceType 
               mediaType: AVMediaTypeVideo 
               position: pos ];
    }
    else
    {
       device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }



    // Configure the session to produce lower resolution video frames, if your 
    // processing algorithm can cope. We'll specify medium quality for the
    // chosen device.
    if ( spec.find("medium")!=std::string::npos)
       session.sessionPreset = AVCaptureSessionPresetMedium;
    else if ( spec.find("low")!=std::string::npos)
       session.sessionPreset = AVCaptureSessionPresetLow;
    else if ( spec.find("high")!=std::string::npos)
       session.sessionPreset = AVCaptureSessionPresetHigh;
    else if ( spec.find("480p")!=std::string::npos)
       session.sessionPreset = AVCaptureSessionPreset640x480;
    else if ( spec.find("720p")!=std::string::npos)
       session.sessionPreset = AVCaptureSessionPreset1280x720;
    else if ( spec.find("1080p")!=std::string::npos)
    {
       if (@available(macOS 10.15, *)) {
          if ([device supportsAVCaptureSessionPreset:AVCaptureSessionPreset1920x1080])
             session.sessionPreset = AVCaptureSessionPreset1920x1080;
          else
             session.sessionPreset = AVCaptureSessionPresetHigh;
       } else {
          session.sessionPreset = AVCaptureSessionPresetHigh;
       }
    }


    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device 
                                                                    error:&error];
    if (!input)
    {
        NSLog(@"PANIC: no media input");
    }
    [session addInput:input];

    // Create a VideoDataOutput and add it to the session
    output = [[AVCaptureVideoDataOutput alloc] init];
    [session addOutput:output];

    #ifdef HAS_DEPTH_CAM
    //printf("wantsDepth: %d\n", wantsDepth);
    if (wantsDepth)
    {
       depthDataOutput = [[AVCaptureDepthDataOutput alloc] init];
       [session addOutput:depthDataOutput];
       [depthDataOutput setFilteringEnabled:false];
       //depthDataOutput.isFilteringEnabled = NO;
       auto connection = [depthDataOutput connectionWithMediaType:AVMediaTypeDepthData];
       //connection.videoOrientation = AVCaptureVideoOrientationPortrait;


       int bestWidth = 0;
       AVCaptureDeviceFormat *bestDepth = 0;
       for(AVCaptureDeviceFormat *fmt in device.activeFormat.supportedDepthDataFormats)
       {
          //NSLog(@" format: %@\n", fmt);
          if (CMFormatDescriptionGetMediaSubType(fmt.formatDescription) == kCVPixelFormatType_DepthFloat16)
          {
             auto dim = CMVideoFormatDescriptionGetDimensions(fmt.formatDescription);
             if (dim.width>bestWidth)
             {
                bestWidth = dim.width;
                bestDepth = fmt;
             }
          }
       }
       //NSLog(@"Found best depth %@\n",bestDepth);
       if (bestDepth)
       {
          NSError* error = nil;
          [device lockForConfiguration:&error];
          device.activeDepthDataFormat = bestDepth;
          [device unlockForConfiguration];
       }
    }
    #endif

    // Specify the pixel format
    output.videoSettings = @{
      (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
    };


    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    FrameRelay *relay = [[FrameRelay alloc] initWithCamera:this];

    #ifdef HAS_DEPTH_CAM
     // Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
    // The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
    if (wantsDepth)
    {
       AVCaptureDataOutputSynchronizer *outputSynchronizer = [
        [AVCaptureDataOutputSynchronizer alloc]
           initWithDataOutputs: @[ output, depthDataOutput] ];

       [outputSynchronizer setDelegate:relay queue:queue];
    }
    else
    {
       [output setSampleBufferDelegate:relay queue:queue];
    }
    #else
    [output setSampleBufferDelegate:relay queue:queue];
    #endif


    // If you wish to cap the frame rate to a known value, such as 15 fps, set 
    // minFrameDuration.

    // Start the session running to start the flow of data
    [session startRunning];

    //[device unlockForConfiguration];
    mSession = session;
  }

   ~AppleCamera()
   {
      pthread_mutex_destroy(&mMutex);
   }

   void lock()
   {
      pthread_mutex_lock(&mMutex); 
   }

   void unlock()
   {
      pthread_mutex_unlock(&mMutex); 
   }

   void copyFrame(ImageBuffer *outBuffer, FrameBuffer *inFrame)
   {
      int n = inFrame->width * inFrame->height;
      unsigned char *src = &inFrame->data[0];
      unsigned char *dest = outBuffer->Edit(0);
      memcpy(dest,src,n*4);
      outBuffer->Commit();
   }



   void onFrame(CMSampleBufferRef inSample, CVPixelBufferRef *inDepth=0)
   {
      FrameBuffer *frameBuffer = getWriteBuffer();

      if (inDepth)
      {
         // Lock the base address of the pixel buffer
         CVPixelBufferLockBaseAddress(*inDepth, 0); 

         // Get the number of bytes per row for the pixel buffer
         void *baseAddress = CVPixelBufferGetBaseAddress(*inDepth); 

         // Get the number of bytes per row for the pixel buffer
         size_t bytesPerRow = CVPixelBufferGetBytesPerRow(*inDepth); 
         // Get the pixel buffer width and height
         int width = CVPixelBufferGetWidth(*inDepth); 
         int height = CVPixelBufferGetHeight(*inDepth); 

         if (width && height)
         {
            frameBuffer->depth.resize(width*height);
            frameBuffer->depthWidth = width;
            frameBuffer->depthHeight = height;

            //printf("Got depth frame w=%d h=%d %lu\n", width, height, bytesPerRow);

            for(int y=0;y<height;y++)
               memcpy( frameBuffer->depthRow(y), (char *)baseAddress + y*bytesPerRow, width*4 );
          }
          CVPixelBufferUnlockBaseAddress(*inDepth,0);
      }

      // Get a CMSampleBuffer's Core Video image buffer for the media data
      CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(inSample); 
      // Lock the base address of the pixel buffer
      CVPixelBufferLockBaseAddress(imageBuffer, 0); 

      // Get the number of bytes per row for the pixel buffer
      void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer); 

      // Get the number of bytes per row for the pixel buffer
      size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
      // Get the pixel buffer width and height
      width = CVPixelBufferGetWidth(imageBuffer); 
      height = CVPixelBufferGetHeight(imageBuffer); 

      frameBuffer->data.resize(width*height*4);
      frameBuffer->width = width;
      frameBuffer->height = height;
      frameBuffer->stride = width*4;


      for(int y=0;y<height;y++)
         memcpy( frameBuffer->row(y), (char *)baseAddress + y*bytesPerRow, width*4 );

      CVPixelBufferUnlockBaseAddress(imageBuffer,0);

      frameBuffer->age = frameId++;
      if (width && height)
         status = camRunning;
   }

};


Camera *CreateCamera(const char *inName)
{
   return new AppleCamera(inName);
}


} // end namespace nme



@implementation FrameRelay

- (id) initWithCamera:(AppleCamera*)camera
{
  self = [super init];
  mCamera = camera;
  return self;
}


// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
   didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
   fromConnection:(AVCaptureConnection *)connection
{ 
     connection.videoOrientation = AVCaptureVideoOrientationPortrait;

    //NSLog(@"captureOutput: didOutputSampleBufferFromConnection");
    mCamera->onFrame( sampleBuffer );
}

#ifdef HAS_DEPTH_CAM
- (void)dataOutputSynchronizer:(AVCaptureDataOutputSynchronizer *)synchronizer 
didOutputSynchronizedDataCollection:(AVCaptureSynchronizedDataCollection *)synchronizedDataCollection
{
   AVCaptureSynchronizedSampleBufferData *syncedVideoData = synchronizedDataCollection[ mCamera->output];
   AVCaptureSynchronizedDepthData *syncedDepthData = synchronizedDataCollection[ mCamera->depthDataOutput];

   if (syncedDepthData.depthDataWasDropped || syncedVideoData.sampleBufferWasDropped)
      return;
   AVDepthData *depthData = [syncedDepthData.depthData depthDataByConvertingToDepthDataType:kCVPixelFormatType_DepthFloat32];
   CVPixelBufferRef depthPixelBuffer = depthData.depthDataMap;

   OSType t = CVPixelBufferGetPixelFormatType(depthPixelBuffer);
   const char *p = (const char *)&t;

   auto sampleBuffer = syncedVideoData.sampleBuffer;

   mCamera->onFrame( sampleBuffer, &depthPixelBuffer );
}
#endif

@end



