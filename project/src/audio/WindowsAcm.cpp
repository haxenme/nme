#include <windows.h>
#include <stdio.h>
#include <mmreg.h>
#include <msacm.h>
#include <wmsdk.h>
#include <Utils.h>
#include "Audio.h"
 
 
namespace nme
{

#define DYN_LINK(API,ret,func,args) \
   typedef ret (API *func##Func) args; \
   func##Func func##Ptr = 0;


#define DYN_LOAD(func) \
   func##Ptr = (func##Func)GetProcAddress(module,#func); \
   if (!func##Ptr) return false;



DYN_LINK(STDMETHODCALLTYPE,HRESULT, WMCreateSyncReader,(IUnknown *pUnkCert,DWORD dwRights, IWMSyncReader **ppSyncReader) ) 
DYN_LINK(ACMAPI,MMRESULT, acmMetrics, (HACMOBJ hao, UINT    uMetric, LPVOID  pMetric) )
DYN_LINK(ACMAPI,MMRESULT, acmStreamOpen, ( LPHACMSTREAM   phas, HACMDRIVER     had, LPWAVEFORMATEX pwfxSrc, LPWAVEFORMATEX pwfxDst, LPWAVEFILTER   pwfltr, DWORD_PTR      dwCallback, DWORD_PTR      dwInstance, DWORD          fdwOpen) )
DYN_LINK(ACMAPI,MMRESULT,  acmStreamClose, ( HACMSTREAM has, DWORD      fdwClose) )
DYN_LINK(ACMAPI,MMRESULT, acmStreamSize,( HACMSTREAM has, DWORD      cbInput, LPDWORD    pdwOutputBytes, DWORD      fdwSize) )
DYN_LINK(ACMAPI,MMRESULT, acmStreamConvert, ( HACMSTREAM        has, LPACMSTREAMHEADER pash, DWORD             fdwConvert) )
DYN_LINK(ACMAPI,MMRESULT, acmStreamPrepareHeader,( HACMSTREAM        has, LPACMSTREAMHEADER pash, DWORD             fdwPrepare) )
DYN_LINK(ACMAPI,MMRESULT, acmStreamUnprepareHeader, ( HACMSTREAM        has, LPACMSTREAMHEADER pash, DWORD             fdwUnprepare) )



static bool triedInit = false;
static bool isInit = false;
bool initAcm()
{
   if (!triedInit)
   {
      triedInit = true;

      HMODULE module = LoadLibraryA("wmvcore.dll");
      if (!module) return false;

      DYN_LOAD(WMCreateSyncReader)

      module = LoadLibraryA("msacm32.dll");
      if (!module) return false;

      DYN_LOAD(acmMetrics)
      DYN_LOAD(acmStreamOpen)
      DYN_LOAD(acmStreamClose)
      DYN_LOAD(acmStreamSize)
      DYN_LOAD(acmStreamConvert)
      DYN_LOAD(acmStreamPrepareHeader)
      DYN_LOAD(acmStreamUnprepareHeader)

      isInit = true;
   }
   return isInit;
}



const DWORD MP3_BLOCK_SIZE = 522;




class AcmSoundData : public INmeSoundData
{
public:
   QuickVec<short> decodedBuffer;
   double duration;
   int rate;
   int channels;
   int sampleCount;
   int refCount;

 
   AcmSoundData(const unsigned char* mp3InputBuffer, DWORD mp3InputBufferSize, int inFlags)
   {
      IWMSyncReader* wmSyncReader = 0;
      IWMHeaderInfo* wmHeaderInfo = 0;
      IWMProfile* wmProfile = 0;
      IWMStreamConfig* wmStreamConfig = 0;
      IWMMediaProps* wmMediaProperties = 0;
      WORD wmStreamNum = 0;
      WMT_ATTR_DATATYPE wmAttrDataType;
      DWORD maxFormatSize = 0;
      HGLOBAL mp3HGlobal = 0;
      rate = 0;
      channels = 0;
      sampleCount = 0;
      refCount = 1;
 
      bool error = !nmeCoInitialize();
    
      // Create SyncReader

      error = error || WMCreateSyncReaderPtr(  NULL, WMT_RIGHT_PLAYBACK , &wmSyncReader );
     
      void* mp3HGlobalBuffer = 0;
      if (!error)
      {
         mp3HGlobal = GlobalAlloc(GPTR, mp3InputBufferSize);
         if (mp3HGlobal)
         {
            mp3HGlobalBuffer = GlobalLock(mp3HGlobal);
            memcpy(mp3HGlobalBuffer, mp3InputBuffer, mp3InputBufferSize);
            GlobalUnlock(mp3HGlobal);
         }
         else
            error = true;
      }

      IStream* mp3Stream = 0;
      error = error || CreateStreamOnHGlobal(mp3HGlobal, FALSE, &mp3Stream);
 
      error = error || wmSyncReader->OpenStream(mp3Stream);
 
      if (!error)
        error = wmSyncReader->QueryInterface(&wmHeaderInfo);
 
      if (!error)
      {
         QWORD durationInNano = 0;
         // Retrieve mp3 song duration in seconds
         WORD lengthDataType = sizeof(QWORD);
         error = wmHeaderInfo->GetAttributeByName(&wmStreamNum, L"Duration", &wmAttrDataType, (BYTE*)&durationInNano, &lengthDataType );
         duration = ((double)durationInNano)/10000000.0;
     }
 
      // Sequence of call to get the MediaType
      // WAVEFORMATEX for mp3 can then be extract from MediaType
      error = error || wmSyncReader->QueryInterface(&wmProfile);
      error = error || wmProfile->GetStream(0, &wmStreamConfig);
      error = error || wmStreamConfig->QueryInterface(&wmMediaProperties);
 
      // Retrieve sizeof MediaType
      DWORD sizeMediaType = 0;
      error = error || wmMediaProperties->GetMediaType(NULL, &sizeMediaType);
 
      // Retrieve MediaType
      WM_MEDIA_TYPE* mediaType = sizeMediaType ? (WM_MEDIA_TYPE*)LocalAlloc(LPTR,sizeMediaType) : 0; 
      error = error || wmMediaProperties->GetMediaType(mediaType, &sizeMediaType);
 
      // Check that MediaType is audio
      error = error || (mediaType->majortype != WMMEDIATYPE_Audio);
      // assert(mediaType->pbFormat == WMFORMAT_WaveFormatEx);
  
      // Check that input is mp3
      if (!error)
      {
         WAVEFORMATEX* inputFormat = (WAVEFORMATEX*)mediaType->pbFormat;
         rate = inputFormat->nSamplesPerSec;
         channels = inputFormat->nChannels;
         sampleCount = (int)(duration*rate + 0.99999); 
      }
 
      // Release COM interface
      if (wmMediaProperties)
         wmMediaProperties->Release();
      if (wmStreamConfig)
         wmStreamConfig->Release();
      if (wmProfile)
         wmProfile->Release();
      if (wmHeaderInfo)
         wmHeaderInfo->Release();
      if (wmSyncReader)
         wmSyncReader->Release();
 
      // Free allocated mem
      if (mediaType)
         LocalFree(mediaType);

      if (!error && !(inFlags & SoundJustInfo))
      {
         HACMSTREAM acmMp3stream = 0;

         // Define input format
         MPEGLAYER3WAVEFORMAT mp3Format =
         {
            {
               (WORD)WAVE_FORMAT_MPEGLAYER3,   // WORD        wFormatTag;         /* format type */
               (WORD)channels,        // WORD        nChannels;          /* number of channels (i.e. mono, stereo...) */
               (DWORD)rate,       // DWORD       nSamplesPerSec;     /* sample rate */
               128 * (1024 / 8),  // DWORD       nAvgBytesPerSec;    not really used but must be one of 64, 96, 112, 128, 160kbps
               1,        // WORD        nBlockAlign;        /* block size of data */
               0,        // WORD        wBitsPerSample;     /* number of bits per sample of mono data */
               MPEGLAYER3_WFX_EXTRA_BYTES,  // WORD        cbSize;        
            },
            MPEGLAYER3_ID_MPEG,      // WORD          wID;
            (DWORD)MPEGLAYER3_FLAG_PADDING_OFF,   // DWORD         fdwFlags;
            MP3_BLOCK_SIZE,       // WORD          nBlockSize;
            1,          // WORD          nFramesPerBlock;
            1393,       // WORD          nCodecDelay;
         };

         // Define output format
         WAVEFORMATEX pcmFormat =
         {
            WAVE_FORMAT_PCM, // WORD        wFormatTag;         /* format type */
            (WORD)channels,     // WORD        nChannels;          /* number of channels (i.e. mono, stereo...) */
            (DWORD)rate,    // DWORD       nSamplesPerSec;     /* sample rate */
            channels * rate * sizeof(short),   // DWORD       nAvgBytesPerSec;    /* for buffer estimation */
            (WORD)channels * sizeof(short),     // WORD        nBlockAlign;        /* block size of data */
            (WORD)sizeof(short)*8,     // WORD        wBitsPerSample;     /* number of bits per sample of mono data */
            0,     // WORD        cbSize;             /* the count in bytes of the size of */
         };


    
        // -----------------------------------------------------------------------------------
        // Convert mp3 to pcm using acm driver
        // The following code is mainly inspired from http://david.weekly.org/code/mp3acm.html
        // -----------------------------------------------------------------------------------
       
        // Get maximum FormatSize for all acm
        error = error || acmMetricsPtr( NULL, ACM_METRIC_MAX_SIZE_FORMAT, &maxFormatSize );
    
        // Allocate PCM output sound buffer
        if (!error)
           decodedBuffer.resize( sampleCount * channels );

        if (!error)
        {
           HRESULT result =  acmStreamOpenPtr( &acmMp3stream,    // Open an ACM conversion stream
              NULL,                       // Query all ACM drivers
              (LPWAVEFORMATEX)&mp3Format, // input format :  mp3
              &pcmFormat,                 // output format : pcm
              NULL,                       // No filters
              0,                          // No async callback
              0,                          // No data for callback
              0                           // No flags
           );
           error = result != MMSYSERR_NOERROR;
           if (error)
              printf("Error opening conversion\n");
        }
    
        // Determine output decompressed buffer size
        unsigned long rawbufsize = 0;
        error = error || acmStreamSizePtr( acmMp3stream, MP3_BLOCK_SIZE, &rawbufsize, ACM_STREAMSIZEF_SOURCE );
       
        // allocate our I/O buffers
        BYTE mp3BlockBuffer[MP3_BLOCK_SIZE];
        //LPBYTE mp3BlockBuffer = (LPBYTE) LocalAlloc( LPTR, MP3_BLOCK_SIZE );
        LPBYTE rawbuf = error ? 0 : (LPBYTE) LocalAlloc( LPTR, rawbufsize );

        // prepare the decoder
        ACMSTREAMHEADER mp3streamHead;
        memset(&mp3streamHead, 0, sizeof(mp3streamHead) );
        mp3streamHead.cbStruct = sizeof(ACMSTREAMHEADER );
        mp3streamHead.pbSrc = mp3BlockBuffer;
        mp3streamHead.cbSrcLength = MP3_BLOCK_SIZE;
        mp3streamHead.pbDst = rawbuf;
        mp3streamHead.cbDstLength = rawbufsize;

        error = error || acmStreamPrepareHeaderPtr( acmMp3stream, &mp3streamHead, 0 );
       
        BYTE* currentOutput = (BYTE *)&decodedBuffer[0];
        int remaining = decodedBuffer.ByteCount();
       
        ULARGE_INTEGER newPosition;
        newPosition.QuadPart = 0LL;
        LARGE_INTEGER seekValue;
        seekValue.QuadPart = 0LL;
        error = error || mp3Stream->Seek(seekValue, STREAM_SEEK_SET, &newPosition);
       
        int totalRead = 0;
        unsigned int flags = ACM_STREAMCONVERTF_START | ACM_STREAMCONVERTF_BLOCKALIGN;
        while(!error)
        {
           // suck in some MP3 data
           ULONG count = 0;
           totalRead += MP3_BLOCK_SIZE;
           error = error || mp3Stream->Read(mp3BlockBuffer, MP3_BLOCK_SIZE, &count);

           if( count == 0 )
              break;

           // convert the data
           mp3streamHead.cbDstLengthUsed = 0;
           MMRESULT code =  acmStreamConvertPtr( acmMp3stream, &mp3streamHead, flags );
           if (code)
              break;
           flags = ACM_STREAMCONVERTF_BLOCKALIGN;

           int toWrite = remaining < mp3streamHead.cbDstLengthUsed ? remaining : mp3streamHead.cbDstLengthUsed;
           //count = fwrite( rawbuf, 1, mp3streamHead.cbDstLengthUsed, fpOut );
           memcpy(currentOutput, rawbuf, toWrite);
           currentOutput += toWrite;
           remaining -= toWrite;
           if (remaining==0)
              break;
        }
        if (remaining)
           decodedBuffer.resize( decodedBuffer.size() - remaining/sizeof(short) );
       
        if (acmMp3stream)
           acmStreamUnprepareHeaderPtr( acmMp3stream, &mp3streamHead, 0 );

        if (rawbuf)
           LocalFree(rawbuf);

        if (acmMp3stream)
           acmStreamClosePtr( acmMp3stream, 0 );
      }

      // Release allocated memory
      if (mp3Stream)
         mp3Stream->Release();

      if (mp3HGlobal)
         GlobalFree(mp3HGlobal);
   }

   ~AcmSoundData()
   {
   }

   virtual unsigned char *decodeWithHeader()
   {
      throw std::runtime_error("not implemented");
   }


   virtual INmeSoundData  *addRef() { refCount++; return this; }
   virtual void   release() { refCount--; if (refCount<=0) delete this; }

   virtual double getDuration() const { return duration; }
   virtual int    getChannelSampleCount() const { return sampleCount; }
   virtual bool   getIsStereo() const { return channels==2; }
   virtual int    getRate() const { return rate; }
   virtual bool   getIsDecoded() const { return decodedBuffer.size() > 0; }
   virtual short  *decodeAll() { return &decodedBuffer[0]; }
   virtual int    getDecodedByteCount() const { return decodedBuffer.ByteCount(); }
   virtual INmeSoundStream *createStream() { return 0; }

};
 
INmeSoundData *INmeSoundData::createAcm(const unsigned char *inData, int inDataLength, unsigned int inFlags)
{
   if (!initAcm())
      return 0;

   return new AcmSoundData(inData, inDataLength, inFlags);
}

} // end namespace nme



