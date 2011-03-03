#ifndef NME_UTILS_H
#define NME_UTILS_H

#include <string>
#include <QuickVec.h>

namespace nme
{

extern std::string gAssetBase;

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


private:
   wchar_t *mString;
   int     mLength;
};
#else
typedef std::wstring WString;
#endif



#ifdef HX_WINDOWS
typedef wchar_t OSChar;
#define val_os_string val_wstring
#define OpenRead(x) _wfopen(x,L"rb")
#else
typedef char OSChar;
#define val_os_string val_string

#ifdef IPHONE
FILE *OpenRead(const char *inName);
#else
#define OpenRead(x) fopen(x,"rb")
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
