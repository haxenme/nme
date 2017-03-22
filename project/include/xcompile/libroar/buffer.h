//buffer.h:

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

#ifndef _LIBROAR_BUFFER_H_
#define _LIBROAR_BUFFER_H_

#include <roaraudio.h>

#define ROAR_BUFFER_FLAG_NONE            0x00
#define ROAR_BUFFER_FLAG_NOFREE          0x01
#define ROAR_BUFFER_FLAG_RING            0x02
#define ROAR_BUFFER_FLAG_FREE_RUNNING    0x04

// for memory corruption detection:
#define ROAR_BUFFER_FLAG_USEABLE         0x40
#define ROAR_BUFFER_FLAG_FREED           0x80

#define ROAR_BUFFER_SET                     0
#define ROAR_BUFFER_RESET                   1

#define _LIBROAR_BUFFER_STDATTRS _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL

struct roar_buffer;

struct roar_buffer_stats {
 size_t parts;
 size_t bytes;
 size_t memory_usage;
};

#define roar_buffer_new(a,len) roar_buffer_new_data((a), (len), NULL)

#define roar_buffer_free(x)    roar_buffer_unref(x)

#define roar_buffer_foreach(cur) for (; (cur) != NULL; (cur) = (roar_buffer_next(&(cur)) == -1) ? NULL : (cur))

int roar_buffer_new_no_ma(struct roar_buffer ** buf, size_t len, void * data) _LIBROAR_BUFFER_STDATTRS; // no internal malloc
int roar_buffer_delete   (struct roar_buffer *  buf, struct roar_buffer ** next) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_next     (struct roar_buffer ** buf) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_add      (struct roar_buffer *  buf, struct roar_buffer *  next) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_moveinto (struct roar_buffer *  buf, struct roar_buffer ** next) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_moveintoqueue(struct roar_buffer ** buf, struct roar_buffer ** next) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_ref      (struct roar_buffer *  buf) _LIBROAR_ATTR_NONNULL_ALL;
int roar_buffer_unref    (struct roar_buffer *  buf) _LIBROAR_ATTR_NONNULL_ALL;

int roar_buffer_new_data (struct roar_buffer ** buf, size_t len, void ** data) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1);

int roar_buffer_new_str  (struct roar_buffer ** buf, const char * str, int terminate) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;

int roar_buffer_ring_new (struct roar_buffer ** buf, size_t len, int free_running) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_get_next   (struct roar_buffer *  buf, struct roar_buffer ** next) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_get_data (struct roar_buffer   * buf, void   ** data) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_get_datalen(struct roar_buffer * buf, void   ** data, size_t * len) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_set_offset (struct roar_buffer *  buf, size_t off) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_shift_out (struct roar_buffer ** buf, void * data, size_t * len) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_set_meta    (struct roar_buffer *  buf, void    *  meta) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_get_meta    (struct roar_buffer *  buf, void    ** meta) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_set_meta_i32(struct roar_buffer *  buf, int32_t    meta) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_get_meta_i32(struct roar_buffer *  buf, int32_t *  meta) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_set_type    (struct roar_buffer *  buf, int        type) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_get_type    (struct roar_buffer *  buf, int     *  type) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_set_len  (struct roar_buffer *  buf, size_t    len) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_get_len  (struct roar_buffer *  buf, size_t *  len) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_set_flag (struct roar_buffer *  buf, int flag, int reset) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_get_flag (struct roar_buffer *  buf, int flag) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_duplicate (struct roar_buffer *  buf, struct roar_buffer ** copy) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_ring_stats (struct roar_buffer *  buf, struct roar_buffer_stats * stats) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_ring_read  (struct roar_buffer *  buf, void * data, size_t * len) _LIBROAR_BUFFER_STDATTRS;
int roar_buffer_ring_write (struct roar_buffer *  buf, void * data, size_t * len) _LIBROAR_BUFFER_STDATTRS;

int roar_buffer_ring_avail(struct roar_buffer *  buf, size_t * readlen, size_t * writelen) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1);

int roar_buffer_ring_reset(struct roar_buffer *  buf) _LIBROAR_BUFFER_STDATTRS;

#endif

//ll
