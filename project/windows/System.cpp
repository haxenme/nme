#include <windows.h>
#include <stdio.h>
#include <string>

namespace nme {
	
	bool LaunchBrowser(const char *inUtf8URL)
	{
		int result;
		result=(int)ShellExecute(NULL, "open", inUtf8URL, NULL, NULL, SW_SHOWDEFAULT);
		return (result>32);
	}

	std::string CapabilitiesGetLanguage()
	{
		char locale[8];
		int lang_len = GetLocaleInfo(GetSystemDefaultUILanguage(), LOCALE_SISO639LANGNAME, locale, sizeof(locale));
		return std::string(locale, lang_len);
	}
	
}
