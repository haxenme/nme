//sndio.h:

#define _ROAR_EMUL_LIBSNDIO

#ifdef ROAR_HAVE_LIBSNDIO
#undef ROAR_HAVE_LIBSNDIO
#endif

#include <libroarsndio/libroarsndio.h>
#define ROAR_HAVE_LIBSNDIO

//ll
