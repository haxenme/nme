//roaraudio.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2008-2013
 *
 *  This file is part of RoarAudio,
 *  a cross-platform sound system for both, home and professional use.
 *  See README for details.
 *
 *  This file is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License version 3
 *  as published by the Free Software Foundation.
 *
 *  RoarAudio is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this software; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 *  NOTE: Even though this file is LGPLed it (may) include GPLed files
 *  so the license of this file is/may therefore downgraded to GPL.
 *  See HACKING for details.
 */

#ifndef _ROARAUDIO_H_
#define _ROARAUDIO_H_

#define  _ROAR_MKVERSION(a,b,c) (((uint32_t)(a) << 16) + ((uint32_t)(b) << 8) + (uint32_t)(c))

#include <roaraudio/config.h>
#include <roaraudio/compilerhacks.h>
#include <roaraudio/targethacks.h>
#include <roaraudio/muconthacks.h>
#include <roaraudio/win32hacks.h> // we include this at the beginning of the file
                                  // so we can define well known standard types known to everyone
                                  // and everywhere but win32 here

#define ROAR_VERSION _ROAR_MKVERSION(ROAR_VERSION_MAJOR, ROAR_VERSION_MINOR, ROAR_VERSION_REV)

#if defined(DEBUG) && !defined(ROAR_SUPPORT_TRAP)
#define ROAR_SUPPORT_TRAP
#endif

// consts we need to set depending on the OS and features:
#if defined(ROAR_NEED_GNU_SOURCE) && !defined(_GNU_SOURCE)
#define _GNU_SOURCE
#endif

#if defined(ROAR_NEED_BSD_VISIBLE) && !defined(__BSD_VISIBLE)
#define __BSD_VISIBLE 1
#endif

#ifdef ROAR_HAVE_H_STDINT
#include <stdint.h>
#endif

#include <stdlib.h>

#ifdef ROAR_HAVE_H_UNISTD
#include <unistd.h>
#endif

#include <stdio.h>
#include <string.h>
#include <errno.h>

#ifdef ROAR_HAVE_H_SYS_TYPES
#include <sys/types.h>
#endif

#include <limits.h>
#if !defined(ROAR_TARGET_WIN32) && !defined(ROAR_TARGET_MICROCONTROLLER)
#include <sys/mman.h>
#endif

// TODO: can we move the next block into roard specific includes?
#if !defined(ROAR_TARGET_WIN32) && !defined(ROAR_TARGET_MICROCONTROLLER)
#include <grp.h>
#include <pwd.h>
#endif

#ifdef ROAR_HAVE_H_SYS_STAT
#include <sys/stat.h>
#endif

#ifdef ROAR_TARGET_WIN32
#include <winsock2.h>
#else /* ROAR_TARGET_WIN32 */
#ifdef ROAR_HAVE_BSDSOCKETS

#ifdef ROAR_HAVE_H_SYS_SOCKET
#include <sys/socket.h>
#endif

#ifdef ROAR_HAVE_IPV4
#include <netinet/in.h>
#include <netinet/tcp.h>
#endif
#ifdef ROAR_HAVE_UNIX
#include <sys/un.h>
#endif

#if defined(ROAR_HAVE_IPV4) || defined(ROAR_HAVE_IPV6)
#include <arpa/inet.h>
#endif

#endif /* ROAR_HAVE_BSDSOCKETS */
#endif /* ROAR_TARGET_WIN32 */

#ifdef __NetBSD__
#include <netinet/in_systm.h>
#endif

#if !defined(ROAR_TARGET_WIN32) && !defined(ROAR_TARGET_MICROCONTROLLER)
#include <netdb.h>
#endif

// NOTE: we need this macro in some of our header files.
// TODO: This is oubslute, we will remove it soon.
#if INT_MAX >= 32767
#define roar_intm16  int
#define roar_uintm16 unsigned int
#else
#define roar_intm16  int16_t
#define roar_uintm16 uint16_t
#endif

// this is to avoid warning messages on platforms
// where sizeof(void*) == 8 and szeof(int) == 4
#ifdef __LP64__
#define ROAR_INSTINT long int
#else
#define ROAR_INSTINT int
#endif

#ifndef __BEGIN_DECLS
#ifdef __cplusplus
# define __BEGIN_DECLS extern "C" {
# define __END_DECLS }
#else
# define __BEGIN_DECLS
# define __END_DECLS
#endif
#endif

__BEGIN_DECLS

#include <roaraudio/license.h>
#include <roaraudio/vendors.h>
#include <roaraudio/proto.h>
#include <roaraudio/caps.h>
#include <roaraudio/error.h>
#include <roaraudio/audio.h>
#include <roaraudio/stream.h>
#include <roaraudio/client.h>
#include <roaraudio/sample.h>
#include <roaraudio/beep.h>
#include <roaraudio/meta.h>
#include <roaraudio/genre.h>
#include <roaraudio/acl.h>
#include <roaraudio/misc.h>
#include <roaraudio/byteorder.h>
#include <roaraudio/socket.h>
#include <roaraudio/ltm.h>
#include <roaraudio/notify.h>

#include <libroar/libroar.h>

// Some settings for roard:
#ifndef ROAR_ROARD_BITS
#define ROAR_ROARD_BITS 32
#endif

// Some glocal network defaults:
#ifndef ROAR_NET_INET4_LOCALHOST
#define ROAR_NET_INET4_LOCALHOST "localhost"
#endif
#ifndef ROAR_NET_INET4_ANYHOST
#define ROAR_NET_INET4_ANYHOST   "0.0.0.0"
#endif

#ifndef ROAR_NET_INET6_LOCALHOST
#define ROAR_NET_INET6_LOCALHOST "ipv6-localhost"
#endif
#ifndef ROAR_NET_INET6_ANYHOST
#define ROAR_NET_INET6_ANYHOST   "::"
#endif

// IP:
#define ROAR_DEFAULT_PORT        16002

// IPv4
#define ROAR_DEFAULT_INET4_PORT  ROAR_DEFAULT_PORT
#define ROAR_DEFAULT_INET4_HOST  ROAR_NET_INET4_LOCALHOST
// aliases:
#define ROAR_DEFAULT_HOST        ROAR_DEFAULT_INET4_HOST
#define ROAR_DEFAULT_HOSTPORT    ROAR_DEFAULT_HOST ":16002"

// IPv6:
#define ROAR_DEFAULT_INET6_PORT  ROAR_DEFAULT_PORT
#define ROAR_DEFAULT_INET6_HOST  ROAR_NET_INET6_LOCALHOST

// UNIX Domain Sockets
#define ROAR_DEFAULT_SOCK_GLOBAL "/tmp/roar"
#define ROAR_DEFAULT_SOCK_USER   ".roar"

// DECnet
#define ROAR_DEFAULT_OBJECT      "roar"
#define ROAR_DEFAULT_NUM         0
#define ROAR_DEFAULT_LISTEN_OBJECT "::" ROAR_DEFAULT_OBJECT

// now handled by configure:
//#define ROAR_DEFAULT_SOCKGRP     "audio"


// defines for emulations:
// ESD:
#define ROAR_DEFAULT_ESD_GSOCK   "/tmp/.esd/socket"
#define ROAR_DEFAULT_ESD_PORT    16001
// RSound:
#define ROAR_DEFAULT_RSOUND_GSOCK  "/tmp/rsound"
#define ROAR_DEFAULT_RSOUND_PORT   12345
#define ROAR_DEFAULT_RSOUND_OBJECT "::rsound"
// PulseAudio:
#define ROAR_DEFAULT_PA_PORT     4712
// RPlay:
#define ROAR_DEFAULT_RPLAY_PORT  5556
// Gopher:
#define ROAR_DEFAULT_GOPHER_PORT 70
// WWW/HTTP:
#define ROAR_DEFAULT_HTTP_PORT   80

#if defined(ROAR_HAVE_LIBWSOCK32) && defined(ROAR_HAVE_LIBWS2_32)
#define ROAR_LIBS_WIN32          " -lwsock32 -lws2_32"
#else
#define ROAR_LIBS_WIN32          ""
#endif

#ifdef ROAR_HAVE_LIBSOCKET
#define ROAR_LIBS_LIBSOCKET      " -lsocket"
#else
#define ROAR_LIBS_LIBSOCKET      ""
#endif

#ifdef ROAR_HAVE_LIBSENDFILE
#define ROAR_LIBS_LIBSENDFILE    " -lsendfile"
#else
#define ROAR_LIBS_LIBSENDFILE    ""
#endif

#define ROAR_LIBS_NET_LIBS       ROAR_LIBS_LIBSOCKET ROAR_LIBS_WIN32

#define ROAR_LIBS                "-lroar"       ROAR_LIBS_LIBSENDFILE ROAR_LIBS_NET_LIBS
#define ROAR_LIBS_DSP            "-lroardsp "   ROAR_LIBS
#define ROAR_LIBS_MIDI           "-lroarmidi "  ROAR_LIBS_DSP
#define ROAR_LIBS_LIGHT          "-lroarlight " ROAR_LIBS
#define ROAR_LIBS_EIO            "-lroareio "   ROAR_LIBS
#define ROAR_CFLAGS              ""

// comp libs:
#define ROAR_LIBS_C_ESD          "-lroaresd "   ROAR_LIBS
#define ROAR_LIBS_C_ARTSC        "-lroarartsc " ROAR_LIBS
#define ROAR_LIBS_C_PULSE        "-lroarpulse " ROAR_LIBS
#define ROAR_LIBS_C_PULSE_SIMPLE "-lroarpulse-simple " ROAR_LIBS_C_PULSE
#define ROAR_LIBS_C_SNDIO        "-lroarsndio " ROAR_LIBS
#define ROAR_LIBS_C_YIFF         "-lroaryiff "  ROAR_LIBS

//some basic macros:
#define ROAR_STDIN  0
#define ROAR_STDOUT 1
#define ROAR_STDERR 2

#define ROAR_DEBUG_OUTFH stderr

#ifndef ROAR_DBG_PREFIX
#define ROAR_DBG_PREFIX "roaraudio"
#endif

#define ROAR_DBG_FULLPREFIX "(" ROAR_DBG_PREFIX ": " __FILE__ ":%i): "

// some default info levels:
#define ROAR_DBG_INFO_NONE             0
#define ROAR_DBG_INFO_NOTICE           1
#define ROAR_DBG_INFO_INFO             2
#define ROAR_DBG_INFO_VERBOSE          3

#if !defined(__GNUC__)
 #define ROAR_DBG(format, ...)
 #define ROAR_ERR(format, ...)
 #define ROAR_WARN(format, ...)
 #define ROAR_INFO(format, level, ...)
#elif __GNUC__ < 3
 #define ROAR_DBG(format, args...)
 #define ROAR_ERR(format, args...)
 #define ROAR_WARN(format, args...)
 #define ROAR_INFO(format, level, args...)
#else

#ifdef DEBUG
 #define ROAR_DBG(format, args...)  roar_debug_msg(ROAR_DEBUG_TYPE_DEBUG, __LINE__, __FILE__, ROAR_DBG_PREFIX, format, ## args)
#else
 #define ROAR_DBG(format, args...)
#endif

#define ROAR_ERR(format, args...)  roar_debug_msg(ROAR_DEBUG_TYPE_ERROR, __LINE__, __FILE__, ROAR_DBG_PREFIX, format, ## args)
#define ROAR_WARN(format, args...) roar_debug_msg(ROAR_DEBUG_TYPE_WARNING, __LINE__, __FILE__, ROAR_DBG_PREFIX, format, ## args)

// INFO function:
#ifdef DEBUG
 #define ROAR_INFO(format, level, args...) roar_debug_msg(ROAR_DEBUG_TYPE_INFO, __LINE__, __FILE__, ROAR_DBG_PREFIX, format, ## args)
#elif defined(ROAR_DBG_INFOVAR)
 #define ROAR_INFO(format, level, args...) if ( (ROAR_DBG_INFOVAR) >= (level) ) roar_debug_msg(ROAR_DEBUG_TYPE_INFO, __LINE__, __FILE__, ROAR_DBG_PREFIX, format, ## args)
#else
 #define ROAR_INFO(format, level, args...)
#endif

#endif

#ifdef ROAR_HAVE_SAFE_OVERFLOW
#define ROAR_MATH_OVERFLOW_ADD(a, b) ((a)+(b))
#else
#define ROAR_MATH_OVERFLOW_ADD(a, b) ((4294967295U - (a)) + 1 + (b))
#endif

#ifdef ROAR_HAVE_STRCASESTR
#define _roar_strcasestr(a,b) strcasestr((a), (b))
#else
#define _roar_strcasestr(a,b) NULL
#endif

__END_DECLS

#endif

//ll
