#include <Audio.h>

#include <ByteArray.h>
#include <cstdio>
#include <iostream>
#include <vorbis/vorbisfile.h>

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

   virtual int fillBuffer(char *outBuffer, int inRequestBytes)
   {
      return inRequestBytes;
   }

   virtual double getPosition()
   {
      return sampleTime * samplePosition;  // + delta
   }
   virtual void setPosition(double inSeconds)
   {
      // TODO
   }

   virtual void   rewind()
   {
      setPosition(0);
   }

   virtual double getDuration() { return data->getDuration(); }
   virtual int    getChannelSampleCount() { return channelSampleCount; }
   virtual bool   getIsStereo() { return channelCount==2; }

};



INmeSoundStream *INmeSoundStream::create(INmeSoundData *inData)
{
   return new NmeSoundStream(inData);
}







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
                  if (duration<=2.0 || (inFlags & SoundForceDecode))
                  {
                     isDecoded = true;
                     decodedBuffer.resize((int)samples * isStereo?2:1 );
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

   INmeSoundStream *createStream()
   {
      if (channelSampleCount<1)
         return 0;

      return INmeSoundStream::create(this);
   }

};



INmeSoundData *create(const std::string &inId, unsigned int inFlags)
{
   return 0;
}

INmeSoundData *create(const unsigned char *inData, int inDataLength, unsigned int inFlags)
{
   NmeSoundData *result = new NmeSoundData(inData, inDataLength, inFlags);
   if (result->getChannelSampleCount()==0)
   {
      result->release();
      return 0;
   }
   return 0;
}

INmeSoundData *create(const short *inData, int inChannelSamples, bool inIsStereo, int inRate)
{
   if (inChannelSamples==0)
      return 0;

   return new NmeSoundData(inData, inChannelSamples, inIsStereo, inRate);
}





} // End namespace nme





namespace nme
{
   // Old Api ....

      
      
      
      
      std::string _get_extension(const std::string& _filename)
      {
         if(_filename.find_last_of(".") != std::string::npos)
            return _filename.substr(_filename.find_last_of(".") + 1);
         return "";
      }
      
      
      
      
      AudioFormat determineFormatFromFile(const std::string &filename)
      {
         std::string extension = _get_extension(filename);
         
         if( extension.compare("ogg") == 0 || extension.compare("oga") == 0)
            return eAF_ogg;
         else if( extension.compare("wav") == 0)
            return eAF_wav;
         else if (extension.compare("mid") == 0)
            return eAF_mid;
         
         AudioFormat format = eAF_unknown;
         
         #ifdef ANDROID
         FileInfo info = AndroidGetAssetFD(filename.c_str());
         FILE *f = fdopen(info.fd, "rb");
         
         if(f) 
         {
             fseek(f, info.offset, 0);
         }
         
         #else
         FILE *f = fopen(filename.c_str(), "rb");
         #endif
         
         int len = 35;
         unsigned char *bytes = (unsigned char*)calloc(len + 1, sizeof(unsigned char));
         
         if (f)
         {
            if (fread(bytes, 1, len, f))
            {
               fclose(f);
               format = determineFormatFromBytes(bytes, len);
            }
            
            fclose(f);
         }
         
         free(bytes);
         return format;
      }
      
      
      bool loadOggSample(OggVorbis_File &oggFile, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate)
      {
         // 0 for Little-Endian, 1 for Big-Endian
         
         int bitStream;
         long bytes = 1;
         int totalBytes = 0;
         
         #define BUFFER_SIZE 32768
         
         //Get the file information
         //vorbis data
         vorbis_info *pInfo = ov_info(&oggFile, -1);            
         //Make sure this is a valid file
         if (pInfo == NULL)
         {
            LOG_SOUND("FAILED TO READ OGG SOUND INFO, IS THIS EVEN AN OGG FILE?\n");
            return false;
         }
         
         //The number of channels
         *channels = pInfo->channels;
         //default to 16? todo 
         *bitsPerSample = 16;
         //Return the same rate as well
         *outSampleRate = pInfo->rate;
         
         // Seem to need four times the read PCM total
         outBuffer.resize(ov_pcm_total(&oggFile, -1)*4);
         
         while (bytes > 0)
         {
            if (outBuffer.size() < totalBytes + BUFFER_SIZE)
            {
               outBuffer.resize(totalBytes + BUFFER_SIZE);
            }
            // Read up to a buffer's worth of decoded sound data
            bytes = ov_read(&oggFile, (char*)outBuffer.begin() + totalBytes, BUFFER_SIZE, OggEndianFlag, Ogg16Bits, OggSigned, &bitStream);
            totalBytes += bytes;
         }
         
         outBuffer.resize(totalBytes);
         ov_clear(&oggFile);
         
         #undef BUFFER_SIZE
         
         return true;
      }
      
      
      bool loadOggSampleFromBytes(const unsigned char *inData, int len, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate)
      {
         NME_OggMemoryFile fakeFile = { inData, len, 0 };
         OggVorbis_File ovFileHandle;
         
         if (ov_open_callbacks(&fakeFile, &ovFileHandle, NULL, 0, NmeOggApi) == 0)
         {
            return loadOggSample(ovFileHandle, outBuffer, channels, bitsPerSample, outSampleRate);
         }
         
         return false;
      }
      
      
      bool loadOggSampleFromFile(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate)
      {
         FILE *f = 0;
         
         //Read the file data
         #ifdef ANDROID
         FileInfo info = AndroidGetAssetFD(inFileURL);
         f = fdopen(info.fd, "rb");
         fseek(f, info.offset, 0);
         #else
         f = fopen(inFileURL, "rb");
         #endif
         
         if (!f)
         {
            LOG_SOUND("FAILED to read \"%s\" file, file pointer as null?\n",inFileURL);
            return false;
         }
         
         OggVorbis_File oggFile;
         //Read the file data
         #ifdef ANDROID
         ov_open(f, &oggFile, NULL, info.length);
         #else
         ov_open(f, &oggFile, NULL, 0);
         #endif
         
         return loadOggSample(oggFile, outBuffer, channels, bitsPerSample, outSampleRate);
      }
      
      
      
      
      bool loadWavSampleFromFile(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate)
      {
         //http://www.dunsanyinteractive.com/blogs/oliver/?p=72
         
         //Local Declarations
         FILE* f = NULL;
         WAVE_Format wave_format;
         RIFF_Header riff_header;
         WAVE_Data wave_data;
         unsigned char* data;
         
         #ifdef ANDROID
         FileInfo info = AndroidGetAssetFD(inFileURL);
         f = fdopen(info.fd, "rb");
         fseek(f, info.offset, 0);
         #else
         f = fopen(inFileURL, "rb");
         #endif
         
         if (!f)
         {
            LOG_SOUND("FAILED to read sound file, file pointer as null?\n");
            return false;
         }
         
         // Read in the first chunk into the struct
         int result = fread(&riff_header, sizeof(RIFF_Header), 1, f);
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
         
         long int currentHead = 0;
         bool foundFormat = false;
         while (!foundFormat)
         {
            // Save the current position indicator of the stream
            currentHead = ftell(f);
            
            //Read in the 2nd chunk for the wave info
            result = fread(&wave_format, sizeof(WAVE_Format), 1, f);
            
            if (result != 1)
            {
               LOG_SOUND("Invalid Wave Format!\n");
               return false;
            }
            
            //check for fmt tag in memory
            if (wave_format.subChunkID[0] != 'f' ||
               wave_format.subChunkID[1] != 'm' ||
               wave_format.subChunkID[2] != 't' ||
               wave_format.subChunkID[3] != ' ') 
            {
               // TODO - wave_data is uninitialized - nice catch VisualStudio
               fseek(f, wave_data.subChunkSize, SEEK_CUR);
            }
            else
            {
               foundFormat = true;
            }
         }
         
         //check for extra parameters;
         if (wave_format.subChunkSize > 16)
         {
            fseek(f, sizeof(short), SEEK_CUR);
         }
         
         bool foundData = false;
         while (!foundData)
         {
            // Save the current position indicator of the stream
            currentHead = ftell(f);
            
            //Read in the the last byte of data before the sound file
            result = fread(&wave_data, sizeof(WAVE_Data), 1, f);
            
            if (result != 1)
            {
               LOG_SOUND("Invalid Wav Data Header!\n");
               return false;
            }
            
            if (wave_data.subChunkID[0] != 'd' ||
            wave_data.subChunkID[1] != 'a' ||
            wave_data.subChunkID[2] != 't' ||
            wave_data.subChunkID[3] != 'a')
            {
               //fseek(f, wave_data.subChunkSize, SEEK_CUR);
               //fseek(f, wave_data.subChunkSize, SEEK_CUR);
               // Goto next chunk.
               fseek(f, currentHead + sizeof(WAVE_Data) + wave_data.subChunkSize, SEEK_SET);
            }
            else
            {
               foundData = true;
            }
         }
         
         //Allocate memory for data
         data = new unsigned char[wave_data.subChunkSize];
         
         // Read in the sound data into the soundData variable
         if (!fread(data, wave_data.subChunkSize, 1, f))
         {
            LOG_SOUND("error loading WAVE data into struct!\n");
            return false;
         }   
         
         //Store in the outbuffer
         outBuffer.Set(data, wave_data.subChunkSize);
         
         //Now we set the variables that we passed in with the
         //data from the structs
         *outSampleRate = (int)wave_format.sampleRate;
         
         //The format is worked out by looking at the number of
         //channels and the bits per sample.
         *channels = wave_format.numChannels;
         *bitsPerSample = wave_format.bitsPerSample;
         
         //clean up and return true if successful
         fclose(f);
         delete[] data;
         
         return true;
      }
      
      
}
