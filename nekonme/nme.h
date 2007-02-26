#ifndef __NME_H__
#define __NME_H__

#define RRGB( c )	(val_int( c ) >> 16 & 0xFF);
#define GRGB( c )	(val_int( c ) >> 8 & 0xFF);
#define BRGB( c )	(val_int( c ) & 0xFF);

typedef enum nme_eventtype {
	et_noevent = -1,
	et_active = 0,
	et_keydown,
	et_keyup,
	et_motion,
	et_button,
	et_jaxis,
	et_jball,
	et_jhat,
	et_jbutton,
	et_resize,
	et_quit,
	et_user,
	et_syswm
};

typedef enum nme_spriteanimtype {
	at_once = 0,
	at_loop,
	at_pingpong
};

#define MAX(a,b)	((a > b) ? a : b);
#define MIN(a,b)	((a < b) ? a : b);

#endif