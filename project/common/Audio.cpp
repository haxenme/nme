#include <Audio.h>
	
#include <cstdio>
#include <iostream>
#include <vorbis/vorbisfile.h>
	//The audio interface is to embed functions which are to be implemented in 
	//the platform specific layers. 

namespace nme {

		#define LOG_SOUND(args,...) printf(args)
		// #define LOG_SOUND(args,...)  { }

	namespace Audio {


		bool CompareBuffer(const char* apBuffer, const char* asMatch, size_t aSize) {

			for (int p= 0; p < aSize; ++p) {
				if (apBuffer[p] != asMatch[p]) return false;
			}

			return true;
		}

		AudioFormat determineAudioTypeFromMagic( const QuickVec<unsigned char> &bytes ) {
			//todo
            return eAF_unknown;
		}

		std::string _get_extension(const std::string& _filename) {
	    	if(_filename.find_last_of(".") != std::string::npos)
	        	return _filename.substr(_filename.find_last_of(".")+1);
	    	return "";
		} //_get_extension

		AudioFormat determineAudioTypeFromFilename( const std::string &filename ) {
			
			std::string extension = _get_extension(filename);

			if( extension.compare("ogg") == 0 || extension.compare("oga") == 0)
				return eAF_ogg;
			else if( extension.compare("wav") == 0)
				return eAF_wav;
			
			return eAF_unknown;		

		} //determineAudioTypeFromFilename

		bool loadOggData(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate) {

                // 0 for Little-Endian, 1 for Big-Endian
            int endian = 0;
            int bitStream;
            long bytes = 1;

            #define BUFFER_SIZE 32768
            char array[BUFFER_SIZE]; 

            FILE *f;

                //Read the file data
            f = fopen(inFileURL, "rb");

            if(!f) {
                LOG_SOUND("FAILED to read sound file, file pointer as null? \n");
                return false;
            }

                //vorbis data
            vorbis_info *pInfo;
            OggVorbis_File oggFile;
                //Read the file data
            ov_open(f, &oggFile, NULL, 0);
                //Get the file information
            pInfo = ov_info(&oggFile, -1);            
                //Make sure this is a valid file
            if(pInfo == NULL) {
                LOG_SOUND("FAILED TO READ OGG SOUND INFO, IS THIS EVEN AN OGG FILE?\n");
                return false;
            }

            	//The number of channels
            *channels = pInfo->channels;  
            	//default to 16? todo 
            *bitsPerSample = 16;          
                //Return the same rate as well
            *outSampleRate = pInfo->rate;

            while (bytes > 0) {
                    // Read up to a buffer's worth of decoded sound data
                bytes = ov_read(&oggFile, array, BUFFER_SIZE, endian, 2, 1, &bitStream);
                    // Append to end of buffer
                outBuffer.InsertAt(outBuffer.size(), (unsigned char*)array, bytes);
            }

            ov_clear(&oggFile);         

            #undef BUFFER_SIZE

            return true;

		} //loadOggData

		bool loadWavData(const char *inFileURL, QuickVec<unsigned char> &outBuffer, int *channels, int *bitsPerSample, int* outSampleRate) {
            
            //http://www.dunsanyinteractive.com/blogs/oliver/?p=72

            //Local Declarations
            FILE* f = NULL;
            WAVE_Format wave_format;
            RIFF_Header riff_header;
            WAVE_Data wave_data;
            unsigned char* data;
         
            f = fopen(inFileURL, "rb");

            if (!f) {
                LOG_SOUND("FAILED to read sound file, file pointer as null? \n");
                return false;
            }
         
            // Read in the first chunk into the struct
            fread(&riff_header, sizeof(RIFF_Header), 1, f);
         
                //check for RIFF and WAVE tag in memeory
            if  (
                    (riff_header.chunkID[0] != 'R'  ||
                     riff_header.chunkID[1] != 'I'  ||
                     riff_header.chunkID[2] != 'F'  ||
                     riff_header.chunkID[3] != 'F') ||
                     (riff_header.format[0] != 'W'  ||
                      riff_header.format[1] != 'A'  ||
                      riff_header.format[2] != 'V'  ||
                      riff_header.format[3] != 'E')
                ) {
                    LOG_SOUND("Invalid RIFF or WAVE Header! ");
                    return false;
                }
                
         
                //Read in the 2nd chunk for the wave info
            fread(&wave_format, sizeof(WAVE_Format), 1, f);

                //check for fmt tag in memory
            if (wave_format.subChunkID[0] != 'f' ||
                wave_format.subChunkID[1] != 'm' ||
                wave_format.subChunkID[2] != 't' ||
                wave_format.subChunkID[3] != ' ') 
            {
                    LOG_SOUND("Invalid Wave Format! ");
                    return false;
            }

                //check for extra parameters;
            if (wave_format.subChunkSize > 16) {
                fseek(f, sizeof(short), SEEK_CUR);
            }
         
                //Read in the the last byte of data before the sound file
            fread(&wave_data, sizeof(WAVE_Data), 1, f);

                //check for data tag in memory
            if (wave_data.subChunkID[0] != 'd' ||
                wave_data.subChunkID[1] != 'a' ||
                wave_data.subChunkID[2] != 't' ||
                wave_data.subChunkID[3] != 'a') {
                    LOG_SOUND("Invalid Wav Data Header! ");
                    return false;
                }
         
                //Allocate memory for data
            data = new unsigned char[wave_data.subChunk2Size];
         
            // Read in the sound data into the soundData variable
            if (!fread(data, wave_data.subChunk2Size, 1, f)) {
                LOG_SOUND("error loading WAVE data into struct!  ");
                return false;
            }   

                //Store in the outbuffer
            outBuffer.Set(data,  wave_data.subChunk2Size);
         
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

		} //loadWavData


	} //namespace Audio

} //nme


