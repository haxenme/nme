#ifndef NME_UTILS_H
#define NME_UTILS_H

#include <string>
#include <QuickVec.h>


#ifdef ANDROID
#include <android/log.h>

#ifdef VERBOSE
#define VLOG(args...) __android_log_print(ANDROID_LOG_INFO, "NME",args)
#else
#define VLOG(args...)
#endif

#define ELOG(args...) __android_log_print(ANDROID_LOG_ERROR, "NME",args)

#else

#include <stdio.h>

#ifdef _MSC_VER
#include <stdio.h>
#include <stdarg.h>

inline void DoLog(const char *inFormat,...)
{
  va_list args;
  va_start(args, inFormat);
  vprintf (inFormat, args);
  printf("\n");
  va_end (args);
}
inline void DontLog(const char *inFormat,...) { }

#ifdef VERBOSE

#define VLOG DoLog
#else
#define VLOG DontLog
#endif
#define ELOG DoLog

#else

#ifndef VERBOSE
#define VLOG(args...) { printf(args); printf("\n"); }
#else
#define VLOG(args...)
#endif

#define ELOG(args...) { printf(args); printf("\n"); }

#endif

#endif


namespace nme
{

extern std::string gAssetBase;

const std::string &GetResourcePath();
const std::string &GetDocumentsPath();


#ifdef ANDROID
class WString
{
public:
   WString() : mLength(0), mString(0) { }
   WString(const WString &inRHS);
   WString(const wchar_t *inStr);
   WString(const wchar_t *inStr,int inLen);
   ~WString();

   inline int length() const { return mLength; }
   inline int size() const { return mLength; }

   WString &operator=(const WString &inRHS);
   inline wchar_t &operator[](int inIndex) { return mString[inIndex]; }
   inline const wchar_t &operator[](int inIndex) const { return mString[inIndex]; }
   const wchar_t *c_str() const { return mString ? mString : L""; }

   WString &operator +=(const WString &inRHS);
   WString operator +(const WString &inRHS) const;
   bool operator<(const WString &inRHS) const;
   bool operator>(const WString &inRHS) const;
   bool operator==(const WString &inRHS) const;
   bool operator!=(const WString &inRHS) const;

   WString substr(int inPos,int inLen) const;


private:
   wchar_t *mString;
   int     mLength;
};
#else
typedef std::wstring WString;
#endif

bool LaunchBrowser(const char *inUtf8URL);

#ifdef HX_WINDOWS
typedef wchar_t OSChar;
#define val_os_string val_wstring
#define OpenRead(x) _wfopen(x,L"rb")
#define OpenOverwrite(x) _wfopen(x,L"wb") // [ddc]

#else
typedef char OSChar;
#define val_os_string val_string

#if defined(IPHONE)
FILE *OpenRead(const char *inName);
FILE *OpenOverwrite(const char *inName); // [ddc]
#elif defined(HX_MACOS)
} // close namespace nme
extern "C" FILE *OpenRead(const char *inName);
extern "C" bool GetBundleFilename(const char *inName, char *outBuffer,int inBufSize);
extern "C" FILE *OpenOverwrite(const char *inName);
namespace nme {
#else
#define OpenRead(x) fopen(x,"rb")
#define OpenOverwrite(x) fopen(x,"wb") // [ddc]
#endif

#endif

std::string WideToUTF8(const WString &inWideString);

// You should delete[] the result
wchar_t *UTF8ToWideCStr(const char *inStr, int &outLen);

void UTF8ToWideVec(QuickVec<wchar_t,0> &outString,const char *inStr);

WString UTF8ToWide(const char *inStr);

double GetTimeStamp();
	

}


#endif
