//random.h:

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

#ifndef _LIBROARRANDOM_H_
#define _LIBROARRANDOM_H_

#include "libroar.h"

#define ROAR_RANDOM_NONE         0
#define ROAR_RANDOM_VERY_WEAK    1
#define ROAR_RANDOM_WEAK         2
#define ROAR_RANDOM_NORMAL       3
#define ROAR_RANDOM_STRONG       4
#define ROAR_RANDOM_VERY_STRONG  5

#define ROAR_RANDOM_NONCE        ROAR_RANDOM_VERY_WEAK

int roar_random_gen_nonce(void * buffer, size_t len);

int roar_random_salt_nonce (void * salt, size_t len);

uint16_t roar_random_uint16(void);
uint32_t roar_random_uint32(void);

int roar_random_gen(void * buffer, size_t len, int quality);

void * roar_random_genbuf(size_t len, int quality, int locked);

#endif

//ll
