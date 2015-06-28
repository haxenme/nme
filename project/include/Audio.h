#ifndef AUDIO_H
#define AUDIO_H

#include <nme/QuickVec.h>
#include <Sound.h>
#include <Utils.h>

#ifdef ANDROID
#include <android/log.h>
#endif


#if 0
   #ifdef ANDROID
      #define LOG_SOUND(args,...) ELOG(args, ##__VA_ARGS__);
   #elif defined(IPHONE)
      #define LOG_SOUND(args,...) NmeLog(args, ##__VA_ARGS__);
   #elif defined(TIZEN)
      #include <FBase.h>
      #define LOG_SOUND(args,...) AppLog(args, ##__VA_ARGS__);
   #else
      #define LOG_SOUND(args,...) printf(args, ##__VA_ARGS__);
   #endif
#else
   #define LOG_SOUND(args,...)  { }
#endif


namespace nme
{
	class AudioStream
	{
	public:
      static AudioStream *createOgg();
		virtual ~AudioStream() {}
		
      virtual bool open(const std::string &path, int startTime)=0;
		virtual double getLength(const std::string &path) = 0;
		virtual double getPosition() = 0;
		virtual double setPosition(const float &inFloat) = 0;
		virtual int fillBuffer(char *outBuffer, int inRequestBytes) = 0;
		virtual void rewind() = 0;
      virtual int getRate() = 0;
      virtual int isStereo() = 0;
      virtual bool isValid() = 0;

	};
	
	enum AudioFormat
	{
		eAF_unknown,
		eAF_auto,
		eAF_ogg,
		eAF_wav,
		eAF_mp3,
		eAF_mid,
		eAF_count
	};
	
	namespace Audio
	{
		AudioFormat determineFormatFromBytes(const float *inData, int len);
		AudioFormat determineFormatFromFile(const std::string &filename);
		
		bool loadOggSampleFromBytes(const float *inData, int len, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);
		bool loadOggSampleFromFile(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);
		
		bool loadWavSampleFromBytes(const float *inData, int len, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);
		bool loadWavSampleFromFile(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);
	}
	
	struct RIFF_Header
	{
		char chunkID[4];
		unsigned int chunkSize; //size not including chunkSize or chunkID
		char format[4];
	};
	
	struct WAVE_Format
	{
		char subChunkID[4];
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
		char subChunkID[4]; //should contain the word data
		unsigned int subChunkSize; //Stores the size of the data block
	};

}

#endif
