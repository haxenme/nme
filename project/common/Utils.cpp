#include <Utils.h>

#ifdef HX_WINDOWS
#include <windows.h>
#include <time.h>
#else
#include <sys/time.h>
#include <stdint.h>
typedef uint64_t __int64;
#endif

#ifdef HX_MACOS
#include <mach/mach_time.h>  
#endif

#ifdef ANDROID
#include <android/log.h>
#endif

#include "ByteArray.h"

namespace nme
{

std::string gAssetBase = "";


ByteArray *ByteArray::FromFile(const OSChar *inFilename)
{
   FILE *file = OpenRead(inFilename);
   if (!file)
   {
      #ifdef ANDROID
      return AndroidGetAssetBytes(inFilename);
      #endif
      return 0;
   }

   fseek(file,0,SEEK_END);
   int len = ftell(file);
   fseek(file,0,SEEK_SET);

   ByteArray *result = new ByteArray;
   result->mBytes.resize(len);
   fread(&result->mBytes[0],len,1,file);
   fclose(file);

   return result;
}


#ifdef HX_WINDOWS
ByteArray *ByteArray::FromFile(const char *inFilename)
{
   FILE *file = fopen(inFilename,"rb");
   if (!file)
      return 0;

   fseek(file,0,SEEK_END);
   int len = ftell(file);
   fseek(file,0,SEEK_SET);

   ByteArray *result = new ByteArray;
   result->mBytes.resize(len);
   fread(&result->mBytes[0],len,1,file);
   fclose(file);

   return result;
}
#endif





#ifndef HX_WINDOWS

std::string WideToUTF8(const WString &inWideString)
{
  int len = 0;
  const wchar_t *chars = inWideString.c_str();
  for(int i=0;i<inWideString.length();i++)
   {
      int c = chars[i];
      if( c <= 0x7F ) len++;
      else if( c <= 0x7FF ) len+=2;
      else if( c <= 0xFFFF ) len+=3;
      else len+= 4;
   }


   std::string result;
   result.resize(len);
   unsigned char *data =  (unsigned char *) &result[0];
   for(int i=0;i<inWideString.length();i++)
   {
      int c = chars[i];
      if( c <= 0x7F )
         *data++ = c;
      else if( c <= 0x7FF )
      {
         *data++ = 0xC0 | (c >> 6);
         *data++ = 0x80 | (c & 63);
      }
      else if( c <= 0xFFFF )
      {
         *data++ = 0xE0 | (c >> 12);
         *data++ = 0x80 | ((c >> 6) & 63);
         *data++ = 0x80 | (c & 63);
      }
      else
      {
         *data++ = 0xF0 | (c >> 18);
         *data++ = 0x80 | ((c >> 12) & 63);
         *data++ = 0x80 | ((c >> 6) & 63);
         *data++ = 0x80 | (c & 63);
      }
   }

   return result;
}


wchar_t *UTF8ToWideCStr(const char *inStr, int &outLen)
{
   int l = 0;

   unsigned char *b = (unsigned char *)inStr;
   for(int i=0;1;)
   {
      int c = b[i];
      if (c==0) break;
      l++;
      if (c==0) break;
      else if( c < 0x80 ) i++;
      else if( c < 0xE0 ) i+=2;
      else if( c < 0xF0 ) i+=3;
      else i=4;
   }
 


   wchar_t *result = new wchar_t[l+1];
   l = 0;

   for(int i=0;1;)
   {
      int c = b[i++];
      if (c==0) break;
      else if( c < 0x80 )
      {
        result[l++] = c;
      }
      else if( c < 0xE0 )
        result[l++] = ( ((c & 0x3F) << 6) | (b[i++] & 0x7F) );
      else if( c < 0xF0 )
      {
        int c2 = b[i++];
        result[l++] += ( ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | ( b[i++] & 0x7F) );
      }
      else
      {
        int c2 = b[i++];
        int c3 = b[i++];
        result[l++] += ( ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 << 6) & 0x7F) | (b[i++] & 0x7F) );
      }
   }
   result[l] = '\0';
   outLen = l;
   return result;
}

void UTF8ToWideVec(QuickVec<wchar_t,0> &outString,const char *inStr)
{
   int l = 0;

   unsigned char *b = (unsigned char *)inStr;
   for(int i=0;1;)
   {
      int c = b[i];
      if (c==0) break;
      l++;
      if (c==0) break;
      else if( c < 0x80 ) i++;
      else if( c < 0xE0 ) i+=2;
      else if( c < 0xF0 ) i+=3;
      else i=4;
   }

	outString.resize(l);
	wchar_t *result = outString.mPtr;
 
   l = 0;
   for(int i=0;1;)
   {
      int c = b[i++];
      if (c==0) break;
      else if( c < 0x80 )
      {
        result[l++] = c;
      }
      else if( c < 0xE0 )
        result[l++] = ( ((c & 0x3F) << 6) | (b[i++] & 0x7F) );
      else if( c < 0xF0 )
      {
        int c2 = b[i++];
        result[l++] += ( ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | ( b[i++] & 0x7F) );
      }
      else
      {
        int c2 = b[i++];
        int c3 = b[i++];
        result[l++] += ( ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 << 6) & 0x7F) | (b[i++] & 0x7F) );
      }
   }
}




WString UTF8ToWide(const char *inStr)
{
   int len=0;
   wchar_t *s = UTF8ToWideCStr(inStr,len);
   WString result(s,len);
   delete [] s;
   return result;
}

#else
#include <windows.h>

std::string WideToUTF8(const WString &inWideString)
{
  int len = WideCharToMultiByte( CP_UTF8, 0, inWideString.c_str(), inWideString.length(),
	  0, 0, 0, 0);

  if (len<1)
	  return std::string();

  std::string result;
  result.resize(len);
  WideCharToMultiByte( CP_UTF8, 0, inWideString.c_str(), inWideString.length(),
      &result[0], len, 0, 0 );


  return result;
}

wchar_t *UTF8ToWideCStr(const char *inStr, int &outLen)
{
   outLen =  MultiByteToWideChar( CP_UTF8, 0, inStr, -1, 0, 0 );
	if (outLen<1)
		return 0;

	// No null character ...
	outLen--;

	wchar_t *buf = new wchar_t[outLen];

   MultiByteToWideChar( CP_UTF8, 0, inStr, outLen, buf, outLen );

	return buf;
}

void UTF8ToWideVec(QuickVec<wchar_t,0> &outString,const char *inStr)
{
   int len =  MultiByteToWideChar( CP_UTF8, 0, inStr, -1, 0, 0 );
	if (len<1)
	{
		outString.clear();
		return;
	}

	// No null character ...
	len--;
	outString.resize(len);

   MultiByteToWideChar( CP_UTF8, 0, inStr, len, outString.mPtr, len );
}

WString UTF8ToWide(const char *inStr)
{
   int len =  MultiByteToWideChar( CP_UTF8, 0, inStr, -1, 0, 0 );
	if (len<1)
		return WString();

	WString result;
	result.resize(len-1);

   MultiByteToWideChar( CP_UTF8, 0, inStr, len-1, &result[0], len-1 );

	return result;
}
#endif



static double t0 = 0;
double  GetTimeStamp()
{
#ifdef _WIN32
   static __int64 t0=0;
   static double period=0;
   __int64 now;

   if (QueryPerformanceCounter((LARGE_INTEGER*)&now))
   {
      if (t0==0)
      {
         t0 = now;
         __int64 freq;
         QueryPerformanceFrequency((LARGE_INTEGER*)&freq);
         if (freq!=0)
            period = 1.0/freq;
      }
      if (period!=0)
         return (now-t0)*period;
   }

   return (double)clock() / ( (double)CLOCKS_PER_SEC);
#elif defined(HX_MACOS)
   static double time_scale = 0.0;
   if (time_scale==0.0)
   {
      mach_timebase_info_data_t info;
      mach_timebase_info(&info);  
      time_scale = 1e-9 * (double)info.numer / info.denom;
   }
   double r =  mach_absolute_time() * time_scale;  
   return mach_absolute_time() * time_scale;  
#elif defined(GPH) || defined(IPHONE)
	  struct timeval tv;
     if( gettimeofday(&tv,NULL) )
       return 0;
     double t =  ( tv.tv_sec + ((double)tv.tv_usec) / 1000000.0 );
     if (t0==0) t0 = t;
     return t-t0;
#else
	 struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    double t =  ( ts.tv_sec + ((double)ts.tv_nsec)*1e-9  );
    if (t0==0) t0 = t;
    return t-t0;
#endif
}


#ifdef ANDROID

WString::WString(const WString &inRHS)
{
   mLength = inRHS.mLength;
   if (mLength==0)
      mString = 0;
   else
   {
      mString = new wchar_t[mLength+1];
      memcpy(mString,inRHS.mString,mLength*sizeof(wchar_t));
      mString[mLength] = '\0';
   }
}

WString::WString(const wchar_t *inStr)
{
   mLength = 0;
   if (inStr==0 || *inStr=='\0')
   {
      mString = 0;
   }
   else
   {
      while(inStr[mLength]) mLength++;
      mString = new wchar_t[mLength+1];
      memcpy(mString,inStr,mLength*sizeof(wchar_t));
      mString[mLength] = '\0';
   }

}

WString::WString(const wchar_t *inStr,int inLen)
{
   if (inLen==0)
   {
      mString = 0;
   }
   else
   {
      mString = new wchar_t[inLen+1];
      if (mString && inStr)
         memcpy(mString,inStr,inLen*sizeof(wchar_t));
      mString[inLen] = '\0';
   }

   mLength = inLen;
}

WString::~WString()
{
   delete [] mString;
}


WString &WString::operator=(const WString &inRHS)
{
   if (inRHS.mString != mString)
   {
      delete [] mString;
      mLength = inRHS.mLength;
      if (mLength==0)
         mString = 0;
      else
      {
         mString = new wchar_t[mLength+1];
         memcpy(mString,inRHS.mString,mLength*sizeof(wchar_t));
         mString[mLength] = '\0';
      }
   }
}

WString &WString::operator +=(const WString &inRHS)
{
   *this = *this + inRHS;
   return *this;
}

WString WString::operator +(const WString &inRHS) const
{
   int len = mLength + inRHS.mLength;
   if (len==0)
      return WString();

   WString result(0,len);
   memcpy(result.mString, mString, mLength*sizeof(wchar_t));
   memcpy(result.mString + mLength, inRHS.mString, inRHS.mLength*sizeof(wchar_t));
   return result;
}

bool WString::operator<(const WString &inRHS) const
{
   int len = mLength<inRHS.mLength ? mLength : inRHS.mLength;
   for(int i=0;i<len;i++)
      if (mString[i] < inRHS.mString[i])
         return true;
      else if (mString[i]>inRHS.mString[i])
         return false;

   return mLength<inRHS.mLength;
}

bool WString::operator>(const WString &inRHS) const
{
   int len = mLength<inRHS.mLength ? mLength : inRHS.mLength;
   for(int i=0;i<len;i++)
      if (mString[i] > inRHS.mString[i])
         return true;
      else if (mString[i]<inRHS.mString[i])
         return false;

   return mLength>inRHS.mLength;
}


bool WString::operator==(const WString &inRHS) const
{
   if (mLength!=inRHS.mLength)
      return false;

   for(int i=0;i<mLength;i++)
      if (mString[i]!=inRHS.mString[i])
         return false;

   return true;
}


bool WString::operator!=(const WString &inRHS) const
{
   if (mLength!=inRHS.mLength)
      return true;

   for(int i=0;i<mLength;i++)
      if (mString[i]!=inRHS.mString[i])
         return true;

   return false;
}




#endif



}
