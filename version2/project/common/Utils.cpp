#include <Utils.h>
#ifdef HX_WINDOWS
#include <windows.h>
#include <time.h>
#else
#include <sys/time.h>
typedef uint64_t __int64;
#endif


namespace nme
{

#ifndef HX_WINDOWS

std::string WideToUTF8(const std::wstring &inWideString)
{
  int len = 0;
  for(int i=0;i<inWideString.length();i++)
   {
      int c = inWideString[i];
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
      int c = inWideString[i];
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




std::wstring UTF8ToWide(const char *inStr)
{
   int len=0;
   wchar_t *s = UTF8ToWideCStr(inStr,len);
   std::wstring result(s,len);
   delete [] s;
   return result;
}

#else
#include <windows.h>

std::string WideToUTF8(const std::wstring &inWideString)
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

std::wstring UTF8ToWide(const char *inStr)
{
   int len =  MultiByteToWideChar( CP_UTF8, 0, inStr, -1, 0, 0 );
	if (len<1)
		return std::wstring();

	std::wstring result;
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
#else
   struct timeval tv;
   if( gettimeofday(&tv,NULL) )
      return 0;
   double t =  ( tv.tv_sec + ((double)tv.tv_usec) / 1000000.0 );
   if (t0==0) t0 = t;
   return t-t0;
#endif
}



}
