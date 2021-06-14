#import <Cocoa/Cocoa.h>
#import <AvFoundation/AvFoundation.h>
#include "Audio.h"


@interface NSDataAssetResourceLoaderDelegate : NSObject <AVAssetResourceLoaderDelegate>
@property (retain) NSData *data;
@property (retain) NSString *contentType;

- (instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType;
@end

@implementation NSDataAssetResourceLoaderDelegate

- (instancetype)initWithData:(NSData *)data contentType:(NSString *)contentType {
    if (self = [super init]) {
        self.data = data;
        self.contentType = contentType;
    }
    return self;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    AVAssetResourceLoadingContentInformationRequest* contentRequest = loadingRequest.contentInformationRequest;

    // TODO: check that loadingRequest.request is actually our custom scheme        

    if (contentRequest) {
        contentRequest.contentType = self.contentType;
        contentRequest.contentLength = self.data.length;
        contentRequest.byteRangeAccessSupported = YES;
    }

    AVAssetResourceLoadingDataRequest* dataRequest = loadingRequest.dataRequest;

    if (dataRequest) {
        // TODO: handle requestsAllDataToEndOfResource
        NSRange range = NSMakeRange((NSUInteger)dataRequest.requestedOffset, (NSUInteger)dataRequest.requestedLength);
        [dataRequest respondWithData:[self.data subdataWithRange:range]];
        [loadingRequest finishLoading];
    }

    return YES;
}

@end

namespace nme
{


class AvDecodedData : public INmeSoundData
{
public:
   QuickVec<short> decodedBuffer;
   double duration;
   int rate;
   int channels;
   int sampleCount;
   int refCount;
   NSDataAssetResourceLoaderDelegate *delegate;

   AvDecodedData(const unsigned char *inData, int len)
   {
      refCount++;
      duration = 0.0;
      channels = 0;
      rate = 0;
      sampleCount = 0;
      delegate = nil;


      #ifndef OBJC_ARC
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      #endif

      NSData* data = [ NSData dataWithBytes:inData length:len];

      delegate = [[NSDataAssetResourceLoaderDelegate alloc] initWithData:data contentType:AVFileTypeWAVE];

      NSURL *url = [NSURL URLWithString:@"ns-data-scheme://"];
      AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];

      [asset.resourceLoader setDelegate:delegate queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];


      setAsset(asset);

      #ifndef OBJC_ARC
      [pool drain];
      #endif
   }

   AvDecodedData(const std::string &inData)
   {
      refCount++;
      duration = 0.0;
      channels = 0;
      rate = 0;
      sampleCount = 0;
      delegate = nil;

      #ifndef OBJC_ARC
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      #endif

      NSString *str = [[NSString alloc] initWithUTF8String:inData.c_str()];

      NSURL *srcUrl = [NSURL fileURLWithPath:str];

      AVURLAsset *asset = [AVURLAsset URLAssetWithURL:srcUrl options:nil];

      setAsset(asset);

      #ifndef OBJC_ARC
      [pool drain];
      #endif
   }

   void setAsset(AVURLAsset *asset)
   {
      if (asset)
      {
         float sampleRate = 0.0;

         CMTime audioDuration = asset.duration;
         double metaDuration = CMTimeGetSeconds(audioDuration);

         NSArray *formatDesc = ((AVAssetTrack*)[[asset tracksWithMediaType:AVMediaTypeAudio]  objectAtIndex:0]).formatDescriptions;
         for(unsigned int i = 0; i < [formatDesc count]; ++i)
         {
            #ifndef OBJC_ARC
            CMAudioFormatDescriptionRef item = (CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
            #else
            CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
            #endif
            const AudioStreamBasicDescription *asDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item);
            if (asDesc)
            {
                // get data
                channels = asDesc->mChannelsPerFrame;
                sampleRate = asDesc->mSampleRate;
            }
         }


         NSError *assetError = nil;
         AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:&assetError] ;
 
         AudioChannelLayout channelLayout;
         memset(&channelLayout, 0, sizeof(AudioChannelLayout));
         channelLayout.mChannelLayoutTag = channels == 2 ? kAudioChannelLayoutTag_Stereo : kAudioChannelLayoutTag_Mono;
   
         NSDictionary *outputSettings = 
            [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, 
              [NSNumber numberWithFloat:sampleRate], AVSampleRateKey,
              [NSNumber numberWithInt:channels], AVNumberOfChannelsKey,
              [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
              [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
              [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
              [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
              [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
            nil];

         AVAssetReaderAudioMixOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput 
                 assetReaderAudioMixOutputWithAudioTracks:asset.tracks audioSettings: outputSettings];

         int sampleCount = channels * sampleRate * metaDuration;
         int pos = 0;
         int remaining = sampleCount;
         decodedBuffer.resize(sampleCount);

         if ([assetReader canAddOutput: assetReaderOutput])
         {
            [assetReader addOutput: assetReaderOutput];

            [assetReader startReading];

            NSDictionary *settings = assetReaderOutput.audioSettings;

            while(true)
            {
               CMSampleBufferRef sampleBuffer = [assetReaderOutput copyNextSampleBuffer];
               if (sampleBuffer)
               {
                  char *buffer = 0;
                  size_t size = 0;
                  CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                  if (blockBuffer)
                  {
                     CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &size, &buffer);
                     int copySamples = size/2;
                     if (copySamples>remaining) copySamples = remaining;
                     if (buffer && copySamples)
                     {
                        memcpy(&decodedBuffer[pos], buffer, copySamples*sizeof(short) );
                        pos += copySamples;
                        remaining -= copySamples;
                     }
                  }
                  CFRelease(sampleBuffer);

                  if (!buffer)
                     break;
               }
               else
               {
                    // done!
                  [assetReader cancelReading];
                  break;
               }
            }
         }
         if (remaining>0)
            decodedBuffer.resize( decodedBuffer.size()-remaining );

         if (decodedBuffer.size()>0)
         {
            rate = sampleRate;
            sampleCount = decodedBuffer.size()/channels;
            duration = sampleCount/(sizeof(float)*rate);
         }
         else
            channels = 0;
      }

   }

   ~AvDecodedData()
   {
      delegate = nil;
   }

   virtual INmeSoundData  *addRef() { refCount++; return this; }
   virtual void   release() { refCount--; if (refCount<=0) delete this; }

   virtual double getDuration() const { return duration; }
   virtual int    getChannelSampleCount() const { return sampleCount; }
   virtual bool   getIsStereo() const { return channels==2; }
   virtual int    getRate() const { return rate; }
   virtual bool   getIsDecoded() const { return decodedBuffer.size() > 0; }
   virtual short  *decodeAll() { return &decodedBuffer[0]; }
   virtual int    getDecodedByteCount() const { return decodedBuffer.ByteCount(); }
   virtual INmeSoundStream *createStream() { return 0; }

};


INmeSoundData *INmeSoundData::createAvDecoded(const std::string &inFilename)
{
   return new AvDecodedData(inFilename);
}

INmeSoundData *INmeSoundData::createAvDecoded(const unsigned char *inData, int len)
{
   return new AvDecodedData(inData, len);
}




} // end namespace nme

