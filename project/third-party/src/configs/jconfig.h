#ifdef IPHONE
#include "jconfig.iphoneos"
#elif defined(ANDROID)
#include "jconfig.mac"
#elif defined(__APPLE__)
#include "jconfig.mac"
#elif defined(_WIN32)
#include "jconfig.vc"
#else
#include "jconfig.linux"
#endif


