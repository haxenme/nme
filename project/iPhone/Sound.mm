#include <UIKit/UIImage.h>
#import <AVFoundation/AVAudioPlayer.h>
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioToolbox/ExtendedAudioFile.h>

#include <Sound.h>
#include <QuickVec.h>
#include <Utils.h>

typedef unsigned char uint8;


//#define LOG_SOUND(args...) NSLog(@args)

#define LOG_SOUND(args...)  { }


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
    if ( self ) {
        loops = theNumberOfLoops;
        offset = theOffset;
        isPlaying = true;
    }
    return self;
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
        loops--;
        player.currentTime = offset/1000;
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
     - doesn't allocate uncompressed sound data in memory
     - doesn't expose sound data
     ------------------------------------------------------------*/
    
    class AVAudioPlayerChannel : public SoundChannel  {
        
    public:
        AVAudioPlayerChannel(Object *inSound, const std::string &inFilename,
            NSData *data,
            int inLoops, float  inOffset, const SoundTransform &inTransform)
        {
            LOG_SOUND("AVAudioPlayerChannel constructor");
            mSound = inSound;
            // each channel keeps the originating Sound object alive.
            inSound->IncRef();
           
            LOG_SOUND("AVAudioPlayerChannel constructor - allocating and initilising the AVAudioPlayer");

            if (data == NULL) {
                LOG_SOUND("AVAudioPlayerChannel construct with name");
                std::string name;
                
                if (inFilename[0] == '/') {
                    name = inFilename;
                } else {
                    name = GetResourcePath() + gAssetBase + inFilename;
                }
                
                NSString *theFileName = [[NSString alloc] initWithUTF8String:name.c_str()];
                
                NSURL  *theFileNameAndPathAsUrl = [NSURL fileURLWithPath:theFileName ];
                
                theActualPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:theFileNameAndPathAsUrl error: nil];
#ifndef OBJC_ARC
                [theFileName release];
#endif
            } else {
                LOG_SOUND("AVAudioPlayerChannel construct with data");
                theActualPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
            }

            // for each player there is a delegate
            // the reason for this is that AVAudioPlayer has no way to loop
            // starting at an offset. So what we need to do is to
            // get the delegate to react to a loop end, rewing the player
            // and play again.
            LOG_SOUND("AVAudioPlayerChannel constructor - allocating and initialising the delegate");
            thePlayerDelegate = [[AVAudioPlayerChannelDelegate alloc] initWithLoopsOffset:inLoops offset:inOffset];
            [theActualPlayer setDelegate:thePlayerDelegate];
            
            // the sound channel has been created because play() was called
            // on a Sound, so let's play
            LOG_SOUND("AVAudioPlayerChannel constructor - getting the player to play at offset %f", inOffset);
            theActualPlayer.currentTime = inOffset/1000;
            if ([theActualPlayer respondsToSelector: NSSelectorFromString(@"setPan")])
                [theActualPlayer setPan: inTransform.pan];
            [theActualPlayer setVolume: inTransform.volume];
            [theActualPlayer play];
            
            LOG_SOUND("AVAudioPlayerChannel constructor exiting");
        }
        
        ~AVAudioPlayerChannel()
        {
            LOG_SOUND("AVAudioPlayerChannel destructor");
            
            // when all channels associated with a sound
            // are all destroyed, then the Sound that generates
            // them might be destroyed (if there are no other
            // references to it anywhere else)
            mSound->DecRef();
        }
        
        void playerHasFinishedDoingItsJob() {
            theActualPlayer = nil;
        }
        
        bool isComplete()
        {
            //LOG_SOUND("AVAudioPlayerChannel isComplete()"); 
            bool isPlaying;
            
            if (theActualPlayer == nil) {
                // The AVAudioPlayer has been released before
                // , maybe by a stop() or maybe because
                // someone already called this method before
                // , he might be dead by now
                // so we can't ask him if he is playing.
                // We know that we return that it is complete
                isPlaying = false;
            }
            else {
                //LOG_SOUND("AVAudioPlayerChannel invoking isPlaying"); 
                
                // note that we ask the delegate, not the AVAudioPlayer
                // the reason is that technically AVAudioPlayer might not be playing,
                // but we are in the process of restarting it to play a loop,
                // and we don't want to stop him. So we ask the delegate, which
                // knows when all the loops are properly done.
                isPlaying = [thePlayerDelegate isPlaying];
                
                if (!isPlaying) {
                    // the channel is completely done playing, so we mark
                    // both the channel and its delegate eligible for destruction (if no-one
                    // has any more references to them)
                    // If all the channels associated to a Sound will be destroyed,
                    // then the Sound itself might be eligible for destruction (if there are
                    // no more references to it anywhere else).
                    #ifndef OBJC_ARC
                    [thePlayerDelegate release];
                    [theActualPlayer release];
                    #endif
                    theActualPlayer = nil;
                    thePlayerDelegate = nil;
                }
            }
            
            //LOG_SOUND("AVAudioPlayerSound isComplete() returning%@\n", (!isPlaying ? @"YES" : @"NO")); 
            return !isPlaying;
        }
        
        double getLeft()  {
            LOG_SOUND("AVAudioPlayerChannel getLeft()");
            if ([theActualPlayer respondsToSelector: NSSelectorFromString(@"setPan")])	   
            {
                return (1-[theActualPlayer pan])/2;
            }
            return 0.5;
        }
        double getRight()   {
            LOG_SOUND("AVAudioPlayerChannel getRight()");
            if ([theActualPlayer respondsToSelector: NSSelectorFromString(@"setPan")])
            {
                return ([theActualPlayer pan] + 1)/2;
            }
            return 0.5;
        }
        double getPosition()   {
            LOG_SOUND("AVAudioPlayerChannel getPosition()");
            return [theActualPlayer currentTime] * 1000;
        }
        void setTransform(const SoundTransform &inTransform) {
            LOG_SOUND("AVAudioPlayerChannel setTransform()");
            if ([theActualPlayer respondsToSelector: NSSelectorFromString(@"setPan")])
            {
                [theActualPlayer setPan: inTransform.pan];
            }
            [theActualPlayer setVolume: inTransform.volume];
        }
        void stop()
        {
            LOG_SOUND("AVAudioPlayerChannel stop()");
            [theActualPlayer stop];
            
            // note that once a channel has been stopped, it's destined
            // to be deallocated. It will never play another sound again
            // we decrease the reference count here of both the player
            // and its delegate.
            // If someone calls isComplete() in the future,
            // that function will see the nil and avoid doing another
            // release.
            #ifndef OBJC_ARC
            [theActualPlayer release];
            [thePlayerDelegate release];
            #endif
            theActualPlayer = nil;
            thePlayerDelegate = nil;
            
        }
        
        
        Object *mSound;
        AVAudioPlayer *theActualPlayer;
        AVAudioPlayerChannelDelegate *thePlayerDelegate;
        
    };
    
    
    class AVAudioPlayerSound : public Sound
    {
    public:
        AVAudioPlayerSound(const std::string &inFilename) : mFilename(inFilename)
        {
            LOG_SOUND("AVAudioPlayerSound constructor()");
            IncRef();
            
            // we copy the filename to a local variable,
            // We pass the filename to create one AVSoundPlayer
            // each time the sound is played.
            // Note that we don't need the path, the filename suffices.
            //theFileName = [[NSString alloc] initWithUTF8String:inFilename.c_str()];
            
            // to answer the getLength() method and to see whether there will be any
            // ploblems loading the file we create an "initial" AVAudioPlayer
            // that we'll never actually use to play anything. We just get the length and
            // any potential error and we
            // release it soon after. Note that
            // no buffers are loaded until we invoke either the play or prepareToPlay
            // methods, so very little memory is used.
            
            this->data = nil;

            std::string path = GetResourcePath() + gAssetBase + inFilename;
            NSString *ns_name = [[NSString alloc] initWithUTF8String:path.c_str()];
            NSURL  *theFileNameAndPathAsUrl = [NSURL fileURLWithPath:ns_name];
            #ifndef OBJC_ARC
            [ns_name release];
            #endif
            
            NSError *err = nil;
            AVAudioPlayer *theActualPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:theFileNameAndPathAsUrl error:&err];
            if (err != nil)
            {
                mError = [[err description] UTF8String];
            }
            
            theDuration = [theActualPlayer duration] * 1000;
            #ifndef OBJC_ARC
            [theActualPlayer release];
            #endif
        }
        
        AVAudioPlayerSound(unsigned char *inDataPtr, int inDataLen)
        {
            mFilename = "unknown";
            
            LOG_SOUND("AVAudioPlayerSound constructor()");
            IncRef();
            
            printf("AVAudioPlayerSound!!");
            
            this->data = [[NSData alloc] initWithBytes:inDataPtr length:inDataLen];
            
            NSError *err = nil;
            AVAudioPlayer *theActualPlayer = [[AVAudioPlayer alloc] initWithData:data error:&err];
            if (err != nil)
            {
                mError = [[err description] UTF8String];
            }
            
            theDuration = [theActualPlayer duration] * 1000;
#ifndef OBJC_ARC
            [theActualPlayer release];
#endif
        }
        
        ~AVAudioPlayerSound()
        {
            LOG_SOUND("AVAudioPlayerSound destructor() ##################################");
        }
        
        double getLength()
        {
            LOG_SOUND("AVAudioPlayerSound getLength returning %f", theDuration);
            
            // we got the duration stored already and each Sound only ever
            // loads one file - so no need to re-check, return what we have
            return theDuration;
        }
        
        void getID3Value(const std::string &inKey, std::string &outValue)
        {
            LOG_SOUND("AVAudioPlayerSound getID3Value returning empty string");
            outValue = "";
        }
        int getBytesLoaded()
        {
            int toBeReturned = ok() ? 100 : 0;
            LOG_SOUND("AVAudioPlayerSound getBytesLoaded returning %i", toBeReturned);
            return toBeReturned;
        }
        int getBytesTotal()
        {
            int toBeReturned = ok() ? 100 : 0;
            LOG_SOUND("AVAudioPlayerSound getBytesTotal returning %i", toBeReturned);
            return toBeReturned;
        }
        bool ok()
        {
            bool toBeReturned = mError.empty();
            LOG_SOUND("AVAudioPlayerSound ok() returning BOOL = %@\n", (toBeReturned ? @"YES" : @"NO")); 
            return toBeReturned;
        }
        std::string getError()
        {
            LOG_SOUND("AVAudioPlayerSound getError()"); 
            return mError;
        }
        
        void close()
        {
            LOG_SOUND("AVAudioPlayerSound close() doing nothing"); 
        }
        
        // This method is called when Sound.play is called.
        SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
        {
            LOG_SOUND("AVAudioPlayerSound openChannel() startTime=%f, loops = %d",startTime,loops); 
            //return new AVAudioPlayerChannel(this,mBufferID,loops,inTransform);
            
            // this creates the channel, note that the channel is an AVAudioPlayer that plays
            // right away
            return new AVAudioPlayerChannel(this, mFilename, data, loops, startTime, inTransform);
        }
        
        std::string mError;
        std::string mFilename;
        double theDuration;
        NSData *data;
    };
    
    /*----------------------------------------------------------
     OpenAL implementation of Sound and SoundChannel classes:
     - lower latency than AVSoundPlayer
     - fully loads uncompressed sound in memory
     - exposes uncompressed sound data
     ------------------------------------------------------------*/
    
    
    static ALCdevice  *sgDevice = 0;
    static ALCcontext *sgContext = 0;
    //static int numberOfPlayedFiles = 0;
    
    static bool OpenALInit()
    {
        LOG_SOUND("Sound.mm OpenALInit()");
        
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
        enum { STEREO_SAMPLES = 2 };
    public:
        OpenALChannel(Object *inSound,unsigned int inBufferID,
                      int inLoops, const SoundTransform &inTransform)
        {
            LOG_SOUND("OpenALChannel constructor %d",inBufferID);
            mSound = inSound;
            inSound->IncRef();
            mSourceID = 0;
            mDynamicDone = true;
            mDynamicBuffer[0] = 0;
            mDynamicBuffer[1] = 0;
            mDynamicStackSize = 0;
            mSampleBuffer = 0;
            
            if (inBufferID>0)
            {
                // grab a source ID from openAL
                alGenSources(1, &mSourceID); 
                
                // attach the buffer to the source
                alSourcei(mSourceID, AL_BUFFER, inBufferID);
                // set some basic source prefs
                alSourcef(mSourceID, AL_PITCH, 1.0f);
                alSourcef(mSourceID, AL_GAIN, inTransform.volume);
                alSource3f(mSourceID, AL_POSITION, inTransform.pan * 1, 0, 0);
                // TODO: not right!
                if (inLoops>1)
                    alSourcei(mSourceID, AL_LOOPING, AL_TRUE);
                
                alSourcePlay(mSourceID);
            }
        }
        
        OpenALChannel(const ByteArray &inBytes,const SoundTransform &inTransform)
        {
            LOG_SOUND("OpenALChannel dynamic %d",inBytes.Size());
            mSound = 0;
            mSourceID = 0;
            
            mDynamicBuffer[0] = 0;
            mDynamicBuffer[1] = 0;
            mDynamicStackSize = 0;
            mSampleBuffer = 0;
            
            alGenBuffers(2, mDynamicBuffer);
            if (!mDynamicBuffer[0])
            {
                LOG_SOUND("Error creating dynamic sound buffer!");
            }
            else
            {
                mSampleBuffer = new short[8192*STEREO_SAMPLES];
                
                // grab a source ID from openAL
                alGenSources(1, &mSourceID); 
                
                QueueBuffer(mDynamicBuffer[0],inBytes);
                
                if (!mDynamicDone)
                    mDynamicStack[mDynamicStackSize++] = mDynamicBuffer[1];
                
                // set some basic source prefs
                alSourcef(mSourceID, AL_PITCH, 1.0f);
                alSourcef(mSourceID, AL_GAIN, inTransform.volume);
                alSource3f(mSourceID, AL_POSITION, inTransform.pan * 1, 0, 0);
                
                alSourcePlay(mSourceID);
            }
        }
        
        void QueueBuffer(ALuint inBuffer, const ByteArray &inBytes)
        {
            int time_samples = inBytes.Size()/sizeof(float)/STEREO_SAMPLES;
            const float *buffer = (const float *)inBytes.Bytes();
            
            for(int i=0;i<time_samples;i++)
            {
                mSampleBuffer[ i<<1 ] = *buffer++ * ((1<<15)-1);
                mSampleBuffer[ (i<<1) + 1 ] = *buffer++ * ((1<<15)-1);
            }
            
            mDynamicDone = time_samples < 1024;
            
            alBufferData(inBuffer, AL_FORMAT_STEREO16, mSampleBuffer, time_samples*STEREO_SAMPLES*sizeof(short), 44100 );
            
            LOG_SOUND("Dynamic queue buffer %d (%d)", inBuffer, time_samples );
            alSourceQueueBuffers(mSourceID, 1, &inBuffer );
        }
        
        void unqueueBuffers()
        {
            ALint processed = 0;
            alGetSourcei(mSourceID, AL_BUFFERS_PROCESSED, &processed);
            LOG_SOUND("Recover buffers : %d (%d)", processed, mDynamicStackSize);
            if (processed)
            {
                alSourceUnqueueBuffers(mSourceID,processed,&mDynamicStack[mDynamicStackSize]);
                mDynamicStackSize += processed;
            }
        }
        
        
        
        bool needsData()
        {
            if (!mDynamicBuffer[0] || mDynamicDone)
                return false;
            
            unqueueBuffers();
            
            LOG_SOUND("needsData (%d)", mDynamicStackSize);
            if (mDynamicStackSize)
            {
                mDynamicDone = true;
                return true;
            }
            
            return false;
            
        }
        
        void addData(const ByteArray &inBytes)
        {
            if (!mDynamicStackSize)
            {
                LOG_SOUND("Adding data with no buffers?");
                return;
            }
            mDynamicDone = false;
            ALuint buffer = mDynamicStack[0];
            mDynamicStack[0] = mDynamicStack[1];
            mDynamicStackSize--;
            QueueBuffer(buffer,inBytes);
            
            // Make sure it is still playing ...
            if (!mDynamicDone && mDynamicStackSize==1)
            {
                ALint val = 0;
                alGetSourcei(mSourceID, AL_SOURCE_STATE, &val);
                if(val != AL_PLAYING)
                {
                    LOG_SOUND("Kickstart (%d/%d)",val,mDynamicStackSize);
                    
                    // This is an indication that the previous buffer finished playing before we could deliver the new buffer.
                    // You will hear ugly popping noises...
                    alSourcePlay(mSourceID);
                }
            }
        }
        
        
        
        ~OpenALChannel()
        {
            LOG_SOUND("OpenALChannel destructor");
            if (mSourceID)
                alDeleteSources(1, &mSourceID);
            if (mDynamicBuffer[0])
                alDeleteBuffers(2, mDynamicBuffer);
            delete [] mSampleBuffer;
            if (mSound)
                mSound->DecRef();
        }
        
        bool isComplete()
        {
            if (!mSourceID)
            {
                LOG_SOUND("OpenALChannel isComplete() - never started!");
                return true;
            }
            
            if (!mDynamicDone)
                return false;
            
            // got this hint from
            // http://www.gamedev.net/topic/410696-openal-how-to-query-if-a-source-sound-is-playing-solved/
            ALint state;
            alGetSourcei(mSourceID,AL_SOURCE_STATE,&state);
            /*
             Possible values of state
             AL_INITIAL
             AL_STOPPED
             AL_PLAYING
             AL_PAUSED
             */
            if(state == AL_STOPPED)
            {
                LOG_SOUND("OpenALChannel isComplete() returning true");
                return true;
            }
            else
            {
                //LOG_SOUND("OpenALChannel isComplete() returning false");
                return false;
            }
        }
        
        double getLeft()  
        { 
            float panX=0;
            float panY=0;
            float panZ=0;
            alGetSource3f(mSourceID,AL_POSITION,&panX,&panY,&panZ);
            return (1-panX)/2;
        }
        
        double getRight()   
        {
            float panX=0;
            float panY=0;
            float panZ=0;
            alGetSource3f(mSourceID,AL_POSITION,&panX,&panY,&panZ);
            return (panX+1)/2;
        }
        
        double getPosition()  
        {
            float pos = 0;
            alGetSourcef(mSourceID,AL_SEC_OFFSET,&pos);
            return pos*1000;
        }
        
        void setTransform(const SoundTransform &inTransform)
        {
            alSourcef(mSourceID, AL_GAIN, inTransform.volume);
            alSource3f(mSourceID, AL_POSITION, inTransform.pan * 1, 0, 0);
        }
        
        void stop()
        {
        }
        
        
        Object *mSound;
        unsigned int mSourceID;
        short  *mSampleBuffer;
        bool   mDynamicDone;
        ALuint mDynamicStackSize;
        ALuint mDynamicStack[2];
        ALuint mDynamicBuffer[2];
    };
    
    
    SoundChannel *SoundChannel::Create(const ByteArray &inBytes,const SoundTransform &inTransform)
    {
        if (!OpenALInit())
            return 0;
        
        return new OpenALChannel(inBytes, inTransform);
    }
    
    
    
    
    class OpenALSound : public Sound
    {
    public:
        OpenALSound(const std::string &inFilename)
        {
            IncRef();
            mBufferID = 0;
            
            #ifndef OBJC_ARC
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            #endif

            std::string asset = GetResourcePath() + gAssetBase + inFilename;
            
            NSString *url = [[NSString alloc] initWithUTF8String:asset.c_str()];
            // get some audio data from a wave file
            #ifndef OBJC_ARC
            CFURLRef fileURL = (CFURLRef)[[NSURL fileURLWithPath:url] retain];
            #else
            CFURLRef fileURL = (__bridge CFURLRef)[NSURL fileURLWithPath:url];
            #endif
            //[path release];
            
            if (!fileURL)
            {
                LOG_SOUND("OpenALSound constructor() error in url");
                mError = "Error int url: " + inFilename;
            }
            else
            {
                QuickVec<uint8> buffer;
                ALenum  format;
                ALsizei freq;
                
                bool ok = LoadData(fileURL, buffer, &format, &freq);
                
                CFRelease(fileURL);
                
                if (!ok)
                {
                    LOG_SOUND("Error opening sound data");
                    mError = "Error opening sound data";
                }
                else if (alGetError() != AL_NO_ERROR)
                {
                    LOG_SOUND("Error after opening sound data");
                    mError = "Error after opening sound data";
                }
                else
                {
                    // grab a buffer ID from openAL
                    alGenBuffers(1, &mBufferID);
                    
                    // load the awaiting data blob into the openAL buffer.
                    alBufferData(mBufferID,format,&buffer[0],buffer.size(),freq); 
                }
            }
            #ifndef OBJC_ARC
            [pool release];
            #endif
        }
        
        ~OpenALSound()
        {
            LOG_SOUND("OpenALSound destructor() ###################################");
            if (mBufferID!=0)
                alDeleteBuffers(1, &mBufferID);
        }
        
        
        bool LoadData(CFURLRef inFileURL, QuickVec<uint8> &outBuffer,
                      ALenum *outDataFormat, ALsizei*   outSampleRate)
        {
            LOG_SOUND("OpenALSound LoadData()");
            
            OSStatus err = noErr;
            SInt64 theFileLengthInFrames = 0;
            AudioStreamBasicDescription theFileFormat;
            UInt32 thePropertySize = sizeof(theFileFormat);
            ExtAudioFileRef extRef = NULL;
            AudioStreamBasicDescription theOutputFormat;
                        
            // Open a file with ExtAudioFileOpen()
            LOG_SOUND("OpenALSound Open a file with ExtAudioFileOpen()");            
            err = ExtAudioFileOpenURL(inFileURL, &extRef);
            if (err)
            {
                LOG_SOUND("OpenALSound Could not load audio data");
                mError = "Could not load audio data";
                return false;
            }
            
            LOG_SOUND("OpenALSound Getting the audio data format");
            // Get the audio data format
            err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileDataFormat,
                                          &thePropertySize, &theFileFormat);
            
            if (err)
            {
                LOG_SOUND("OpenALSound Could not get FileDataFormat");
                mError = "Could not get FileDataFormat";
            }
            else if (theFileFormat.mChannelsPerFrame > 2)
            {
                LOG_SOUND("OpenALSound Too many channels");
                mError = "Too many channels";
            }
            
            
            if (ok())
            {
                LOG_SOUND("OpenALSound ok() was true so Set the  client format to 16 bit signed integer (native-endian) data Maintain the  channel count and sample rate of the original source format");
                
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
                {
                    LOG_SOUND("Could not set output format");
                    mError = "Could not set output format";
                }
            }
            
            if (ok())
            {
                // Get the total frame count
                thePropertySize = sizeof(theFileLengthInFrames);
                err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileLengthFrames,
                                              &thePropertySize, &theFileLengthInFrames);
                if(err)
                {
                    LOG_SOUND("OpenALSound Could not get the number of frames");
                    mError = "Could not get the number of frames";
                }
            }
            
            if (ok())
            {
                // Read all the data into memory
                UInt32 dataSize = theFileLengthInFrames * theOutputFormat.mBytesPerFrame;;
                LOG_SOUND("OpenALSound dataSize: %u", dataSize);
                outBuffer.resize(dataSize);
                
                AudioBufferList theDataBuffer;
                theDataBuffer.mNumberBuffers = 1;
                theDataBuffer.mBuffers[0].mDataByteSize = dataSize;
                theDataBuffer.mBuffers[0].mNumberChannels = theOutputFormat.mChannelsPerFrame;
                theDataBuffer.mBuffers[0].mData = &outBuffer[0];
                
                // Read the data into an AudioBufferList
                err = ExtAudioFileRead(extRef, (UInt32*)&theFileLengthInFrames, &theDataBuffer);
                if (err)
                {
                    LOG_SOUND("OpenALSound dataSize: %u", dataSize);
                    mError = "Read audio buffer";
                }
                else
                {
                    LOG_SOUND("OpenALSound success");
                    // success
                    *outDataFormat = (theOutputFormat.mChannelsPerFrame > 1) ?
                    AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
                    *outSampleRate = (ALsizei)theOutputFormat.mSampleRate;
                }
                
            }
            
            if (extRef)
            {
                LOG_SOUND("OpenALSound calling ExtAudioFileDispose");
                ExtAudioFileDispose(extRef);
            }
            return ok();
        }
        
        
        
        double getLength()
        {
            double toBeReturned = ok() ? 1 : 0;
            LOG_SOUND("OpenALSound getLength returning %f", toBeReturned);
            return toBeReturned;
        }
        
        void getID3Value(const std::string &inKey, std::string &outValue)
        {
            LOG_SOUND("OpenALSound getID3Value returning empty string");
            outValue = "";
        }
        int getBytesLoaded()
        {
            int toBeReturned = ok() ? 100 : 0;
            LOG_SOUND("OpenALSound getBytesLoaded returning %i", toBeReturned);
            return toBeReturned;
        }
        
        int getBytesTotal()
        {
            int toBeReturned = ok() ? 100 : 0;
            LOG_SOUND("OpenALSound getBytesTotal returning %i", toBeReturned);
            return toBeReturned;
        }
        bool ok()
        {
            bool toBeReturned = mError.empty();
            LOG_SOUND("OpenALSound ok() returning BOOL = %@\n", (toBeReturned ? @"YES" : @"NO")); 
            return toBeReturned;
        }
        std::string getError()
        {
            LOG_SOUND("OpenALSound getError()"); 
            return mError;
        }
        void close()
        {
            LOG_SOUND("OpenALSound close() doing nothing"); 
        }
        
        SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
        {
            LOG_SOUND("OpenALSound openChannel()"); 
            return new OpenALChannel(this,mBufferID,loops,inTransform);
        }
        
        unsigned int mBufferID;
        std::string mError;
    };
    
    
    Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
    {
        // Here we pick a Sound object based on either OpenAL or Apple's AVSoundPlayer
        // depending on the inForceMusic flag.
        //
        // OpenAL has lower latency but can be expensive memory-wise when playing
        // files more than a few seconds long, and it's not really needed anyways if there is
        // no need to work with the uncompressed data.
        //
        // AVAudioPlayer has slightly higher latency and doesn't give access to uncompressed
        // sound data, but uses "Apple's optimized pathways" and doesn't need to store
        // uncompressed sound data in memory.
        //
        // By default the OpenAL implementation is picked, while AVAudioPlayer is used then
        // inForceMusic is true.
        
        LOG_SOUND("Sound.mm Create()"); 
        if (inForceMusic)
        {
            return new AVAudioPlayerSound(inFilename);
        }
        else
        {
            if (!OpenALInit())
                return 0;
            return new OpenALSound(inFilename);
        }
    }
    
    Sound *Sound::Create(unsigned char *inData, int len, bool inForceMusic)
    {
        // Here we pick a Sound object based on either OpenAL or Apple's AVSoundPlayer
        // depending on the inForceMusic flag.
        //
        // OpenAL has lower latency but can be expensive memory-wise when playing
        // files more than a few seconds long, and it's not really needed anyways if there is
        // no need to work with the uncompressed data.
        //
        // AVAudioPlayer has slightly higher latency and doesn't give access to uncompressed
        // sound data, but uses "Apple's optimized pathways" and doesn't need to store
        // uncompressed sound data in memory.
        //
        // By default the OpenAL implementation is picked, while AVAudioPlayer is used then
        // inForceMusic is true.
        
        LOG_SOUND("Sound.mm Create()");
        return new AVAudioPlayerSound(inData, len);
    }
    
    
} // end namespace nme