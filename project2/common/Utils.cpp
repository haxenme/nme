#include <Utils.h>
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



