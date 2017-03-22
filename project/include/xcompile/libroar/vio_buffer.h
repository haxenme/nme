//vio_buffer.h:

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

#ifndef _LIBROARVIO_BUFFER_H_
#define _LIBROARVIO_BUFFER_H_

#include "libroar.h"

struct roar_vio_buffer_offset {
 int is_old;
 size_t offset;
};

struct roar_vio_buffer {
 struct roar_vio_calls * backend;
 struct roar_buffer * buf_old, * buf_cur;
 size_t len_old, len_cur;
 ssize_t min_bufsize;
 struct roar_vio_buffer_offset offset;
 struct roar_vio_calls re_vio;
 int use_re;
 size_t abspos;
};

int     roar_vio_open_buffer    (struct roar_vio_calls * calls, struct roar_vio_calls * dst, ssize_t minsize, int use_re);
ssize_t roar_vio_buffer_read    (struct roar_vio_calls * vio, void *buf, size_t count);
ssize_t roar_vio_buffer_write   (struct roar_vio_calls * vio, void *buf, size_t count);
roar_off_t   roar_vio_buffer_lseek   (struct roar_vio_calls * vio, roar_off_t offset, int whence);
int     roar_vio_buffer_sync    (struct roar_vio_calls * vio);
int     roar_vio_buffer_ctl     (struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data);
int     roar_vio_buffer_close   (struct roar_vio_calls * vio);

#endif

//ll
