//libroar.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2008-2013
 *
 *  This file is part of libroar a part of RoarAudio,
 *  a cross-platform sound system for both, home and professional use.
 *  See README for details.
 *
 *  This file is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 3
 *  as published by the Free Software Foundation.
 *
 *  libroar is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this software; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 *  NOTE for everyone want's to change something and send patches:
 *  read README and HACKING! There a addition information on
 *  the license of this document you need to read before you send
 *  any patches.
 *
 *  NOTE for uses of non-GPL (LGPL,...) software using libesd, libartsc
 *  or libpulse*:
 *  The libs libroaresd, libroararts and libroarpulse link this lib
 *  and are therefore GPL. Because of this it may be illigal to use
 *  them with any software that uses libesd, libartsc or libpulse*.
 */

#ifndef _LIBROAR_H_
#define _LIBROAR_H_

//#define ROAR_DBG_PREFIX  "libroar"

#include <roaraudio.h>

#include <stdarg.h>

#ifdef ROAR_HAVE_WAIT
#include <sys/wait.h>
#endif

#ifdef ROAR_HAVE_H_FCNTL
#include <fcntl.h>
#endif

#ifdef ROAR_HAVE_H_SIGNAL
#include <signal.h>
#endif

#ifdef ROAR_HAVE_SYSLOG
#include <syslog.h>
#endif

#ifdef ROAR_HAVE_BSDSOCKETS

#ifndef ROAR_TARGET_WIN32
#ifdef ROAR_HAVE_H_SYS_SOCKET
#include <sys/socket.h>
#endif
#ifdef ROAR_HAVE_IPV4
#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#endif
#include <sys/uio.h>

#ifdef ROAR_HAVE_UNIX
#include <sys/un.h>
#endif
#endif

#ifdef ROAR_HAVE_LIBDNET
#include <netdnet/dn.h>
#include <netdnet/dnetdb.h>
#endif

#ifdef ROAR_HAVE_IPX
#include <netipx/ipx.h>
#endif

#endif /* ROAR_HAVE_BSDSOCKETS */

#ifdef ROAR_HAVE_LIBSSL
#include <openssl/bio.h>
#include <openssl/evp.h>
#endif

#ifdef ROAR_HAVE_LIBSLP
#include <slp.h>
#ifdef ROAR_HAVE_H_SYS_TIME
#include <sys/time.h>
#endif
#endif

#ifdef ROAR_HAVE_H_TIME
#include <time.h>
#endif

#if defined(ROAR_HAVE_H_DLFCN)
#include <dlfcn.h>
#endif

#ifdef ROAR_HAVE_LIBX11
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#endif

#include "roarfeatures.h"
#include "error.h"
#include "trap.h"
#include "config.h"
#include "roarfloat.h"
#include "crc.h"
#include "base64.h"
#include "keyval.h"
#include "uuid.h"
#include "env.h"
#include "roardl.h"
#include "plugincontainer.h"
#include "services.h"
#include "debug.h"
#include "memmgr.h"
#include "stack.h"
#include "buffer.h"
#include "crypto.h"
#include "random.h"
#include "hash.h"
#include "hash_tiger.h"
#include "nnode.h"
#include "vio_ctl.h"
#include "vio.h"
#include "vio_buffer.h"
#include "vio_buffer_store.h"
#include "vio_cmd.h"
#include "vio_zlib.h"
#include "vio_ops.h"
#include "vio_string.h"
#include "vio_magic.h"
#include "vio_bio.h"
#include "vio_stdio.h"
#include "vio_stack.h"
#include "vio_jumbo.h"
#include "vio_pipe.h"
#include "vio_socket.h"
#include "vio_winsock.h"
#include "vio_proto.h"
#include "vio_proxy.h"
#include "vio_rtp.h"
#include "vio_select.h"
// dstr needs to have access to all other VIOs, so it must be included last
#include "vio_dstr.h"
#include "vio_tantalos.h"
#include "vio_stdvios.h"
#include "vio_misc.h"
#include "client.h"
#include "basic.h"
#include "serverinfo.h"
#include "stream.h"
#include "simple.h"
#include "cdrom.h"
#include "authfile.h"
#include "auth.h"
#include "socket.h"
#include "ctl.h"
#include "caps.h"
#include "roartime.h"
#include "meta.h"
#include "file.h"
#include "acl.h"
#include "pinentry.h"
#include "sshaskpass.h"
#include "passwordapi.h"
#include "roarslp.h"
#include "display.h"
#include "roarx11.h"
#include "beep.h"
#include "ltm.h"
#include "vs.h"
#include "enumdev.h"
#include "notify.h"
#include "notify_proxy.h"
#include "asyncctl.h"
#include "kstore.h"
#include "watchdog.h"
#include "scheduler.h"

// some basic macros:
#define ROAR_MAX2(a,b) ((a) > (b) ? (a) : (b))
#define ROAR_MIN2(a,b) ((a) < (b) ? (a) : (b))

#define ROAR_MAX3(a,b,c) ROAR_MAX2(ROAR_MAX2(a,b),c)
#define ROAR_MIN3(a,b,c) ROAR_MIN2(ROAR_MIN2(a,b),c)

#define ROAR_MAX4(a,b,c,d) ROAR_MAX2(ROAR_MAX2(a,b),ROAR_MAX2(c,d))
#define ROAR_MIN4(a,b,c,d) ROAR_MIN2(ROAR_MIN2(a,b),ROAR_MIN2(c,d))

#define ROAR_MAX ROAR_MAX2
#define ROAR_MIN ROAR_MIN2

int roar_usleep(uint_least32_t t);
int roar_sleep(int t);
pid_t roar_fork(const struct roar_libroar_forkapi * api);

// call this function after we fork/exec()ed or similar.
enum roar_reset {
 ROAR_RESET_UNKNOWN     = -1,
#define ROAR_RESET_UNKNOWN ROAR_RESET_UNKNOWN
 ROAR_RESET_NONE        =  0,
#define ROAR_RESET_NONE ROAR_RESET_NONE
 ROAR_RESET_ON_FORK     =  1,
#define ROAR_RESET_ON_FORK ROAR_RESET_ON_FORK
 ROAR_RESET_ON_EXIT     =  2,
#define ROAR_RESET_ON_EXIT ROAR_RESET_ON_EXIT
 ROAR_RESET_ON_PRE_EXEC =  3,
#define ROAR_RESET_ON_PRE_EXEC ROAR_RESET_ON_PRE_EXEC
 ROAR_RESET_MEMORY      =  0x81,
#define ROAR_RESET_MEMORY ROAR_RESET_MEMORY
 ROAR_RESET_CONFIG      =  0x82,
#define ROAR_RESET_CONFIG ROAR_RESET_CONFIG
 ROAR_RESET_RANDOMPOOL  =  0x84,
#define ROAR_RESET_RANDOMPOOL ROAR_RESET_RANDOMPOOL
 ROAR_RESET_EOL         = -2
#define ROAR_RESET_EOL ROAR_RESET_EOL
};
int roar_reset(enum roar_reset what);

// fatal probelms:
enum roar_fatal_error {
 ROAR_FATAL_ERROR_NONE = 0,          // ???
 ROAR_FATAL_ERROR_UNKNOWN,           // Unknown error
#define ROAR_FATAL_ERROR_UNKNOWN ROAR_FATAL_ERROR_UNKNOWN
 ROAR_FATAL_ERROR_MEMORY_CORRUPTION, // some structure has been corrupted
#define ROAR_FATAL_ERROR_MEMORY_CORRUPTION ROAR_FATAL_ERROR_MEMORY_CORRUPTION
 ROAR_FATAL_ERROR_MEMORY_CORRUPTION_GUARD, // memory was corruppted but no data has been harmed (yet)
#define ROAR_FATAL_ERROR_MEMORY_CORRUPTION_GUARD ROAR_FATAL_ERROR_MEMORY_CORRUPTION_GUARD
 ROAR_FATAL_ERROR_CPU_FAILURE,      // CPU general CPU failure
#define ROAR_FATAL_ERROR_CPU_FAILURE ROAR_FATAL_ERROR_CPU_FAILURE
 ROAR_FATAL_ERROR_CPU_FAILTURE = ROAR_FATAL_ERROR_CPU_FAILURE,
 ROAR_FATAL_ERROR_MEMORY_USED_AFTER_FREE,
#define ROAR_FATAL_ERROR_MEMORY_USED_AFTER_FREE ROAR_FATAL_ERROR_MEMORY_USED_AFTER_FREE
 ROAR_FATAL_ERROR_MEMORY_DOUBLE_FREE,
#define ROAR_FATAL_ERROR_MEMORY_DOUBLE_FREE ROAR_FATAL_ERROR_MEMORY_DOUBLE_FREE
 ROAR_FATAL_ERROR_WATCHDOG,
#define ROAR_FATAL_ERROR_WATCHDOG ROAR_FATAL_ERROR_WATCHDOG

 ROAR_FATAL_ERROR_EOL
};

#if __STDC_VERSION__ < 199901L
#if __GNUC__ >= 2
#define __roar_func__ __FUNCTION__
#else
#define __roar_func__ NULL
#endif
#else
#define __roar_func__ __func__
#endif

#define roar_panic(err,info) roar_panic_real((err), (info), __LINE__, __FILE__, ROAR_DBG_PREFIX, __roar_func__)
void roar_panic_real(enum roar_fatal_error error, const char * info,
                     unsigned long int line, const char * file, const char * prefix, const char * func);

// version stuff:
const char * roar_version_string(void);
uint32_t     roar_version_num(void);

#endif

//ll
