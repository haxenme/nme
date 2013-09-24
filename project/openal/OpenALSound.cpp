
#ifdef HX_MACOS
   
#include <OpenAL/al.h>
#include <OpenAL/alc.h>

#else

#include <AL/al.h>
#include <AL/alc.h>

#endif

#include <Sound.h>
#include <QuickVec.h>
#include <Utils.h>

//new audio api to handle loading
//sounds and streams from various formats.
#include <Audio.h>

#ifdef ANDROID
#include <android/log.h>
#endif


typedef unsigned char uint8;


#ifdef ANDROID
#define LOG_SOUND(args,...) ELOG(args)
#else
#define LOG_SOUND(args,...) printf(args)
#endif
//#define LOG_SOUND(args...)  { }


namespace nme
{
    
    bool gSDLIsInit = false;
    
    
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
        //LOG_SOUND("Sound.mm OpenALInit()");
        
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
            //LOG_SOUND("OpenALChannel constructor %d",inBufferID);
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
            //LOG_SOUND("OpenALChannel dynamic %d",inBytes.Size());
            mSound = 0;
            mSourceID = 0;
            
            mDynamicBuffer[0] = 0;
            mDynamicBuffer[1] = 0;
            mDynamicStackSize = 0;
            mSampleBuffer = 0;
            
            alGenBuffers(2, mDynamicBuffer);
            if (!mDynamicBuffer[0])
            {
                //LOG_SOUND("Error creating dynamic sound buffer!");
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
            
            //LOG_SOUND("Dynamic queue buffer %d (%d)", inBuffer, time_samples );
            alSourceQueueBuffers(mSourceID, 1, &inBuffer );
        }
        
        void unqueueBuffers()
        {
            ALint processed = 0;
            alGetSourcei(mSourceID, AL_BUFFERS_PROCESSED, &processed);
            //LOG_SOUND("Recover buffers : %d (%d)", processed, mDynamicStackSize);
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
            
            //LOG_SOUND("needsData (%d)", mDynamicStackSize);
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
                //LOG_SOUND("Adding data with no buffers?");
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
                    //LOG_SOUND("Kickstart (%d/%d)",val,mDynamicStackSize);
                    
                    // This is an indication that the previous buffer finished playing before we could deliver the new buffer.
                    // You will hear ugly popping noises...
                    alSourcePlay(mSourceID);
                }
            }
        }
        
        
        
        ~OpenALChannel()
        {
            //LOG_SOUND("OpenALChannel destructor");
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
                //LOG_SOUND("OpenALChannel isComplete() - never started!");
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
                //LOG_SOUND("OpenALChannel isComplete() returning true");
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
        
        double setPosition(const float &inFloat)  {
            alSourcef(mSourceID,AL_SEC_OFFSET,inFloat);
            return inFloat;
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

             #ifdef HX_MACOS
             char fileURL[1024];
             GetBundleFilename(inFilename.c_str(),fileURL,1024);
             #else
             const char *fileURL = inFilename.c_str();
             #endif
            
            if (!fileURL) {
                
                //LOG_SOUND("OpenALSound constructor() error in url");
                mError = "Error int url: " + inFilename;

            } else {

                QuickVec<uint8> buffer;
                int _channels;
                int _bitsPerSample;
                ALenum  format;
                ALsizei freq;
                bool ok = false; 

                    //Determine the file format before we try anything
                AudioFormat type = Audio::determineFormatFromFile(std::string(fileURL));

                switch(type) {
                    case eAF_ogg:
                        ok = Audio::loadOggSampleFromFile( fileURL, buffer, &_channels, &_bitsPerSample, &freq );
                    break;
                    case eAF_wav:
                        ok = Audio::loadWavSampleFromFile( fileURL, buffer, &_channels, &_bitsPerSample, &freq );
                    break;
                    default:
                        LOG_SOUND("Error opening sound file, unsupported type.\n");
                }

                    //Work out the format from the data
                if (_channels == 1) {
                    if (_bitsPerSample == 8 ) {
                        format = AL_FORMAT_MONO8;
                    } else if (_bitsPerSample == 16) {
                        format = (int)AL_FORMAT_MONO16;
                    }
                } else if (_channels == 2) {
                    if (_bitsPerSample == 8 ) {
                        format = (int)AL_FORMAT_STEREO8;
                    } else if (_bitsPerSample == 16) {
                        format = (int)AL_FORMAT_STEREO16;
                    }
                } //channels = 2
                 
                
                if (!ok) {
                    LOG_SOUND("Error opening sound data\n");
                    mError = "Error opening sound data";
                } else if (alGetError() != AL_NO_ERROR) {
                    LOG_SOUND("Error after opening sound data\n");
                    mError = "Error after opening sound data";  
                } else {
                        // grab a buffer ID from openAL
                    alGenBuffers(1, &mBufferID);
                    
                        // load the awaiting data blob into the openAL buffer.
                    alBufferData(mBufferID,format,&buffer[0],buffer.size(),freq); 

                        // once we have all our information loaded, get some extra flags
                    alGetBufferi(mBufferID, AL_SIZE, &bufferSize);
                    alGetBufferi(mBufferID, AL_FREQUENCY, &frequency);
                    alGetBufferi(mBufferID, AL_CHANNELS, &channels);    
                    alGetBufferi(mBufferID, AL_BITS, &bitsPerSample); 
                    
                } //!ok
            }
        }
        
        OpenALSound(float *inData, int len)
        {
            IncRef();
            mBufferID = 0;
            
            QuickVec<uint8> buffer;
            int _channels;
            int _bitsPerSample;
            ALenum  format;
            ALsizei freq;
            bool ok = false; 
            
            //Determine the file format before we try anything
            AudioFormat type = Audio::determineFormatFromBytes(inData, len);
            
            switch(type) {
                case eAF_ogg:
                    ok = Audio::loadOggSampleFromBytes(inData, len, buffer, &_channels, &_bitsPerSample, &freq );
                break;
                case eAF_wav:
                    ok = Audio::loadWavSampleFromBytes(inData, len, buffer, &_channels, &_bitsPerSample, &freq );
                break;
                default:
                    LOG_SOUND("Error opening sound file, unsupported type.\n");
            }
            
            //Work out the format from the data
            if (_channels == 1) {
                if (_bitsPerSample == 8 ) {
                    format = AL_FORMAT_MONO8;
                } else if (_bitsPerSample == 16) {
                    format = (int)AL_FORMAT_MONO16;
                }
            } else if (_channels == 2) {
                if (_bitsPerSample == 8 ) {
                    format = (int)AL_FORMAT_STEREO8;
                } else if (_bitsPerSample == 16) {
                    format = (int)AL_FORMAT_STEREO16;
                }
            } //channels = 2
             
            
            if (!ok) {
                LOG_SOUND("Error opening sound data\n");
                mError = "Error opening sound data";
            } else if (alGetError() != AL_NO_ERROR) {
                LOG_SOUND("Error after opening sound data\n");
                mError = "Error after opening sound data";  
            } else {
                    // grab a buffer ID from openAL
                alGenBuffers(1, &mBufferID);
                
                    // load the awaiting data blob into the openAL buffer.
                alBufferData(mBufferID,format,&buffer[0],buffer.size(),freq); 

                    // once we have all our information loaded, get some extra flags
                alGetBufferi(mBufferID, AL_SIZE, &bufferSize);
                alGetBufferi(mBufferID, AL_FREQUENCY, &frequency);
                alGetBufferi(mBufferID, AL_CHANNELS, &channels);    
                alGetBufferi(mBufferID, AL_BITS, &bitsPerSample); 
                
            }
        }
        
        ~OpenALSound()
        {
            //LOG_SOUND("OpenALSound destructor() ###################################");
            if (mBufferID!=0)
                alDeleteBuffers(1, &mBufferID);
        }
        
        double getLength()
        {
            double result = ((double)bufferSize) / (frequency * channels * (bitsPerSample/8) );

            //LOG_SOUND("OpenALSound getLength returning %f", toBeReturned);
            return result;
        }
        
        void getID3Value(const std::string &inKey, std::string &outValue)
        {
            //LOG_SOUND("OpenALSound getID3Value returning empty string");
            outValue = "";
        }
        int getBytesLoaded()
        {
            int toBeReturned = ok() ? 100 : 0;
            //LOG_SOUND("OpenALSound getBytesLoaded returning %i", toBeReturned);
            return toBeReturned;
        }
        
        int getBytesTotal()
        {
            int toBeReturned = ok() ? 100 : 0;
            //LOG_SOUND("OpenALSound getBytesTotal returning %i", toBeReturned);
            return toBeReturned;
        }
        bool ok()
        {
            bool toBeReturned = mError.empty();
            //LOG_SOUND("OpenALSound ok() returning BOOL = %@\n", (toBeReturned ? @"YES" : @"NO")); 
            return toBeReturned;
        }
        std::string getError()
        {
            //LOG_SOUND("OpenALSound getError()"); 
            return mError;
        }
        void close()
        {
            //LOG_SOUND("OpenALSound close() doing nothing"); 
        }
        
        SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
        {
            //LOG_SOUND("OpenALSound openChannel()"); 
            return new OpenALChannel(this,mBufferID,loops,inTransform);
        }
        
        ALint bufferSize;
        ALint frequency;
        ALint bitsPerSample;
        ALint channels;

        unsigned int mBufferID;
        std::string mError;
    };
    
    
    Sound *Sound::Create(const std::string &inFilename,bool inForceMusic) {

        //Always check if openal is intitialized
        if (!OpenALInit())
            return 0;

        //Return a reference
        return new OpenALSound(inFilename);
    }
    
    Sound *Sound::Create(float *inData, int len, bool inForceMusic)
    {
        //Always check if openal is intitialized
        if (!OpenALInit())
            return 0;

        //Return a reference
        return new OpenALSound(inData, len);
    }
    
    
} // end namespace nme