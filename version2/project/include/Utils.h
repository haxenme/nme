#ifndef NME_UTILS_H
#define NME_UTILS_H

#include <string>

namespace nme
{

#ifdef HX_WINDOWS
typedef wchar_t OSChar;
#define val_os_string val_wstring
#define OpenRead(x) _wfopen(x,L"rb")
#else
typedef char OSChar;
#define val_os_string val_string
#define OpenRead(x) fopen(x,"rb")
#endif

std::string WideToUTF8(const std::wstring &inWideString);

// You should delete[] the result
wchar_t *UTF8ToWideCStr(const char *inStr, int &outLen);

std::wstring UTF8ToWide(const char *inStr);

}


#endif
