#include <UIKit/UIImage.h>
#import <AVFoundation/AVAudioPlayer.h>
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioToolbox/ExtendedAudioFile.h>

#include <Sound.h>
#include <QuickVec.h>

typedef unsigned char uint8;

namespace nme
{

static ALCdevice  *sgDevice = 0;
static ALCcontext *sgContext = 0;

static bool Init()
{
   static bool is_init = false;
   if (!is_init)
   {
      is_init = true;
      sgDevice = alcOpenDevice(0); // select the "preferred device"
      if (sgDevice)
      {
         sgContext=alcCreateContext(sgDevice,0);
         alcMakeContextCurrent(sgContext);
      }
   }
   return sgContext;
}

class OpenALChannel : public SoundChannel
{
public:
    OpenALChannel(Object *inSound,unsigned int inBufferID,
                   int inLoops, const SoundTransform &inTransform)
    {
       mSound = inSound;

       // grab a source ID from openAL
       alGenSources(1, &mSourceID); 
 
       // attach the buffer to the source
       alSourcei(mSourceID, AL_BUFFER, inBufferID);
       // set some basic source prefs
       alSourcef(mSourceID, AL_PITCH, 1.0f);
       alSourcef(mSourceID, AL_GAIN, inTransform.volume);
       // TODO: not right!
       if (inLoops>1)
         alSourcei(mSourceID, AL_LOOPING, AL_TRUE);

       alSourcePlay(mSourceID);

       inSound->IncRef();
    }

    ~OpenALChannel()
    {
       if (mSourceID)
          alDeleteSources(1, &mSourceID);
       mSound->DecRef();
    }

   bool isComplete() { return true; }
   double getLeft()  { return 1.0; }
   double getRight()   { return 1.0; }
   double getPosition()  { return 1.0; }
   void setTransform(const SoundTransform &inTransform)
   {
   }
   void stop()
   {
   }


    Object *mSound;
    unsigned int mSourceID;
};


class OpenALSound : public Sound
{
public:
   OpenALSound(const std::string &inFilename)
   {
      IncRef();
      mBufferID = 0;

      NSString *str = [[NSString alloc] initWithUTF8String:inFilename.c_str()];
      NSString *path = [[NSBundle mainBundle] pathForResource:str ofType:nil];
      [str release];

      // get some audio data from a wave file
      CFURLRef fileURL = (CFURLRef)[[NSURL fileURLWithPath:path] retain];
      //[path release];
 
      if (!fileURL)
      {
         mError = "Error int url: " + inFilename;
      }
      else
      {
         QuickVec<uint8> buffer;
         ALenum  format;
         ALsizei freq;
 
         LoadData(fileURL, buffer, &format, &freq);
 
         CFRelease(fileURL);
 
         if(alGetError() != AL_NO_ERROR)
         {
            mError = "Error opening sound data";
         }
         else
         {
            // grab a buffer ID from openAL
            alGenBuffers(1, &mBufferID);
 
            // load the awaiting data blob into the openAL buffer.
            alBufferData(mBufferID,format,&buffer[0],buffer.size(),freq); 
         }
      }
   }

   ~OpenALSound()
   {
      if (mBufferID!=0)
         alDeleteBuffers(1, &mBufferID);
   }


   bool LoadData(CFURLRef inFileURL, QuickVec<uint8> &outBuffer,
                 ALenum *outDataFormat, ALsizei*   outSampleRate)
   {
      OSStatus err = noErr;
      SInt64 theFileLengthInFrames = 0;
      AudioStreamBasicDescription theFileFormat;
      UInt32 thePropertySize = sizeof(theFileFormat);
      ExtAudioFileRef extRef = NULL;
      AudioStreamBasicDescription theOutputFormat;
    

      // Open a file with ExtAudioFileOpen()
      err = ExtAudioFileOpenURL(inFileURL, &extRef);
      if (err)
      {
         mError = "Could not load audio data";
         return false;
      }

      // Get the audio data format
      err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileDataFormat,
               &thePropertySize, &theFileFormat);

      if (err)
      {
         mError = "Could not get FileDataFormat";
      }
      else if (theFileFormat.mChannelsPerFrame > 2)
      {
         mError = "Too many channels";
      }


      if (ok())
      {
         // Set the client format to 16 bit signed integer (native-endian) data
         // Maintain the channel count and sample rate of the original source format
         theOutputFormat.mSampleRate = theFileFormat.mSampleRate;
         theOutputFormat.mChannelsPerFrame = theFileFormat.mChannelsPerFrame;
    
         theOutputFormat.mFormatID = kAudioFormatLinearPCM;
         theOutputFormat.mBytesPerPacket = 2 * theOutputFormat.mChannelsPerFrame;
         theOutputFormat.mFramesPerPacket = 1;
         theOutputFormat.mBytesPerFrame = 2 * theOutputFormat.mChannelsPerFrame;
         theOutputFormat.mBitsPerChannel = 16;
         theOutputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian |
                 kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    
         // Set the desired client (output) data format
         err = ExtAudioFileSetProperty(extRef, kExtAudioFileProperty_ClientDataFormat,
              sizeof(theOutputFormat), &theOutputFormat);
         if (err)
            mError = "Could not set output format";
      }

      if (ok())
      {
         // Get the total frame count
         thePropertySize = sizeof(theFileLengthInFrames);
         err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileLengthFrames,
            &thePropertySize, &theFileLengthInFrames);
         if(err) mError = "Could not get the number of frames";
      }
    
      if (ok())
      {
         // Read all the data into memory
         UInt32 dataSize = theFileLengthInFrames * theOutputFormat.mBytesPerFrame;;
         outBuffer.resize(dataSize);

         AudioBufferList theDataBuffer;
         theDataBuffer.mNumberBuffers = 1;
         theDataBuffer.mBuffers[0].mDataByteSize = dataSize;
         theDataBuffer.mBuffers[0].mNumberChannels = theOutputFormat.mChannelsPerFrame;
         theDataBuffer.mBuffers[0].mData = &outBuffer[0];
    
         // Read the data into an AudioBufferList
         err = ExtAudioFileRead(extRef, (UInt32*)&theFileLengthInFrames, &theDataBuffer);
         if (err)
            mError = "Read audio buffer";
         else
         {
            // success
            *outDataFormat = (theOutputFormat.mChannelsPerFrame > 1) ?
                  AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
            *outSampleRate = (ALsizei)theOutputFormat.mSampleRate;
         }

      }
    
      if (extRef)
         ExtAudioFileDispose(extRef);
      return ok();
   }


   // TODO:
   double getLength() { return ok() ? 1 : 0; }

   void getID3Value(const std::string &inKey, std::string &outValue)
   {
      outValue = "";
   }
   int getBytesLoaded() { return ok() ? 100 : 0; }
   int getBytesTotal()  { return ok() ? 100 : 0; }
   bool ok() { return mError.empty(); }
   std::string getError() { return mError; }


   void close()  { }


   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
   {
      return new OpenALChannel(this,mBufferID,loops,inTransform);
   }

   unsigned int mBufferID;
   std::string mError;
};


Sound *Sound::Create(const std::string &inFilename,bool inForceSound)
{
   if (!Init())
      return 0;
   return new OpenALSound(inFilename);
}

} // end namespace nme
