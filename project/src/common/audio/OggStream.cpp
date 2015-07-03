#include <math.h>
#include <vorbis/vorbisfile.h>
#include <string>
#include <Audio.h>

namespace nme
{
 
//Ogg specific stream implementation
class AudioStream_Ogg : public AudioStream
{
public:
    FILE*           oggFile;
    OggVorbis_File* oggStream;
    vorbis_info*    vorbisInfo;
    vorbis_comment* vorbisComment;
    std::string mPath;
    bool mIsValid;
    int mChannels;
    int mRate;

    
    #ifdef ANDROID
    
    FileInfo mInfo;
    off_t mFilePosition;
    
    static size_t read_func(void* ptr, size_t size, size_t nmemb, void* datasource)
    {
        AudioStream_Ogg *stream = (AudioStream_Ogg*)datasource;
        long pos = ftell(stream->oggFile);
        
        if (pos + size*nmemb > stream->mInfo.length + stream->mInfo.offset)
        {
           nmemb = 1;
           size = stream->mInfo.length + stream->mInfo.offset - pos;
           if (size <= 0)
           {
             return 0;
           }
        }
        
        return fread(ptr, size, nmemb, stream->oggFile);
    }

    static int seek_func(void* datasource, ogg_int64_t offset, int whence)
    {
        AudioStream_Ogg *stream = (AudioStream_Ogg*)datasource;
        long pos = 0;
        
        if (whence == SEEK_SET)
            pos = stream->mInfo.offset + (unsigned int)offset;
        else if (whence == SEEK_CUR)
            pos = ftell(stream->oggFile) + (unsigned int)offset;
        else if (whence == SEEK_END)
            pos = stream->mInfo.offset + stream->mInfo.length;
         
        if (pos > stream->mInfo.offset + stream->mInfo.length) pos = stream->mInfo.offset + stream->mInfo.length;
        return fseek(stream->oggFile, pos, 0);
    }

    static int close_func(void* datasource)
    {
        AudioStream_Ogg *stream = (AudioStream_Ogg*)datasource;
        return fclose(stream->oggFile);
    }

    static long tell_func(void* datasource)
    {
        AudioStream_Ogg *stream = (AudioStream_Ogg*)datasource;
        return (long)ftell(stream->oggFile) - stream->mInfo.offset;
    }
    
    #endif



 
   //Ogg Audio Stream implementation
   AudioStream_Ogg()
   {
      mIsValid = false;
      oggFile = 0;
      oggStream = 0;
      mChannels = 1;
      mRate = 8192;
   }

   ~AudioStream_Ogg()
   {
     if (oggStream)
     {
         ov_clear(oggStream);
         delete oggStream;
         oggStream = 0;
         oggFile = 0;
     }
     
     mIsValid = false;
   }

   int getRate() { return mRate; }
   int isStereo() { return mChannels==2; }
   bool isValid() { return mIsValid; }

  
   
   double getLength(const std::string &path)
   {
        int result;
        mPath = std::string(path.c_str());
        mIsValid = true;
        
        #ifdef ANDROID
        
        mInfo = AndroidGetAssetFD(path.c_str());
        oggFile = fdopen(mInfo.fd, "rb");
        fseek(oggFile, mInfo.offset, 0);
        
        ov_callbacks callbacks;
        callbacks.read_func = &nme::AudioStream_Ogg::read_func;
        callbacks.seek_func = &nme::AudioStream_Ogg::seek_func;
        callbacks.close_func = &nme::AudioStream_Ogg::close_func;
        callbacks.tell_func = &nme::AudioStream_Ogg::tell_func;
        
        #else
        
        oggFile = fopen(path.c_str(), "rb");
        
        #endif
        
        if(!oggFile)
        {
            //throw std::string("Could not open Ogg file.");
            LOG_SOUND("Could not open Ogg file.");
            mIsValid = false;
            return 0;
        }
        
        oggStream = new OggVorbis_File();
        
        #ifdef ANDROID
        result = ov_open_callbacks(this, oggStream, NULL, 0, callbacks);
        #else
        result = ov_open(oggFile, oggStream, NULL, 0);
        #endif
        
        if(result < 0)
        {
            fclose(oggFile);
            oggFile = 0;
         
            //throw std::string("Could not open Ogg stream. ") + errorString(result);
            LOG_SOUND("Could not open Ogg stream.");
            //LOG_SOUND(errorString(result).c_str());
            mIsValid = false;
            return 0;
        }
        
        return ov_time_total(oggStream, -1);
   }
   
   
   bool open(const std::string &path, int startTime)
   {
        int result;
        mPath = std::string(path.c_str());
        mIsValid = true;
        
        #ifdef ANDROID
        
        mInfo = AndroidGetAssetFD(path.c_str());
        oggFile = fdopen(mInfo.fd, "rb");
        fseek(oggFile, mInfo.offset, 0);
        
        ov_callbacks callbacks;
        callbacks.read_func = &nme::AudioStream_Ogg::read_func;
        callbacks.seek_func = &nme::AudioStream_Ogg::seek_func;
        callbacks.close_func = &nme::AudioStream_Ogg::close_func;
        callbacks.tell_func = &nme::AudioStream_Ogg::tell_func;
        
        #else
        
        oggFile = fopen(path.c_str(), "rb");
        
        #endif
        
        if(!oggFile) {
            //throw std::string("Could not open Ogg file.");
            LOG_SOUND("Could not open Ogg file.");
            mIsValid = false;
            return false;
        }
        
        oggStream = new OggVorbis_File();
        
        #ifdef ANDROID
        result = ov_open_callbacks(this, oggStream, NULL, 0, callbacks);
        #else
        result = ov_open(oggFile, oggStream, NULL, 0);
        #endif
         
        if(result < 0) {
         
            fclose(oggFile);
            oggFile = 0;
         
            //throw std::string("Could not open Ogg stream. ") + errorString(result);
            LOG_SOUND("Could not open Ogg stream.");
            //LOG_SOUND(errorString(result).c_str());
            mIsValid = false;
            return false;
        }

        vorbisInfo = ov_info(oggStream, -1);
        vorbisComment = ov_comment(oggStream, -1);

        mChannels = vorbisInfo->channels;
        mRate = vorbisInfo->rate;

        if (startTime != 0)
        {
          double seek = startTime * 0.001;
          ov_time_seek(oggStream, seek);
        }

        return true;
   }

	virtual int fillBuffer(char *outBuffer, int inRequestBytes)
   {
      int section = 0;
      return ov_read(oggStream, outBuffer, inRequestBytes, 0, 2, 1, &section);
   }

   void rewind()
   {
      ov_time_seek(oggStream, 0);
   }


   std::string errorString(int code)
   {
      switch(code)
      {

           case OV_EREAD:
               return std::string("Read from media.");
           case OV_ENOTVORBIS:
               return std::string("Not Vorbis data.");
           case OV_EVERSION:
               return std::string("Vorbis version mismatch.");
           case OV_EBADHEADER:
               return std::string("Invalid Vorbis header.");
           case OV_EFAULT:
               return std::string("Internal logic fault (bug or heap/stack corruption.");
           default:
               return std::string("Unknown Ogg error.");

       }

   }
   
   
   double setPosition(const float &inFloat)
   {
      double seek = inFloat * 0.001;
      ov_time_seek(oggStream, seek);
      return inFloat;
   }
   
   
   double getPosition() 
   {
      double pos = ov_time_tell(oggStream);
      return pos * 1000.0;
   }
};


AudioStream *AudioStream::createOgg()
{
   return new AudioStream_Ogg();
}

}
