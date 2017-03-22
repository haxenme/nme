//hash_tiger.h:

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

#ifndef _LIBROARHASH_TIGER_H_
#define _LIBROARHASH_TIGER_H_

#include "libroar.h"

struct roar_hash_tiger {
 uint64_t a, b, c;
 char inbuf[64];
 size_t inlen;
 size_t blocks;
 int is_final;
};

// init and deinit functions:
int roar_hash_tiger_init(struct roar_hash_tiger * state);
int roar_hash_tiger_uninit(struct roar_hash_tiger * state);

// functions needed for string internal state:
int roar_hash_tiger_init_from_pstate(struct roar_hash_tiger * state, void * oldstate);
int roar_hash_tiger_to_pstate(struct roar_hash_tiger * state, void * newstate, size_t * len);
ssize_t roar_hash_tiger_statelen(struct roar_hash_tiger * state);

// finalize, should not be called directly:
int roar_hash_tiger_finalize(struct roar_hash_tiger * state);

// finalize and get final digest:
int roar_hash_tiger_get_digest(struct roar_hash_tiger * state, void * digest, size_t * len);

// optimized functions to process fixed size data blocks:
int roar_hash_tiger_proc_block(struct roar_hash_tiger * state, void * block);
ssize_t roar_hash_tiger_blocklen(struct roar_hash_tiger * state);

// normal function to process data:
int roar_hash_tiger_proc(struct roar_hash_tiger * state, void * data, size_t len);

#endif

//ll
