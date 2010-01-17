#ifndef NME_UTILS_H
#define NME_UTILS_H

#include <string>

namespace nme
{

std::string WideToUTF8(const std::wstring &inWideString);

// You should delete[] the result
wchar_t *UTF8ToWideCStr(const char *inStr, int &outLen);

std::wstring UTF8ToWide(const char *inStr);

}


#endif
