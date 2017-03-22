//vio_pipe.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2009-2013
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

#ifndef _LIBROARVIO_PIPE_H_
#define _LIBROARVIO_PIPE_H_

#include "libroar.h"

#define ROAR_VIO_PIPE_TYPE_AUTO        -1
#define ROAR_VIO_PIPE_TYPE_AUTO_FORK    ROAR_VIO_PIPE_TYPE_AUTO
#define ROAR_VIO_PIPE_TYPE_AUTO_NOFORK  ROAR_VIO_PIPE_TYPE_AUTO
#define ROAR_VIO_PIPE_TYPE_NONE         0
#define ROAR_VIO_PIPE_TYPE_BUFFER       1
#define ROAR_VIO_PIPE_TYPE_PIPE         2
#define ROAR_VIO_PIPE_TYPE_SOCKET       3

#define ROAR_VIO_PIPE_S(self,stream)   ((self->s0) == (stream) ? 0 : 1)
#define ROAR_VIO_PIPE_SR(self,stream)  ((self->s0) == (stream) ? 1 : 0)
#define ROAR_VIO_PIPE_SF(self,stream)  ROAR_VIO_PIPE_S(self,stream)

struct roar_vio_pipe {
 int refcount;
 int type;
 int flags;
 union {
  struct roar_buffer * b[2];
  int                  p[4];
 } b;
 struct roar_vio_calls * s0;
};

int roar_vio_open_pipe (struct roar_vio_calls * s0, struct roar_vio_calls * s1, int type, int flags);
int roar_vio_pipe_init (struct roar_vio_calls * s,  struct roar_vio_pipe * self, int flags);

ssize_t roar_vio_pipe_read    (struct roar_vio_calls * vio, void *buf, size_t count);
ssize_t roar_vio_pipe_write   (struct roar_vio_calls * vio, void *buf, size_t count);
int     roar_vio_pipe_sync    (struct roar_vio_calls * vio);
int     roar_vio_pipe_ctl     (struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data);
int     roar_vio_pipe_close   (struct roar_vio_calls * vio);

#endif

//ll
