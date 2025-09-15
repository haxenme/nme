#include <UIKit/UIImage.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVFoundation.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioToolbox/ExtendedAudioFile.h>

#include <Sound.h>
#include <nme/QuickVec.h>
#include <Utils.h>
#include "Audio.h"



@interface GameAudioManager : NSObject
@end



namespace nme { void avCheckPlayable(); }

AVAudioSession *session = nil;
bool sessionInterrupted = false;
bool avAudioPlayable = true;
bool sessionSuspended = false;
AVAudioEngine *audioEngine = nil;
int audioEngineUsers = 0;

bool avAudioManagerSetup = false;
GameAudioManager *avAudioManager = nil;

@implementation GameAudioManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupAudioSession];
    }
    return self;
}

//- (void)activate: {
//    [session setActive:YES error:nil];
//}

- (void)handleAudioInterruption:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    unsigned int type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];

    LOG_SOUND("handleAudioInterruption");
    if (type == AVAudioSessionInterruptionTypeBegan) {
        sessionInterrupted = true;
        nme::avCheckPlayable();
        // Pause audio during interruption (e.g., phone call)
        /*
        if (self.backgroundMusicPlayer.isPlaying) {
            [self.backgroundMusicPlayer pause];
        }
        for (NSString *key in self.soundEffects) {
            AVAudioPlayer *player = self.soundEffects[key];
            if (player.isPlaying) {
                [player pause];
            }
        }
        */
    } else if (type == AVAudioSessionInterruptionTypeEnded) {
        // Resume audio if interruption ends and app is still active
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            NSError *error = nil;
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            if (error) {
                NSLog(@"Failed to reactivate audio session: %@", error.localizedDescription);
                return;
            }
            nme::avCheckPlayable();
            //[self.backgroundMusicPlayer play];
            // Optionally resume sound effects if needed
        }
    }
}

- (void)setupAudioSession {
    LOG_SOUND("GameAudioManager:setupAudioSession");
    session = [AVAudioSession sharedInstance];
    NSError *error = nil;

    // Use AVAudioSessionCategoryAmbient for games (allows mixing with other audio, respects mute switch)
    [session setCategory:AVAudioSessionCategoryAmbient
            withOptions:0
                  error:&error];
    if (error) {
        NSLog(@"Failed to set audio session category: %@", error.localizedDescription);
        return;
    }

    // Activate the audio session
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"Failed to activate audio session: %@", error.localizedDescription);
        return;
    }

    // Register for interruption notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleAudioInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:session];

    avAudioManager = self;
    LOG_SOUND("GameAudioManager:setupAudioSession ok");
}

@end


bool initSession()
{
   if (!avAudioManagerSetup)
   {
      avAudioManagerSetup = true;
      [[GameAudioManager alloc] init];
   }
   [session setActive:YES error:nil]; 

   return avAudioManager!=nil;
}

AVAudioEngine *getAudioEngine()
{
   if (!audioEngine)
   {
      audioEngine = [ [AVAudioEngine alloc] init];
   }

   return audioEngine;
}

bool useAudioEngine()
{
   if (audioEngineUsers==0)
   {
      NSError *err = nil;
      if (![audioEngine  startAndReturnError:&err])
      {
         NSLog(@"Failed to activate audio engine: %@", err.localizedDescription);
         return false;
      }
   }

   audioEngineUsers++;
   return true;
}

void releaseAudioEngine()
{
   audioEngineUsers--;
   if (audioEngineUsers==0)
      [audioEngine stop];
}



@interface AVAudioPlayerChannelDelegate : NSObject <AVAudioPlayerDelegate>  {
@private
    // keeps track of how many times a track still has to play
    int loops;
    float offset;
    bool isPlaying;
}
@end


@implementation AVAudioPlayerChannelDelegate

- (id)init {
    self = [super init];
    return self;
}


-(bool) isPlaying  {
    return isPlaying;
}

-(id) initWithLoopsOffset: (int)theNumberOfLoops offset:(int)theOffset  {
    self = [super init];
    LOG_SOUND("Delegate initWithLoopsOffset %d",theOffset);
    if ( self ) {
        loops = theNumberOfLoops <= 0 ? theNumberOfLoops : theNumberOfLoops - 1;
        offset = theOffset;
        isPlaying = true;
    }
    return self;
}

- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *) player 
                                  error:(NSError *) error {
   LOG_SOUND("audioPlayerDecodeErrorDidOccur!");
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    LOG_SOUND("AVAudioPlayerChannelDelegate audioPlayerDidFinishPlaying()");
    LOG_SOUND("loops : %d", loops );
    LOG_SOUND("offset : %f", offset);

    if (loops == 0) {
        LOG_SOUND("finished the mandated number of loops");
        isPlaying = false;
        // the channel has done its job.
        // we should release both the player and the delegate
        // right here, but the problem is that someone has to
        // notify the channel that we are done because he has to do
        // his own cleanup (someone will poll him later whether the channel
        // is done playing).
        // Long story short, because of weird issues, we can't keep
        // a handle to the channel here, so we can't notify him.
        // So what we do instead is we'll let the channel release
        // both the player and the delegate when he'll find out that the
        // player is not playing anymore.        
    }
    else {
        LOG_SOUND("still some loops to go, playing");
        if (loops>0)
           loops--;
        player.currentTime = offset;
        //player.currentTime = 0;
        [player play];
    }
}

@end


namespace nme
{


/*----------------------------------------------------------
 AVSoundPlayer implementation of Sound and SoundChannel classes:
 - higher latency than OpenAL implementation
 - streams sound data using Apple's optimized pathways
 ------------------------------------------------------------*/
std::vector<class AVAudioPlayerChannel *> allAvChannels;

class AVAudioPlayerChannel : public SoundChannel
{
   std::string name;
   AVAudioPlayer *avPlayer;
   AVAudioPlayerChannelDelegate *thePlayerDelegate;
   bool paused;
   bool sharedPlayer;

public:
   AVAudioPlayerChannel( const std::string &inName, AVAudioPlayer *inPlayer, bool inSharedPlayer,
        int inLoops, float  inOffset, const SoundTransform &inTransform) : name(inName)
   {
      IncRef();

      LOG_SOUND("AVAudioPlayerChannel %s constructor", name.c_str());
      paused = false;
      avPlayer = inPlayer;
      sharedPlayer = inSharedPlayer && avPlayer!=nil;

      if (avPlayer)
      {
         // for each player there is a delegate
         // the reason for this is that AVAudioPlayer has no way to loop
         // starting at an offset. So what we need to do is to
         // get the delegate to react to a loop end, rewind the player
         // and play again.
         LOG_SOUND("AVAudioPlayerChannel constructor - allocating and initialising the delegate");
         thePlayerDelegate = [[AVAudioPlayerChannelDelegate alloc] initWithLoopsOffset:inLoops offset:inOffset];
         [avPlayer setDelegate:thePlayerDelegate];

         // the sound channel has been created because play() was called
         // on a Sound, so let's play
         LOG_SOUND("AVAudioPlayerChannel constructor - getting the player to play at offset %f", inOffset);
         avPlayer.currentTime = inOffset/1000;
         avPlayer.pan = inTransform.pan;
         //if ([avPlayer respondsToSelector: NSSelectorFromString(@"setPan")])
            //[avPlayer setPan: inTransform.pan];
         [avPlayer setVolume: inTransform.volume];

         [avPlayer play];
 
         allAvChannels.push_back(this);
      }

      LOG_SOUND("AVAudioPlayerChannel constructor exiting");
   }

   ~AVAudioPlayerChannel()
   {
      LOG_SOUND("AVAudioPlayerChannel %s destructor", name.c_str());

      if (avPlayer!=nil)
        removeFromList();
   }

   void removeFromList()
   {
      allAvChannels.erase( std::find(allAvChannels.begin(), allAvChannels.end(),this) );
   }

   bool isComplete()
   {
      // Never had one in the first place, or maybe relinquishPlayer or stopped.
      bool isPlaying = avPlayer!=nil;

      if (isPlaying)
      {
         // note that we ask the delegate, not the AVAudioPlayer
         // the reason is that technically AVAudioPlayer might not be playing,
         // but we are in the process of restarting it to play a loop,
         // and we don't want to stop him. So we ask the delegate, which
         // knows when all the loops are properly done.
         isPlaying = [thePlayerDelegate isPlaying];

         // Finished?
         if (!isPlaying)
         {
            #ifndef OBJC_ARC
            [thePlayerDelegate release];
            if (!sharedPlayer)
               [avPlayer release];
            #endif
            avPlayer = nil;
            thePlayerDelegate = nil;
            removeFromList();
         }
      }

      if (!isPlaying)
         LOG_SOUND("AVAudioPlayerChannel %s isComplete\n", name.c_str());
      return !isPlaying;
   }


   void suspend()
   {
      paused = false;
      if (avPlayer!=nil && [avPlayer isPlaying] )
      {
         LOG_SOUND("sound - suspend");
         paused = true;
         [avPlayer pause];
      }
      else
         LOG_SOUND("sound - no need to suspend");
   }

   void resume()
   {
      if (avPlayer!=nil && paused)
      {
         LOG_SOUND("sound - resume");
         [avPlayer play];
      }
      else
         LOG_SOUND("sound - no need to resume");
      paused = false;
   }

   double getLeft()
   {
      if (avPlayer)
         return (1-avPlayer.pan)/2;
      return 0.5;
   }
   double getRight()
   {
      if (avPlayer)
      {
         //return ([avPlayer pan] + 1)/2;
         return (avPlayer.pan + 1)/2;
     }
     return 0.5;
   }
   double getPosition()
   {
      LOG_SOUND("AVAudioPlayerChannel getPosition()");
      if (!avPlayer) return 0.0;
      return [avPlayer currentTime] * 1000;
   }
   double setPosition(const float &inFloat)
   {
      LOG_SOUND("AVAudioPlayerChannel setPosition()");
      if (!avPlayer) return 0.0;
      avPlayer.currentTime = inFloat / 1000;
      return inFloat;
   }

   void setTransform(const SoundTransform &inTransform)
   {
      LOG_SOUND("AVAudioPlayerChannel setTransform()");
      if (avPlayer)
      {
         avPlayer.pan = inTransform.pan;
         [avPlayer setVolume: inTransform.volume];
      }
   }

   // note that once a channel has been stopped, it's destined
   // to be deallocated. It will never play another sound again
   // we decrease the reference count here of both the player
   // and its delegate.
   // If someone calls isComplete() in the future,
   // that function will see the nil and avoid doing another
   // release.
   void stop()
   {
      LOG_SOUND("AVAudioPlayerChannel %s stop()", name.c_str());
      if (!avPlayer)
         return;

      if (sharedPlayer)
      {
         [avPlayer pause];
      }
      else
      {
         [avPlayer stop];
         #ifndef OBJC_ARC
         [avPlayer release];
         #endif
      }
      #ifndef OBJC_ARC
      [thePlayerDelegate release];
      #endif

      avPlayer = nil;
      thePlayerDelegate = nil;
      removeFromList();
   }


   void relinquishPlayer()
   {
      if (avPlayer)
      {
         LOG_SOUND("AVAudioPlayerChannel %s early stop()", name.c_str());
         stop();
      }
   }

   void detachPlayer()
   {
      sharedPlayer = false;
   }

};


// Plays either from dynamiec data, or from a pre-decoded sound data object, decoded into a buffer stream
class AVAudioPlayerSyncChannel : public SoundChannel
{
   const int BUF_SIZE = (1<<17);
 
   AVAudioFormat *format = nil;
   AVAudioPlayerNode *playerNode = nil;
   AVAudioFormat *convertFormat = nil;
   AVAudioConverter *converter = nil;
   bool deinterleave = false;
   bool isPlaying = false;
   bool isStarted = false;
   int  channelCount = 0;
   int frequency = 0;
   bool acceptingData = true;
   bool usingAudioEngine = false;
   double pendingBufferTime = 0;
   int pendingBufferCount = 0;
   double partialBufferStart = 0;
   double currentPlaybackPosition = 0.0;
   bool isFloat = false;
   INmeSoundDataPtr soundData;
   INmeSoundStream *soundStream=nullptr;
   std::vector<unsigned char> dataBuf;
    
public:

   // Async channel
   AVAudioPlayerSyncChannel( const SoundTransform &inTransform, SoundDataFormat inDataFormat,bool inIsStereo, int inRate)
   {
      init(AVAudioPCMFormatFloat32, inIsStereo, inRate);
   }

   // From encoded data
   AVAudioPlayerSyncChannel( INmeSoundDataPtr inSoundData, int loops, double startTime, const SoundTransform &inTransform )
   {
      soundData = inSoundData;
      INmeSoundStream *stream = inSoundData->createStream();
      LOG_SOUND("AVAudioPlayerSyncChannel from Stream %p", stream);
      if (stream)
      {
         soundStream = stream;
         init(false, inSoundData->getIsStereo(), inSoundData->getRate());
         LOG_SOUND("init done, acceptingData");
         acceptingData = true;
         bool remaining = queueStream();
         LOG_SOUND(" Queued first buffer %d\n", remaining);
         if (remaining)
            remaining = queueStream();
         LOG_SOUND(" Queued second buffer %d\n", remaining);
         //if (remaining)
         //   remaining = queueStream();
         LOG_SOUND(" Queued third buffer %d\n", remaining);
      }
   }

   bool init( bool inIsFloat, bool inIsStereo, int inRate)
   {
      isFloat = inIsFloat;
      AVAudioCommonFormat commonFmt = isFloat ? AVAudioPCMFormatFloat32 : AVAudioPCMFormatInt16;
      channelCount = inIsStereo ? 2 : 1;
      deinterleave = inIsStereo;
      frequency = inRate;
      AVAudioEngine *audioEngine = getAudioEngine();
      LOG_SOUND("Using audioEngine %p, channels %d, rate:%d\n", audioEngine, channelCount, inRate);

      format = [[AVAudioFormat alloc] initWithCommonFormat:commonFmt
                                             sampleRate:inRate
                                             channels:channelCount
                                             interleaved:NO];
      LOG_SOUND("Created sound format: %p\n", format);
      playerNode = [[AVAudioPlayerNode alloc] init];
      // _buffers = [NSMutableArray array];

      LOG_SOUND("Created player node : %p\n", playerNode);
        
      // Attach player node to the engine
      [audioEngine attachNode:playerNode];

      LOG_SOUND("Attached player node : %p\n", playerNode);
  
      // Connect player node to the main mixer node
      LOG_SOUND("Connected player node tp : %p\n", audioEngine.mainMixerNode);
      @try
      {
         [audioEngine connect:playerNode to:audioEngine.mainMixerNode format:format];
         LOG_SOUND("Connected Ok\n", playerNode);
      }
      @catch (NSException *exception)
      {
         LOG_SOUND("Connected requires conversion\n");

         AVAudioFormat *destFormat = [audioEngine.mainMixerNode inputFormatForBus:0];

         /*
         NSLog(@"Sample Rate: %f", destFormat.sampleRate);
         NSLog(@"Channels: %ld", (long)destFormat.channelCount);
         NSLog(@"Interleaved: %s", destFormat.isInterleaved ? "YES" : "NO");
         NSLog(@"Standard fmt: %s", destFormat.isStandard ? "YES" : "NO");
         NSLog(@"Common Format: %s", destFormat.commonFormat == AVAudioPCMFormatFloat32 ? "Float32" :
               (destFormat.commonFormat == AVAudioPCMFormatFloat64 ? "Float64" :
               (destFormat.commonFormat == AVAudioPCMFormatInt16 ? "Int16" : "Other")));
         */

         converter = [[AVAudioConverter alloc] initFromFormat:format toFormat:destFormat];

         LOG_SOUND("Connected with Conversion %p %p\n", playerNode, converter);
         if (!converter)
         {
            LOG_SOUND("Failed to create converter");
            closeStream();
            return false;
         }

         convertFormat = destFormat;

         [audioEngine connect:playerNode to:audioEngine.mainMixerNode format:destFormat];
      }  
      return true;
   }

   // AudioStream
   ~AVAudioPlayerSyncChannel()
   {
      LOG_SOUND("AVAudioPlayerSyncChannel destructor %p\n", this);
      closeStream();
   }

   double now() { return GetTimeStamp(); }

   bool queueStream()
   {
      if (!soundStream || !acceptingData)
         return false;

      dataBuf.resize(BUF_SIZE);
      int toRead = BUF_SIZE;
      int read = soundStream->fillBuffer((char *)dataBuf.data(), toRead);
      //LOG_SOUND("Read %d/%d bytes\n", read, toRead);
      if (read>0)
      {
         addData(dataBuf.data(),read);
      }
      else
      {
         LOG_SOUND("Finished stream\n");
         acceptingData = false;
      }

      return acceptingData;
   }

   // AudioStream
   void addData(const ByteArray &inBytes)
   {
      addData(inBytes.Bytes(), inBytes.Size());
   }
   void addData(const unsigned char *inBytes, int inByteCount)
   {
      int sampleCount = inByteCount / (isFloat ? sizeof(float) : sizeof(short));
      int frames = sampleCount/channelCount; 
      // This means close channel
      if (frames<1024 && !soundStream)
      {
         // Last one
         acceptingData = false;
         if (frames==0)
            return;
      }

      // Create a buffer with the correct frame count and format
      AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:(AVAudioFrameCount)frames];
      if (!buffer)
      {
         LOG_SOUND("Could not allocate buffer\n");
         closeStream();
         return;
      }
    
      buffer.frameLength = buffer.frameCapacity;
      if (deinterleave)
      {
         for(int ch=0; ch<2;ch++)
         {
            if (isFloat)
            {
               float *floatChannelData = buffer.floatChannelData[ch];
               const float *src = ((const float *)inBytes) + ch;
               for(int f=0;f<frames;f++)
                  floatChannelData[f] = src[f<<1];
            }
            else
            {
               short *shortChannelData = buffer.int16ChannelData[ch];
               const short *src = ((const short *)inBytes) + ch;
               for(int f=0;f<frames;f++)
                  shortChannelData[f] = src[f<<1];
            }
         }
      }
      else
      {
         void *channelData = isFloat ? (void *)buffer.floatChannelData[0] :  (void *)buffer.int16ChannelData[0];
         memcpy(channelData, inBytes, inByteCount);
      }

      if (converter)
      {
         AVAudioPCMBuffer *newBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:convertFormat frameCapacity:(AVAudioFrameCount)frames];
         newBuffer.frameLength = newBuffer.frameCapacity;
         NSError *err = nil;
         if (![converter convertToBuffer:newBuffer fromBuffer:buffer error:&err])
         {
            LOG_SOUND("Conversion failed (%p) %s.", newBuffer, [[err description] UTF8String]);
            closeStream();
            return;
         }
         buffer = newBuffer;
      }
    
      double bufferTime = (double)frames / frequency;
      
      pendingBufferTime += bufferTime;
      pendingBufferCount ++;
    
      [playerNode scheduleBuffer:buffer completionHandler:^{
         pendingBufferTime -= bufferTime;
         pendingBufferCount --;
         currentPlaybackPosition += bufferTime;
         partialBufferStart = now();
         if (acceptingData && pendingBufferCount<2)
            queueStream();
      }];
    
      if (!isStarted)
      {
         if (useAudioEngine())
         {
            isStarted = true;
            usingAudioEngine = true;
            [playerNode play];
            isPlaying = true;
         }
         else
         {
            closeStream();
         }
      }
   }
    
   void closeStream()
   {
      acceptingData = false;
      delete soundStream;
      soundStream = nullptr;

      //printf("closeStream %d %p\n", mChannel, stream);
      if (playerNode && isPlaying)
      {
         [playerNode stop];
         isPlaying = false;
      }
      playerNode = nil;
      if (usingAudioEngine)
      {
         usingAudioEngine = false;
         releaseAudioEngine();
      }
   }


   // AudioStream
   void setTransform(const SoundTransform &inTransform) 
   {
   }


   // AudioStream
   bool CheckDone()
   {
      return !acceptingData;
   }

   // AudioStream
   bool isComplete()
   {
      bool complete = CheckDone();
      if (complete)
         closeStream();
      return complete;
   }
   double getLeft() { return 1; }
   double getRight() { return 1; }
   double setPosition(const float &inFloat) { return 1; }
   void stop() 
   {
      //printf("AudioStream stop %d\n", mChannel);
      closeStream();
      //CheckDone();
   }

   // AudioStream
   double getPosition()
   {
      double partial = pendingBufferTime>0 ? now()-partialBufferStart : 0.0;
      return currentPlaybackPosition + partial;
   }


   double getDataPosition()
   {
      // ?
      return getPosition() / frequency;
   }

   // AudioStream
   bool needsData()
   {
      if (soundStream)
         return false;
      if (!acceptingData)
         return false;

      if (pendingBufferTime<=0.0001)
         return true;

      double remainingTime = pendingBufferTime - (now()-partialBufferStart);

      return remainingTime<0.300;
   }

};


/*
 Can operate in 1 of 2 modes:
  1. Persistent player - quick to play, but takes memory.
  2. Filename store, create av player on demand.  Slow to start, but low memory when idle.

 Generally, use 1 for shound effects and 2 for music.  When constructed from data, we also use 1.
 The AVAudioPlayerChannel manages the playing events and also know what mode it operates in.

*/

class AVAudioPlayerSound : public Sound
{
    std::string mError;
    std::string mFilename;
    std::string name;
    double theDuration;
    AVAudioPlayer *persistentPlayer;
    ObjectPtr<AVAudioPlayerChannel> currentChannel;
    INmeSoundDataPtr soundData;

public:
   AVAudioPlayerSound(const std::string &inFilename, bool forceMusic) :
       mFilename(inFilename)
   {
      LOG_SOUND("AVAudioPlayerSound constructor(%s) %p",inFilename.c_str(), this);
      IncRef();

      name = mFilename;

      persistentPlayer = nil;

      AVAudioPlayer *player = createPlayer();

      if (player==nil)
      {
         bool forceDecode = !forceMusic || nme::determineFormatFromFile(inFilename) == eAF_wav;
         int flags = (forceDecode ? SoundForceDecode : 0) | SoundAddWavHeader;
        
         INmeSoundData *soundData = INmeSoundData::create(mFilename, flags);
         if (soundData)
            fromSoundData(soundData);
      }
      else
      {
         theDuration = [player duration] * 1000;
         LOG_SOUND("Created sound from file, duration %fms", theDuration);

         if (forceMusic)
         {
            name += " music";
            LOG_SOUND("Release music, keep filename");
            #ifndef OBJC_ARC
            [player release];
            #endif
            player = nil;
         }
         else
         {
            LOG_SOUND("Keep sound-effect file");
            persistentPlayer = player;
            [persistentPlayer prepareToPlay]; // Preload to reduce latency
         }
      }
   }

   AVAudioPlayer *createPlayer()
   {
      std::string path = mFilename[0]=='/' ? mFilename : GetResourcePath() + gAssetBase + mFilename;
      NSString *ns_name = [[NSString alloc] initWithUTF8String:path.c_str()];
      NSURL  *theFileNameAndPathAsUrl = [NSURL fileURLWithPath:ns_name];
      #ifndef OBJC_ARC
      [ns_name release];
      #endif

      NSError *err = nil;
      AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:theFileNameAndPathAsUrl error:&err];

      if (err != nil)
      {
         mError = [[err description] UTF8String];
         LOG_SOUND("Error in file: %s.", mError.c_str());
      }

      return player;
   }

   AVAudioPlayerSound(const unsigned char *inDataPtr, int inDataLen, bool inForceMusic)
   {
      IncRef();
      mFilename = "unknown";

      LOG_SOUND("AVAudioPlayerSound constructor(datax%d) %p", inDataLen, this);
      char buf[1024];
      snprintf(buf,1024,"From date: %d (%d)", inDataLen, inForceMusic);
      name = buf;

      NSData *data = [[NSData alloc] initWithBytes:inDataPtr length:inDataLen];

      NSError *err = nil;
      persistentPlayer = [[AVAudioPlayer alloc] initWithData:data error:&err];
      #ifndef OBJC_ARC
      [data release];
      #endif
      data = nil;

      if (err != nil)
      {
         mError = [[err description] UTF8String];
         err = nil;

         bool forceDecode = !inForceMusic || nme::determineFormatFromBytes(inDataPtr, inDataLen) == eAF_wav;
         int flags = (forceDecode ? SoundForceDecode : 0) | SoundAddWavHeader;
        
         INmeSoundData *soundData = INmeSoundData::create(inDataPtr, inDataLen, flags);
         LOG_SOUND("AVAudioPlayerSound - try decoding %d data:%p",forceDecode, soundData);
         if (soundData)
         {
            fromSoundData(soundData);
            mError = "";
         }  
      }
      else
      {
         if (persistentPlayer!=nil)
            theDuration = [persistentPlayer duration] * 1000;
      }

      LOG_SOUND(" data player: %p = %p err:%s\n", this, persistentPlayer, mError.c_str());
   }

   void fromSoundData(INmeSoundData *inSoundData)
   {
      bool decoded = inSoundData->getIsDecoded();
      if (decoded)
      {
          LOG_SOUND("AVAudioPlayerSound - from decoded");
          mError = "";
          unsigned char *wav = inSoundData->decodeWithHeader();
          int wav_size = inSoundData->getDecodedByteCount();
          NSData *data = [[NSData alloc] initWithBytes:wav length:wav_size];

          #if 0
          NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
          NSString *documentsDirectory = [paths firstObject];
          NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"mydata.wav"];
          LOG_SOUND("Saving file path: %s\n", [filePath UTF8String] );

          // Write the NSData to the file
          BOOL success = [data writeToFile:filePath atomically:YES];
          LOG_SOUND("AVAudioPlayerSound - wrote ok:%d", success==YES);
          #endif

          NSError *err = nil;
          persistentPlayer = [[AVAudioPlayer alloc] initWithData:data error:&err];
          #ifndef OBJC_ARC
          [data release];
          #endif
          data = nil;
          LOG_SOUND("AVAudioPlayerSound - decode %d ok:%d", wav_size, err!=nil);

          if (err != nil)
          {
             mError = [[err description] UTF8String];
          }
          if (persistentPlayer!=nil)
             theDuration = [persistentPlayer duration] * 1000;
      }
      else
      {
         soundData = inSoundData;
         theDuration = soundData->getDuration();
         LOG_SOUND("AVAudioPlayerSound - from encoded with duration %f", theDuration);
      }
      inSoundData->release();
   }

   ~AVAudioPlayerSound()
   {
      LOG_SOUND("AVAudioPlayerSound destructor(%p)",this);
      if (currentChannel)
         currentChannel->detachPlayer();

      #ifndef OBJC_ARC
      if (persistentPlayer!=nil) [persistentPlayer release];
      #endif
   }

   double getLength()
   {
      return theDuration;
   }

   void getID3Value(const std::string &inKey, std::string &outValue)
   {
      outValue = "";
   }
   int getBytesLoaded()
   {
      int toBeReturned = ok() ? 100 : 0;
      return toBeReturned;
   }
   int getBytesTotal()
   {
      int toBeReturned = ok() ? 100 : 0;
      return toBeReturned;
   }
   bool ok()
   {
      bool toBeReturned = mError.empty();
      return toBeReturned;
   }
   std::string getError()
   {
      return mError;
   }

   void close()
   {
      LOG_SOUND("AVAudioPlayerSound close() doing nothing"); 
   }

   const char *getEngine() { return "avplayer"; }

   // This method is called when Sound.play is called.
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      LOG_SOUND("AVAudioPlayerSound openChannel() startTime=%f, loops = %d",startTime,loops); 

      if (!initSession())
      {
         LOG_SOUND("No session.");
         return nullptr;
      }

      if (persistentPlayer!=nil)
      {
         if (currentChannel)
         {
            currentChannel->relinquishPlayer();
            currentChannel = nullptr;
         }

         currentChannel = new AVAudioPlayerChannel( name, persistentPlayer, true, loops, startTime, inTransform);
         return currentChannel.get();
      }

      if (soundData)
      {
         LOG_SOUND("AVAudioPlayerSound openChannel() from data %p", soundData.get());
          return new AVAudioPlayerSyncChannel( soundData, loops, startTime, inTransform);
      }

      LOG_SOUND("AVAudioPlayerSound openChannel() with player\n");
      return new AVAudioPlayerChannel( name, createPlayer(), false, loops, startTime, inTransform);
   }
};


Sound *CreateAvPlayerSound(const std::string &inFilename, bool forceMusic)
{
   initSession();
   return new AVAudioPlayerSound(inFilename, forceMusic);
}


Sound *CreateAvPlayerSound(const unsigned char *inData, int len, bool inForceMusic)
{
   initSession();
   return new AVAudioPlayerSound(inData, len, inForceMusic);
}

SoundChannel *CreateAvPlayerSyncChannel(const ByteArray &inData, const SoundTransform &inTransform,
              SoundDataFormat inDataFormat,bool inIsStereo, int inRate)
{
   initSession();
   AVAudioPlayerSyncChannel *result = new AVAudioPlayerSyncChannel(inTransform, inDataFormat, inIsStereo, inRate);

   result->addData(inData);

   return result;
}




void avCheckPlayable()
{
   bool playable = !sessionSuspended && !sessionInterrupted;
   if (playable!=avAudioPlayable)
   {
      avAudioPlayable = playable;
      if (playable)
         for(auto channel : allAvChannels )
            channel->resume();
      else
         for(auto channel : allAvChannels )
            channel->suspend();
   }
}

void avSuspendAudio()
{
   LOG_SOUND("avSuspendAudio %d", (int)allAvChannels.size());
   sessionSuspended = true;
   avCheckPlayable();
}

void avResumeAudio()
{
   LOG_SOUND("avResumeAudio %d", (int)allAvChannels.size());
   sessionSuspended = false;
   avCheckPlayable();
}


} // end namespace nme
