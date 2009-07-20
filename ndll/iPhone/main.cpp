#include <hxObject.h>


extern "C" void __hxcpp_lib_main();
extern "C" int nme_register_prims();

extern "C" int std_register_prims();
extern "C" int regexp_register_prims();
extern "C" int zlib_register_prims();

extern "C" int SDL_main(int argc, char *argv[])
{ 
	printf("And away we go...\n");
	std_register_prims();
	regexp_register_prims();
	zlib_register_prims();
	nme_register_prims();
	
	try { 
		__hxcpp_lib_main();
	}
	catch ( Dynamic d ) {
		printf(" Error %S\n", d->toString().__s );
	}
		
    return 0;
}
