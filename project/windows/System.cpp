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
	
	bool SetDPIAware()
	{
		HMODULE usr32 = LoadLibrary("user32.dll");
		if(!usr32) return false;
		
		BOOL (*addr)() = (BOOL (*)())GetProcAddress(usr32, "SetProcessDPIAware");
		return addr ? addr() : false;
	}

	bool dpiAware = SetDPIAware();

	double CapabilitiesGetScreenDPI()
	{
		HDC screen = GetDC(NULL);
		/* It reports 72... :(
		double hSize = GetDeviceCaps(screen, HORZSIZE);
		double vSize = GetDeviceCaps(screen, VERTSIZE);
		double hRes = GetDeviceCaps(screen, HORZRES);
		double vRes = GetDeviceCaps(screen, VERTRES);
		double hPixelsPerInch = hRes / hSize * 25.4;
		double vPixelsPerInch = vRes / vSize * 25.4;
		*/
		double hPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSX);
		double vPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSY);
		ReleaseDC(NULL, screen);
		return (hPixelsPerInch + vPixelsPerInch) * 0.5;
	}

	double CapabilitiesGetPixelAspectRatio() {
		HDC screen = GetDC(NULL);
		double hPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSX);
		double vPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSY);
		ReleaseDC(NULL, screen);
		return hPixelsPerInch / vPixelsPerInch;
	}

}
