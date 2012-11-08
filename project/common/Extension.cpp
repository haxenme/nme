#include <NME/extension.h>
#include <Utils.h>

#ifdef BLACKBERRY
#include <bps/event.h>
#endif

#include <Utils.h>


#ifdef BLACKBERRY

bool nme_register_bps_event_handler (void (*handler)(bps_event_t *event), int domain) {
	
	return RegisterBPSEventHandler (handler, domain);
	
}

#endif
