#ifndef AUDIO_H
#define AUDIO_H

#include <QuickVec.h>
#include <Utils.h>

namespace nme {

	class AudioSample {

	};

	class AudioStream {

	};

	enum AudioFormat {
		eAF_unknown,
		eAF_auto,
		eAF_ogg,
		eAF_wav,
		eAF_mp3,
		eAF_count
	};

		//The main audio interface
	namespace Audio {

		AudioFormat determineAudioTypeFromMagic( const QuickVec<unsigned char> &bytes );
		AudioFormat determineAudioTypeFromFilename( const std::string &filename );

			//Loading formats
		bool loadOggData(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);
		bool loadWavData(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate);

	} //namespace Audio



//Wav format info
	struct RIFF_Header {
	  char chunkID[4];
	  unsigned int chunkSize;//size not including chunkSize or chunkID
	  char format[4];
	};

	struct WAVE_Format {
	  char subChunkID[4];
	  unsigned int subChunkSize;
	  short audioFormat;
	  short numChannels;
	  unsigned int sampleRate;
	  unsigned int byteRate;
	  short blockAlign;
	  short bitsPerSample;
	};

	struct WAVE_Data {
	  char subChunkID[4]; //should contain the word data
	  unsigned int subChunk2Size; //Stores the size of the data block
	};

} //namespace nme

#endif //AUDIO_H