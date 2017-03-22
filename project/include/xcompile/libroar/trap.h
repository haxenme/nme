//trap.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2011-2013
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

#ifndef _LIBROARTRAP_H_
#define _LIBROARTRAP_H_

#include "libroar.h"

#ifdef ROAR_SUPPORT_TRAP
#define roar_strap(group,name) roar_strap_impl((group),(name), __LINE__, __FILE__, ROAR_DBG_PREFIX)
#else
#define roar_strap(group,name)
#endif

#define ROAR_TRAP_GROUP_LIBROAR 1
#define ROAR_TRAP_GROUP_ROARD   2
#define ROAR_TRAP_GROUP_APP     3
#define ROAR_TRAP_GROUP_LIB     4
#define ROAR_TRAP_GROUP_NETWORK 5
#define ROAR_TRAP_GROUP_PROTO   6

#define ROAR_TRAP_GROUP_USER_MIN 1025

enum roar_trap_policy {
 ROAR_TRAP_IGNORE = 0,
 ROAR_TRAP_WARN,
 ROAR_TRAP_ABORT,
 ROAR_TRAP_KILL,
 ROAR_TRAP_STOP,
 ROAR_TRAP_DIE
};

unsigned int roar_trap_register_group(const char * name);
const char * roar_trap_get_groupname(const unsigned int group);
unsigned int roar_trap_get_groupid(const char * name);

void roar_strap_impl(const unsigned int group, const char * name, unsigned int line, const char * file, const char * prefix);

#endif

//ll
