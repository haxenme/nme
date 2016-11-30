//vio_stdio.h:

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

#ifndef _LIBROARVIO_STDIO_H_
#define _LIBROARVIO_STDIO_H_

#include "libroar.h"

int     roar_vio_open_stdio    (struct roar_vio_calls * calls, FILE * dst);

FILE *  roar_vio_to_stdio      (struct roar_vio_calls * calls, int flags);
#if defined(ROAR_HAVE_FOPENCOOKIE) || defined(ROAR_HAVE_FUNOPEN)
int roar_vio_to_stdio_close (void *__cookie);
#endif
#if defined(ROAR_HAVE_FOPENCOOKIE)
ssize_t roar_vio_to_stdio_read (void *__cookie, char *__buf, size_t __nbytes);
ssize_t roar_vio_to_stdio_write (void *__cookie, __const char *__buf, size_t __n);
int roar_vio_to_stdio_lseek (void *__cookie, _IO_off64_t *__pos, int __w);
#elif defined(ROAR_HAVE_FUNOPEN)
int roar_vio_to_stdio_read(void *__cookie, char *__buf, int __nbytes);
int roar_vio_to_stdio_write(void *__cookie, const char *__buf, int __n);
fpos_t roar_vio_to_stdio_lseek(void *__cookie, fpos_t __pos, int __w);
#endif


// stdio
ssize_t roar_vio_stdio_read    (struct roar_vio_calls * vio, void *buf, size_t count);
ssize_t roar_vio_stdio_write   (struct roar_vio_calls * vio, void *buf, size_t count);
roar_off_t   roar_vio_stdio_lseek   (struct roar_vio_calls * vio, roar_off_t offset, int whence);
int     roar_vio_stdio_sync    (struct roar_vio_calls * vio);
int     roar_vio_stdio_ctl     (struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data);
int     roar_vio_stdio_close   (struct roar_vio_calls * vio);

#endif

//ll
