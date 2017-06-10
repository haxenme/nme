#include "SDL_main.h"
#include <wrl.h>

#ifndef SDL_WINRT_METADATA_FILE_AVAILABLE
#ifndef __cplusplus_winrt
#error SDL_winrt_main_NonXAML.cpp must be compiled with /ZW, otherwise build errors due to missing .winmd files can occur.
#endif
#endif

#ifdef _MSC_VER
#pragma warning(disable:4447)
#endif

#ifdef _MSC_VER
#pragma comment(lib, "runtimeobject.lib")
#endif

#define DEBUG_PRINTF
#ifdef DEBUG_PRINTF
# ifdef UNICODE
#  define DLOG(fmt, ...) {wchar_t buf[1024];swprintf(buf,L"****LOG: %s(%d): %s \n    [" fmt "]\n",__FILE__,__LINE__,__FUNCTION__, __VA_ARGS__);OutputDebugString(buf);}
# else
#  define DLOG(fmt, ...) {char buf[1024];sprintf(buf,"****LOG: %s(%d): %s \n    [" fmt "]\n",__FILE__,__LINE__,__FUNCTION__, __VA_ARGS__);OutputDebugString(buf);}
# endif
#else
# define DLOG(fmt, ...) {}
#endif

extern "C" const char *hxRunLibrary ();
extern "C" void hxcpp_set_top_of_stack ();
extern "C" int nme_register_prims();

::foreach ndlls::::if (registerStatics)::
extern "C" int ::nameSafe::_register_prims ();::end::::end::

int mymain(int argc, char *argv[])
{

  hxcpp_set_top_of_stack ();

  nme_register_prims();
  ::foreach ndlls::::if (registerStatics)::
  ::nameSafe::_register_prims ();::end::::end::

    const char *err = hxRunLibrary ();
    if (err)
    {
      DLOG("******Error hxRunLibrary: %s",err);
      return -1;
    }
  return 0;
}

int CALLBACK WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{ 

  if (FAILED(Windows::ENV_DCS::Foundation::ENV_DCS::Initialize(RO_INIT_MULTITHREADED))) 
  {
      return 1;
  } 

  SDL_WinRTRunApp(mymain, NULL);
  return 0;
}
