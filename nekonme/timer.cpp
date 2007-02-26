#include "nsdl.h"

value nme_gettime()
{
	return alloc_int( SDL_GetTicks() );
}

DEFINE_PRIM(nme_gettime, 0);