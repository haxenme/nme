//base64.h:

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

#ifndef _LIBROARBASE64_H_
#define _LIBROARBASE64_H_

#include "libroar.h"

#define ROAR_BASE64_FLAG_NONE           0x0000
#define ROAR_BASE64_FLAG_EOF            0x0001
#define ROAR_BASE64_FLAG_OPENPGP        0x0002
#define ROAR_BASE64_FLAG_CRC_OK         0x0004

struct roar_base64 {
 int flags;
 unsigned char iobuf[3];
 int buflen;
 int reg, reglen;
};

int roar_base64_init(struct roar_base64 * state, int flags);

#define roar_base64_init_encode(state,flags) roar_base64_init((state),(flags))
#define roar_base64_init_decode(state,flags) roar_base64_init((state),(flags))

ssize_t roar_base64_encode(struct roar_base64 * state, void * out, size_t outlen, const void * in, size_t inlen, size_t * off, int eof);

ssize_t roar_base64_decode(struct roar_base64 * state, void * out, size_t outlen, const void * in, size_t inlen, size_t * off);

int roar_base64_is_eof(struct roar_base64 * state);

int roar_base64_uninit(struct roar_base64 * state);

#endif

//ll
