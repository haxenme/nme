#ifndef IPHONE
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif

#include <hx/CFFI.h>
#include "Utils.h"
#include <stdio.h>

using namespace ::name::;


static value ::name::_sample_method (value inputValue) {
	
	int returnValue = SampleMethod(val_int(inputValue));
	return alloc_int(returnValue);
	
}
DEFINE_PRIM (::name::_sample_method, 1);


extern "C" void ::name::_main () {
	
	// This is an optional method used for initialization
	
}
DEFINE_ENTRY_POINT (::name::_main);


extern "C" int ::name::_register_prims () { return 0; }