#ifndef UTILS_H
#define UTILS_H

#include <string>

std::string WideToUTF8(const std::wstring &inWideString);

// You should delete[] the result
wchar_t *UTF8ToWideCStr(const char *inStr, int &outLen);


#endif
