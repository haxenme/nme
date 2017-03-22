//debug.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2009-2013
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

#ifndef _LIBROARDEBUG_H_
#define _LIBROARDEBUG_H_

#include "libroar.h"

#define ROAR_WARNING_NEVER       0
#define ROAR_WARNING_ONCE        1
#define ROAR_WARNING_ALWAYS      2

#define ROAR_DEBUG_TYPE_ERROR    1
#define ROAR_DEBUG_TYPE_WARNING  2
#define ROAR_DEBUG_TYPE_INFO     3
#define ROAR_DEBUG_TYPE_DEBUG    4

#define ROAR_DEBUG_MODE_SYSIO    0
#define ROAR_DEBUG_MODE_VIO      1
#define ROAR_DEBUG_MODE_SYSLOG   2

#if 1
#define roar_debug_warn_sysio(f,n,i)     roar_debug_warn_sysio_real((f),(n),(i))
#define roar_debug_warn_obsolete(f,n,i)  roar_debug_warn_obsolete_real((f),(n),(i))
#else
#define roar_debug_warn_sysio(f,n,i)
#define roar_debug_warn_obsolete(f,n,i)
#endif

void roar_debug_warn_sysio_real   (char * func, char * newfunc, char * info);
void roar_debug_warn_obsolete_real(char * func, char * newfunc, char * info);

void roar_debug_bin_obsolete(const char * progname, const char * newprog, const char * info);

// Error handle:
struct roar_vio_calls; // will be declared later in vio.h

void   roar_debug_set_stderr_fh(int fh);
void   roar_debug_set_stderr_vio(struct roar_vio_calls * vio);
void   roar_debug_set_stderr_mode(int mode);

struct roar_vio_calls * roar_debug_get_stderr(void);

void roar_debug_msg_simple(const char *format, ...) _LIBROAR_ATTR_PRINTF(1, 2);

void roar_debug_msg(int type, unsigned long int line, const char * file, const char * prefix, const char * format, ...) _LIBROAR_ATTR_PRINTF(5, 6);

#endif

//ll
