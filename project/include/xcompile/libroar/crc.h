//crc.h:

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

#ifndef _LIBROARCRC_H_
#define _LIBROARCRC_H_

#include "libroar.h"

uint32_t roar_crc24_add(uint32_t state, const void * data, size_t len);
#define roar_crc24_init() roar_crc24_add(0, NULL, 0)

uint32_t roar_adler32_add(uint32_t state, const void * data, size_t len);
#define roar_adler32_init() roar_adler32_add(0, NULL, 0)

int roar_hash_crc24_init(void * state);
int roar_hash_crc24_digest(void * state, void * digest, size_t * len);
int roar_hash_crc24_proc(void * state, const void * data, size_t len);

int roar_hash_adler32_init(void * state);
int roar_hash_adler32_digest(void * state, void * digest, size_t * len);
int roar_hash_adler32_proc(void * state, const void * data, size_t len);

#endif

//ll
