#include <windows.h>
#include <stdio.h>
#include <string>

namespace nme
{

bool LaunchBrowser(const char *inUtf8URL)
{
   return false;
}

std::string CapabilitiesGetLanguage()
{
   return "";
}

//bool dpiAware = SetProcessDPIAware();

double CapabilitiesGetScreenDPI()
{
   return 96;
}

double CapabilitiesGetPixelAspectRatio()
{
   return 1.0;
}


}
