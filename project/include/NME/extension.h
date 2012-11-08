#ifndef NME_EXTENSION_H
#define NME_EXTENSION_H

#ifdef BLACKBERRY
#include <bps/event.h>
#endif


#ifdef BLACKBERRY
bool nme_register_bps_event_handler(void (*handler)(bps_event_t *event), int domain);
#endif



#endif