//hash.h:

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

#ifndef _LIBROARHASH_H_
#define _LIBROARHASH_H_

#include "libroar.h"

typedef uint_least32_t roar_hash_t;

// the hashtypes:
#define ROAR_HT_NONE        ((roar_hash_t)0UL)
#define ROAR_HT_MD5         ((roar_hash_t)1UL)
#define ROAR_HT_SHA1        ((roar_hash_t)2UL)
#define ROAR_HT_RIPEMD160   ((roar_hash_t)3UL)
#define ROAR_HT_MD2         ((roar_hash_t)5UL)
#define ROAR_HT_TIGER       ((roar_hash_t)6UL)
#define ROAR_HT_HAVAL       ((roar_hash_t)7UL)
#define ROAR_HT_SHA256      ((roar_hash_t)8UL)
#define ROAR_HT_SHA384      ((roar_hash_t)9UL)
#define ROAR_HT_SHA512      ((roar_hash_t)10UL)
#define ROAR_HT_SHA224      ((roar_hash_t)11UL)
#define ROAR_HT_MD4         ((roar_hash_t)301UL)
#define ROAR_HT_CRC32       ((roar_hash_t)302UL)
#define ROAR_HT_RFC1510     ((roar_hash_t)303UL)
#define ROAR_HT_RFC2440     ((roar_hash_t)304UL)
#define ROAR_HT_WHIRLPOOL   ((roar_hash_t)305UL)
#define ROAR_HT_UUID        ((roar_hash_t)70000UL)
#define ROAR_HT_GTN8        ((roar_hash_t)70001UL)
#define ROAR_HT_GTN16       ((roar_hash_t)70002UL)
#define ROAR_HT_GTN32       ((roar_hash_t)70004UL)
#define ROAR_HT_GTN64       ((roar_hash_t)70008UL)
#define ROAR_HT_CLIENTID    ((roar_hash_t)71001UL)
#define ROAR_HT_STREAMID    ((roar_hash_t)71002UL)
#define ROAR_HT_SOURCEID    ((roar_hash_t)71003UL)
#define ROAR_HT_SAMPLEID    ((roar_hash_t)71004UL)
#define ROAR_HT_MIXERID     ((roar_hash_t)71005UL)
#define ROAR_HT_BRIDGEID    ((roar_hash_t)71006UL)
#define ROAR_HT_LISTENID    ((roar_hash_t)71007UL)
#define ROAR_HT_ACTIONID    ((roar_hash_t)71008UL)
#define ROAR_HT_MSGQUEUEID  ((roar_hash_t)71009UL)
#define ROAR_HT_MSGBUSID    ((roar_hash_t)71010UL)
#define ROAR_HT_GTIN8       ((roar_hash_t)72001UL)
#define ROAR_HT_GTIN13      ((roar_hash_t)72002UL)
#define ROAR_HT_ISBN10      ((roar_hash_t)72003UL)
#define ROAR_HT_ISBN13      ROAR_HT_GTIN13
#define ROAR_HT_ADLER32     ((roar_hash_t)73001UL)

struct roar_hash_cmds {
 roar_hash_t algo;
 ssize_t statelen;
 ssize_t blocksize;
 int (*init)(void * state);
 int (*uninit)(void * state);
 int (*digest)(void * state, void * digest, size_t * len);
 int (*proc_block)(void * state, const void * block);
 int (*proc)(void * state, const void * data, size_t len);
};

const char * roar_ht2str (const roar_hash_t ht);
roar_hash_t  roar_str2ht (const char  * ht);

ssize_t      roar_ht_digestlen (const roar_hash_t ht);

ssize_t      roar_hash_digest2str(char * out, size_t outlen, void * digest, size_t digestlen, roar_hash_t ht);

int          roar_ht_is_supported(const roar_hash_t ht);

struct roar_hash_state;

struct roar_hash_state * roar_hash_new(roar_hash_t algo);
int roar_hash_free(struct roar_hash_state * state);
int roar_hash_digest(struct roar_hash_state * state, void * digest, size_t * len);
int roar_hash_proc(struct roar_hash_state * state, const void * data, size_t len);

int roar_hash_buffer(void * digest, const void * data, size_t datalen, roar_hash_t algo);
int roar_hash_salted_buffer(void * digest, const void * data, size_t datalen, roar_hash_t algo, const void * salt, size_t saltlen);


// 'forwardings' for hashes without own header:
struct roar_hash_sha1 {
 uint32_t state[5];
 uint64_t count;
 size_t in_buffer;
 char buffer[64];
 int is_final;
};

#endif

//ll
