//uuid.h:

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

#ifndef _LIBROARUUID_H_
#define _LIBROARUUID_H_

#include "libroar.h"

typedef unsigned char roar_uuid_t[16];

enum roar_uuid_type {
 ROAR_UUID_TYPE_NULL         = 0,
 ROAR_UUID_TYPE_TIME         = 1,
 ROAR_UUID_TYPE_DCE_SECURITY = 2,
 ROAR_UUID_TYPE_MD5          = 3,
 ROAR_UUID_TYPE_RANDOM       = 4,
 ROAR_UUID_TYPE_SHA1         = 5
};

// compare two UUIDs: return 1 if they are the same, 0 if they are not and -1 in case of error.
int roar_uuid_eq(const roar_uuid_t a, const roar_uuid_t b);

int roar_uuid2str(char * str, const roar_uuid_t uuid, ssize_t len);
int roar_str2uuid(roar_uuid_t uuid, const char * str);

// returns UUIDs for common namespaces.
const roar_uuid_t * roar_uuid_get_ns_real(const char * ns);
#define roar_uuid_get_ns(ns) (*roar_uuid_get_ns_real((ns)))

int roar_uuid_gen(roar_uuid_t uuid, enum roar_uuid_type type, const roar_uuid_t ns, const void * argp, ssize_t arglen);
#define roar_uuid_gen_null(uuid) roar_uuid_gen((uuid), ROAR_UUID_TYPE_NULL, NULL, NULL, -1)
#define roar_uuid_gen_time(uuid) roar_uuid_gen((uuid), ROAR_UUID_TYPE_TIME, NULL, NULL, -1)
#define roar_uuid_gen_random(uuid) roar_uuid_gen((uuid), ROAR_UUID_TYPE_RANDOM, NULL, NULL, -1)
#define roar_uuid_gen_fromstr(uuid,str,ns) roar_uuid_gen((uuid), ROAR_UUID_TYPE_SHA1, roar_uuid_get_ns((ns)), (str), roar_mm_strlen((str)))
#define roar_uuid_clear(uuid) roar_uuid_gen_null((uuid))

#endif

//ll
