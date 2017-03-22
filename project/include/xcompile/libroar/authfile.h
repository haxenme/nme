//authfile.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2010-2013
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

#ifndef _LIBROARAUTHFILE_H_
#define _LIBROARAUTHFILE_H_

#include "libroar.h"

#define ROAR_AUTHFILE_TYPE_AUTO       -1 /* auto detect type of key */
#define ROAR_AUTHFILE_TYPE_NONE        0 /* dummy */
#define ROAR_AUTHFILE_TYPE_ROAR        1 /* RoarAudio */
#define ROAR_AUTHFILE_TYPE_ESD         2 /* EsounD, plain cookie, len=16 byte */
#define ROAR_AUTHFILE_TYPE_PULSE       3 /* PulseAudio, plain cookie, len=256 byte */
#define ROAR_AUTHFILE_TYPE_HTPASSWD    4 /* Common .htpasswd format */
#define ROAR_AUTHFILE_TYPE_XAUTH       5 /* a xauth file */

#define ROAR_AUTHFILE_VERSION_AUTO    -1

struct roar_authfile;

struct roar_authfile * roar_authfile_open(int type, const char * filename, int rw, int version);
int roar_authfile_close(struct roar_authfile * authfile);

int roar_authfile_lock(struct roar_authfile * authfile);
int roar_authfile_unlock(struct roar_authfile * authfile);

int roar_authfile_sync(struct roar_authfile * authfile);

struct roar_authfile_key {
 size_t refc;
 int type;
 int index;
 const char * address;
 void * data;
 size_t len;
};

struct roar_authfile_key * roar_authfile_key_new(int type, size_t len, const char * addr);
#define roar_authfile_key_free(key) roar_authfile_key_unref(key)
int roar_authfile_key_ref(struct roar_authfile_key * key);
int roar_authfile_key_unref(struct roar_authfile_key * key);

int roar_authfile_add_key(struct roar_authfile * authfile, struct roar_authfile_key * key);

struct roar_authfile_key * roar_authfile_lookup_key(struct roar_authfile * authfile, int type, int minindex, const char * address);

struct roar_authfile_key * roar_authfile_key_new_random(int type, size_t len, const char * addr);

#endif

//ll
