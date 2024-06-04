#include "Audio.h"

#include <ByteArray.h>
#include <cstdio>
#include <iostream>
#include <vorbis/vorbisfile.h>

#ifdef NME_MODPLUG
#define MODPLUG_STATIC
#include <modplug.h>
#endif

//The audio interface is to embed functions which are to be implemented in 
//the platform specific layers. 


namespace
{

enum
{
   #ifdef HXCPP_BIG_ENDIAN
   OggEndianFlag = 1,
   #else
   OggEndianFlag = 0,
   #endif
   Ogg16Bits = 2,
   OggSigned = 1,
};


// === WAV ======

struct RIFF_Header
{
   unsigned char chunkID[4];
   unsigned int chunkSize; //size not including chunkSize or chunkID
   unsigned char format[4];
};

struct WAVE_Format
{
   unsigned char subChunkID[4];
   unsigned int subChunkSize;
   short audioFormat;
   short numChannels;
   unsigned int sampleRate;
   unsigned int byteRate;
   short blockAlign;
   short bitsPerSample;
};

struct WAVE_Data
{
   unsigned char subChunkID[4]; //should contain the word data
   unsigned int subChunkSize; //Stores the size of the data block
};

bool SameBuffer(const unsigned char* inSrc, const char* inTest, size_t inSize)
{
   return !memcmp(inSrc,inTest,inSize);
}


template<typename T>
inline const unsigned char*readStruct(T& dest, const unsigned char*& ptr)
{
   const unsigned char* ret = 0;
   memcpy(&dest, ptr, sizeof(T));
   ptr += sizeof(WAVE_Data);
   ret = ptr;
   ptr += dest.subChunkSize;
   return ret;
}


const unsigned char* find_chunk(const unsigned char* start, const unsigned char* end, const unsigned char* chunkID)
{
   WAVE_Data chunk;
   const unsigned char* ptr = start;
   while (ptr < (end - sizeof(WAVE_Data)))
   {
      memcpy(&chunk, ptr, sizeof(WAVE_Data));

      if (chunk.subChunkID[0] == chunkID[0] &&
         chunk.subChunkID[1] == chunkID[1] &&
         chunk.subChunkID[2] == chunkID[2] &&
         chunk.subChunkID[3] == chunkID[3])
      {
         return ptr;
      }
      ptr += sizeof(WAVE_Data) + chunk.subChunkSize;
   }
   return 0;
}




bool parseWav(const unsigned char *inData, int len,
                            int *outChannels, int *outBitsPerSample, int* outSampleRate,
                            const unsigned char *&outData, int &outDataLength)
{
   const unsigned char* start = inData;
   const unsigned char* end = start + len;
   const unsigned char* ptr = start;
   WAVE_Format wave_format;
   RIFF_Header riff_header;
   WAVE_Data wave_data;
   unsigned char* data;
   
   // Read in the first chunk into the struct
   memcpy(&riff_header, ptr, sizeof(RIFF_Header));
   ptr += sizeof(RIFF_Header);
   
   //check for RIFF and WAVE tag in memeory
   if ((riff_header.chunkID[0] != 'R'  ||
      riff_header.chunkID[1] != 'I'  ||
      riff_header.chunkID[2] != 'F'  ||
      riff_header.chunkID[3] != 'F') ||
      (riff_header.format[0] != 'W'  ||
      riff_header.format[1] != 'A'  ||
      riff_header.format[2] != 'V'  ||
      riff_header.format[3] != 'E'))
   {
      LOG_SOUND("Invalid RIFF or WAVE Header!\n");
      return false;
   }
   
   //Read in the 2nd chunk for the wave info
   ptr = find_chunk(ptr, end, (const unsigned char *)"fmt ");
   if (!ptr) {
      return false;
   }
   readStruct(wave_format, ptr);
   
   //check for fmt tag in memory
   if (wave_format.subChunkID[0] != 'f' ||
      wave_format.subChunkID[1] != 'm' ||
      wave_format.subChunkID[2] != 't' ||
      wave_format.subChunkID[3] != ' ') 
   {
      LOG_SOUND("Invalid Wave Format!\n");
      return false;
   }
   
   ptr = find_chunk(ptr, end, (const unsigned char *)"data");
   if (!ptr) {
      return false;
   }
   
   const unsigned char* base = readStruct(wave_data, ptr);
   
   //check for data tag in memory
   if (wave_data.subChunkID[0] != 'd' ||
      wave_data.subChunkID[1] != 'a' ||
      wave_data.subChunkID[2] != 't' ||
      wave_data.subChunkID[3] != 'a')
   {
      LOG_SOUND("Invalid Wav Data Header!\n");
      return false;
   }
   
   //Allocate memory for data
   //data = new unsigned char[wave_data.subChunk2Size];
   
   // Read in the sound data into the soundData variable
   size_t size = wave_data.subChunkSize;
   if (size > (end - base)) {
      return false;
   }
   
   //Store in the outbuffer
   outData = base;
   outDataLength = size;
   
   //Now we set the variables that we passed in with the
   //data from the structs
   *outSampleRate = (int)wave_format.sampleRate;
   
   //The format is worked out by looking at the number of
   //channels and the bits per sample.
   *outChannels = wave_format.numChannels;
   *outBitsPerSample = wave_format.bitsPerSample;
   
   
   return true;
}



// === OGG ======


struct NME_OggMemoryFile
{
   const unsigned char* data;
   ogg_int64_t    size;
   ogg_int64_t    pos;
};



size_t NME_OggBufferRead(void* dest, size_t eltSize, size_t nelts, NME_OggMemoryFile* src)
{
   size_t len = eltSize * nelts;
   if ( (src->pos + len) > src->size)
      len = src->size - src->pos;

   if (len > 0)
   {
      memcpy( dest, (src->data + src->pos), len);
      src->pos += len;
   }
   return len;
}

int NME_OggBufferSeek(NME_OggMemoryFile* src, ogg_int64_t pos, int whence)
{
   switch (whence)
   {
      case SEEK_CUR: src->pos += pos; break;
      case SEEK_END: src->pos = src->size - pos; break;
      case SEEK_SET: src->pos = pos; break;
      default:
         return -1;
   }
   if (src->pos < 0)
   {
      src->pos = 0;
      return -1;
   }
   return (src->pos > src->size) ? -1 : 0;
}


int NME_OggBufferClose(NME_OggMemoryFile* src) { return 0; }

long NME_OggBufferTell(NME_OggMemoryFile *src) { return src->pos; }


static ov_callbacks NmeOggApi =
{
   (size_t (*)(void *, size_t, size_t, void *)) NME_OggBufferRead,
   (int (*)(void *, ogg_int64_t, int))          NME_OggBufferSeek,
   (int (*)(void *))                            NME_OggBufferClose,
   (long (*)(void *))                           NME_OggBufferTell
};

} // end anon namespace


namespace nme
{

bool isMp3(const std::string &inFilename)
{
   return inFilename.size()>3 && inFilename.substr( inFilename.size()-3,2 )=="mp";
}


AudioFormat determineFormatFromBytes(const unsigned char *inData, int len)
{
   if (len >= 35 && SameBuffer(inData, "OggS", 4) && SameBuffer(&inData[28], "\x01vorbis", 7))
      return eAF_ogg;

   if (len >= 12 && SameBuffer(inData, "RIFF", 4) && SameBuffer(&inData[8], "WAVE", 4))
      return eAF_wav;

   if (len>4 && SameBuffer(inData, "MThd", 4))
      return eAF_mid;

   return eAF_unknown;
}

AudioFormat determineFormatFromFile(const std::string &inFilename)
{
   if (isMp3(inFilename))
      return eAF_mp3;

   unsigned char buf[41];
   memset(buf,0,sizeof(buf));

   FILE *file = OpenRead(inFilename.c_str());
   if (file)
   {
      fread(buf, sizeof(buf), 1, file);
      fclose(file);
      return determineFormatFromBytes(buf,sizeof(buf));
   }
   
   return eAF_unknown;
}



bool loadWavSampleFromBytes(const unsigned char *inData, int len,
                            QuickVec<unsigned char> &outBuffer,
                            int *outChannels, int *outBitsPerSample, int* outSampleRate)
{
   const unsigned char *rawData = 0;
   int rawLength = 0;
   if (parseWav(inData, len, outChannels, outBitsPerSample, outSampleRate, rawData, rawLength) )
   {
      outBuffer.Set(rawData, rawLength);
      return true;
   }
   return false;
}






} // end namespace nme







namespace nme
{



class NmeSoundStream : public INmeSoundStream 
{
public:
   INmeSoundData *data;
   int           samplePosition;
   int           channelSampleCount;
   int           channelCount;
   double        sampleTime;

   NmeSoundStream(INmeSoundData *inData)
   {
      data = inData->addRef();
      samplePosition = 0;
      channelSampleCount = data->getChannelSampleCount();
      channelCount = data->getIsStereo() ? 2:1;
      sampleTime = 1.0 / data->getRate();
   }
   ~NmeSoundStream()
   {
      data->release();
   }


   virtual double getPosition()
   {
      return sampleTime * samplePosition;  // + delta
   }
   virtual void   rewind()
   {
      setPosition(0);
   }

   virtual int    getRate() const { return data->getRate(); }
   virtual double getDuration() const { return data->getDuration(); }
   virtual int    getChannelSampleCount() const { return channelSampleCount; }
   virtual bool   getIsStereo() const { return channelCount==2; }

};



class NmeSoundStreamOgg : public NmeSoundStream 
{
   OggVorbis_File file;
   NME_OggMemoryFile oggData;
   bool ok;
   bool open;
 
public:

   // Data stays alive while we have a refernece to inData
   NmeSoundStreamOgg(INmeSoundData *inSound, const unsigned char *inData, int inLength)
     : NmeSoundStream(inSound)
   {
      oggData.data = inData;
      oggData.size = inLength;
      oggData.pos = 0;
         
      ok = (ov_open_callbacks(&oggData, &file, NULL, 0, NmeOggApi) == 0);
      open = ok;
   }

   ~NmeSoundStreamOgg()
   {
      if (open)
        ov_clear(&file);
   }

   bool isValid() const
   {
      return ok && getChannelSampleCount();
   }
       
   virtual int fillBuffer(char *outBuffer, int inRequestBytes)
   {
      if (!ok)
         return 0;

      int bitStream = 0;
      int remaining = inRequestBytes;
      while(remaining>0)
      {
         int bytes = ov_read(&file, outBuffer, remaining, OggEndianFlag, Ogg16Bits, OggSigned, &bitStream);
         if (bytes<=0)
            return inRequestBytes-remaining;

         remaining -= bytes;
         outBuffer += bytes;
      }
 
      return inRequestBytes;
   }

   virtual double setPosition(double inSeconds)
   {
      ov_time_seek(&file, inSeconds);
      return inSeconds;
   }
};







#ifdef NME_MODPLUG

class NmeSoundStreamMid : public NmeSoundStream 
{
   ModPlugFile *modFile;
 
public:

   // Data stays alive while we have a refernece to inData
   NmeSoundStreamMid(INmeSoundData *inSound, const unsigned char *inData, int inLength)
     : NmeSoundStream(inSound)
   {
      modFile = ModPlug_Load(inData, inLength);
   }

   ~NmeSoundStreamMid()
   {
      if (modFile)
        ModPlug_Unload(modFile);
   }

   bool isValid() const
   {
      return modFile && getChannelSampleCount();
   }
       
   virtual int fillBuffer(char *outBuffer, int inRequestBytes)
   {
      if (!modFile)
         return 0;

      char *buffer = outBuffer;
      int bitStream = 0;
      int remaining = inRequestBytes;
      while(remaining>0)
      {
         int bytes = ModPlug_Read(modFile, buffer, remaining);
         // Stopping early might be ok, since timing might not be 100 % accurate
         if (bytes<=0)
            return inRequestBytes-remaining;

         remaining -= bytes;
         outBuffer += bytes;
      }
 
      return inRequestBytes;
   }

   virtual double setPosition(double inSeconds)
   {
      ModPlug_Seek(modFile, inSeconds*1000.0);
      return inSeconds;
   }
};

#endif













class NmeSoundData : public INmeSoundData
{
public:
   int refCount;
   unsigned int flags;
   double duration;
   int    rate;
   bool   isStereo;
   bool   isDecoded;
   int    channelSampleCount;
   QuickVec<short> decodedBuffer;
   QuickVec<unsigned char> sourceBuffer;
   AudioFormat fileFormat;

   NmeSoundData(const unsigned char *inData, int inDataLength, unsigned int inFlags)
   {
      refCount = 1;
      flags = inFlags;
      init(0,true);

      fileFormat = determineFormatFromBytes(inData, inDataLength);
      switch(fileFormat)
      {
         case eAF_wav:
            decodeWav(inData, inDataLength);
            break;

         case eAF_ogg:
            parseOgg(inData, inDataLength, flags);
            break;

         #ifdef NME_MODPLUG
         case eAF_mid:
            parseMid(inData, inDataLength, flags);
            break;
         #endif

         default:
            ;
      }
   }

   NmeSoundData(const short *inData, int inChannelSamples, bool inIsStereo, int inRate)
   {
      init(inChannelSamples, inIsStereo, inRate);
      int shorts = channelSampleCount * (isStereo?2:1);
      decodedBuffer.Set(inData,shorts);
      isDecoded = true;
   }

   void init(int inChannelSamples, bool inIsStereo, int inRate=44100)
   {
      isDecoded = false;
      isStereo = inIsStereo;
      rate = inRate;
      channelSampleCount = inChannelSamples;
      duration = rate>0 ? (double)channelSampleCount/rate : 0;
   }

   INmeSoundData  *addRef()
   {
      refCount++;
      return this;
   }

   void release()
   {
      refCount--;
      if (refCount<=0)
         delete this;
   }



   void decodeWav(const unsigned char *inData, int inDataLength)
   {
      const unsigned char *rawData = 0;
      int rawLength = 0;
      int channelCount = 0;
      int bitsPerSample = 0;
      int rate = 0;
      if (parseWav(inData, inDataLength, &channelCount, &bitsPerSample, &rate, rawData, rawLength) )
      {
         bool stereo = channelCount==2;

         if (!(flags & SoundJustInfo))
         {
            if (bitsPerSample==16)
            {
               decodedBuffer.Set( (short *)rawData, rawLength/sizeof(short) );
            }
            else if (bitsPerSample==8)
            {
               decodedBuffer.resize(rawLength);
               short *dest = decodedBuffer.mPtr;
               const char *src = (const char  *)rawData;
               for(int i=0;i<rawLength;i++)
                  dest[i] = src[i]*256;
            }
            else
               return;
         }

         init( rawLength/((stereo?2:1)*sizeof(short)), stereo, rate);

         isDecoded = !(flags & SoundJustInfo);
      }
   }


   #ifdef NME_MODPLUG
   void parseMid(const unsigned char *inData, int inDataLength, unsigned int inFlags)
   {
      static bool modPlugInit = false;
      static ModPlug_Settings settings;

      if (!modPlugInit)
      {
         modPlugInit = true;
         ModPlug_GetSettings(&settings);
         settings.mFlags=MODPLUG_ENABLE_OVERSAMPLING;
         settings.mChannels=2;
         settings.mBits=16;
         settings.mFrequency=44100; /* 11025, 22050, or 44100 ? */
         settings.mResamplingMode=MODPLUG_RESAMPLE_FIR;
         settings.mReverbDepth=0;
         settings.mReverbDelay=100;
         settings.mBassAmount=0;
         settings.mBassRange=50;
         settings.mSurroundDepth=0;
         settings.mSurroundDelay=10;
         settings.mLoopCount=0;
         ModPlug_SetSettings(&settings);
      }

      ModPlugFile *modFile = ModPlug_Load(inData, inDataLength);
      if (modFile)
      {
         fileFormat = eAF_mid;
         rate = settings.mFrequency;
         isStereo = settings.mChannels = 2;
         duration = ModPlug_GetLength(modFile) * 0.001;
         channelSampleCount = duration*44100;
         
         if (!(inFlags & SoundJustInfo))
         {
            if (duration<=2.0 || (inFlags & SoundForceDecode) )
            {
               isDecoded = true;
               decodedBuffer.resize((int)channelSampleCount * (isStereo?2:1) );
               char *buffer = (char *)decodedBuffer.ByteData();
               int remaining = decodedBuffer.ByteCount();
               int bitStream = 0;
               while(remaining>0)
               {
                  int bytes = ModPlug_Read(modFile, buffer, remaining);
                  if (bytes<=0)
                  {
                     // Stopping early might be ok, since timing might not be 100 % accurate
                     decodedBuffer.resize( decodedBuffer.size() - remaining/sizeof(short) );
                     break;
                  }
                  remaining -= bytes;
                  buffer += bytes;
               }
            }
            else
            {
               sourceBuffer.Set(inData,inDataLength);
            }
         }
         ModPlug_Unload(modFile);
      }
   }
   #endif

 

   void parseOgg(const unsigned char *inData, int inDataLength, unsigned int inFlags)
   {
      NME_OggMemoryFile memoryFile = { inData, inDataLength, 0 };
      OggVorbis_File ovFileHandle;

      if (ov_open_callbacks(&memoryFile, &ovFileHandle, NULL, 0, NmeOggApi) == 0)
      {
         vorbis_info *pInfo = ov_info(&ovFileHandle, -1);
         if (pInfo)
         {
            int channels = pInfo->channels;
            int rate = pInfo->rate;

            ogg_int64_t samples = ov_pcm_total(&ovFileHandle,-1);
            if (samples!=OV_EINVAL)
            {
               init((int)samples, channels==2, rate);
               if (!(inFlags & SoundJustInfo))
               {
                  if (duration<=2.0 || (inFlags & SoundForceDecode) )
                  {
                     isDecoded = true;
                     decodedBuffer.resize((int)samples * (isStereo?2:1) );
                     char *buffer = (char *)decodedBuffer.ByteData();
                     int remaining = decodedBuffer.ByteCount();
                     int bitStream = 0;
                     while(remaining>0)
                     {
                        int bytes = ov_read(&ovFileHandle, buffer, remaining, OggEndianFlag, Ogg16Bits, OggSigned, &bitStream);
                        if (bytes<=0)
                        {
                           LOG_SOUND("Error decoding ogg samples");
                           // Error !
                           channelSampleCount = 0;
                           isDecoded = false;
                           break;
                        }
                        remaining -= bytes;
                        buffer += bytes;
                     }
                  }
                  else
                  {
                     sourceBuffer.Set(inData,inDataLength);
                  }
               }
            }
         }
         else
         {
            LOG_SOUND("Bad Ogg file");
         }

         ov_clear(&ovFileHandle);
      }
   }


   double getDuration() const { return duration; }
   int    getChannelSampleCount() const { return channelSampleCount; }
   bool   getIsStereo() const { return isStereo; }
   int    getRate() const { return rate; }
   bool   getIsDecoded() const { return isDecoded; }

   short *decodeAll()
   {
      if (!isDecoded && sourceBuffer.size())
         parseOgg(sourceBuffer.ByteData(), sourceBuffer.ByteCount(), SoundForceDecode);

      if (!isDecoded || !channelSampleCount)
         return 0;

      return decodedBuffer.mPtr;
   }

   int getDecodedByteCount() const
   {
      return decodedBuffer.ByteCount();
   }


   INmeSoundStream *createStream()
   {
      if (channelSampleCount<1)
      {
         LOG_SOUND("Error creating stream - no samples");
         return 0;
      }

      if (fileFormat==eAF_ogg)
         return new NmeSoundStreamOgg(this, sourceBuffer.ByteData(), sourceBuffer.ByteCount());

      #ifdef NME_MODPLUG
      if (fileFormat==eAF_mid)
         return new NmeSoundStreamMid(this, sourceBuffer.ByteData(), sourceBuffer.ByteCount());
      #endif

      LOG_SOUND("Error creating stream - unknown format");
      return 0;
   }

};



INmeSoundData *INmeSoundData::create(const std::string &inId, unsigned int inFlags)
{
   ByteArray bytes = ByteArray::FromFile(inId.c_str());
   if (!bytes.Ok())
      bytes = ByteArray(inId.c_str());
   if (!bytes.Ok())
   {
      LOG_SOUND("Could not create sound resource %s", inId.c_str());
      return 0;
   }

   const unsigned char *data = bytes.Bytes();
   int length = bytes.Size();

   if (!length || !data)
   {
      LOG_SOUND("Sound resource is invalid %s", inId.c_str());
      return 0;
   }

   return create(data,length,inFlags);
}

INmeSoundData *INmeSoundData::create(const unsigned char *inData, int inDataLength, unsigned int inFlags)
{
   INmeSoundData *result = new NmeSoundData(inData, inDataLength, inFlags);
   if (result->getChannelSampleCount()==0)
   {
      result->release();
      result = 0;
      #if defined(HX_WINDOWS) && !defined(NME_NO_WINACM)
      result = createAcm(inData, inDataLength, inFlags);
      if (result && !result->getChannelSampleCount())
      {
         result->release();
         result = 0;
      }
      #endif
   }

   if (!result)
      LOG_SOUND("Can't create sound from data - channel count is zero.");
   return result;
}

INmeSoundData *INmeSoundData::create(const short *inData, int inChannelSamples, bool inIsStereo, int inRate)
{
   if (inChannelSamples==0)
   {
      LOG_SOUND("Can't create sound with no channels");
      return 0;
   }

   return new NmeSoundData(inData, inChannelSamples, inIsStereo, inRate);
}


} // End namespace nme

