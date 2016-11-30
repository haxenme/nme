//vio.h:

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

#ifndef _LIBROARVIO_H_
#define _LIBROARVIO_H_

#include "libroar.h"

// some defines:
#define ROAR_VIOF_EXEC      O_EXEC
#define ROAR_VIOF_READ      O_RDONLY
#define ROAR_VIOF_WRITE     O_WRONLY
#define ROAR_VIOF_READWRITE O_RDWR
#define ROAR_VIOF_SEARCH    O_SEARCH
#define ROAR_VIOF_LISTEN    (-"") /* compiler error as long as there is no O_LISTEN */

#define ROAR_VIOF_CREAT     O_CREAT
#define ROAR_VIOF_TRUNC     O_TRUNC
#define ROAR_VIOF_APPEND    O_APPEND

#ifndef ROAR_TARGET_WIN32
#define ROAR_VIOF_NONBLOCK  O_NONBLOCK
#else
#define ROAR_VIOF_NONBLOCK  0
#endif

#define ROAR_VIO_FLAGS_NONE        0x00000000UL
#define ROAR_VIO_FLAGS_FREESELF    0x00000001UL /* Free the VIO object */

struct roar_connection;

// sys io:

typedef int32_t       roar_vio_ctl_t;
typedef int_least64_t roar_off_t;

struct roar_vio_calls {
 size_t           refc;
 uint32_t         flags;
 void            *inst;
 ssize_t        (*read    )(struct roar_vio_calls * vio, void *buf, size_t count);
 ssize_t        (*write   )(struct roar_vio_calls * vio, void *buf, size_t count);
 roar_off_t     (*lseek   )(struct roar_vio_calls * vio, roar_off_t offset, int whence);
 int            (*sync    )(struct roar_vio_calls * vio);
 int            (*ctl     )(struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data);
 int            (*close   )(struct roar_vio_calls * vio);
};

int roar_vio_clear_calls (struct roar_vio_calls * calls);

ssize_t roar_vio_read    (struct roar_vio_calls * vio, void *buf, size_t count) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;
ssize_t roar_vio_write   (struct roar_vio_calls * vio, void *buf, size_t count) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;
roar_off_t   roar_vio_lseek   (struct roar_vio_calls * vio, roar_off_t offset, int whence) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;
int     roar_vio_nonblock(struct roar_vio_calls * vio, int state) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;
int     roar_vio_sync    (struct roar_vio_calls * vio) _LIBROAR_ATTR_NONNULL_ALL;
int     roar_vio_ctl     (struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1);

#define roar_vio_close(x) roar_vio_unref((x))
int     roar_vio_ref     (struct roar_vio_calls * vio) _LIBROAR_ATTR_NONNULL_ALL;
int     roar_vio_unref   (struct roar_vio_calls * vio) _LIBROAR_ATTR_NONNULL_ALL;

// special commands:
int     roar_vio_accept  (struct roar_vio_calls * calls, struct roar_vio_calls * dst) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;
int     roar_vio_shutdown(struct roar_vio_calls * vio,   int how) _LIBROAR_ATTR_NONNULL_ALL;

// converters:
int     roar_vio_open_fh       (struct roar_vio_calls * calls, int fh) _LIBROAR_ATTR_NONNULL_ALL;
int     roar_vio_open_fh_socket(struct roar_vio_calls * calls, int fh) _LIBROAR_ATTR_NONNULL_ALL;

int     roar_vio_open_socket   (struct roar_vio_calls * calls, const char * host, int port) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;
int     roar_vio_open_socket_listen(struct roar_vio_calls * calls, int type, const char * host, int port) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;

int     roar_vio_simple_stream (struct roar_vio_calls * calls,
                                uint32_t rate, uint32_t channels, uint32_t bits, uint32_t codec,
                                const char * server, int dir, const char * name, int mixer);

int     roar_vio_simple_new_stream_obj (struct roar_vio_calls * calls,
                                        struct roar_connection * con,
                                        struct roar_stream * s,
                                        uint32_t rate, uint32_t channels, uint32_t bits, uint32_t codec,
                                        int dir, int mixer);

// possible VIOs:

// basic
ssize_t roar_vio_basic_read    (struct roar_vio_calls * vio, void *buf, size_t count);
ssize_t roar_vio_basic_write   (struct roar_vio_calls * vio, void *buf, size_t count);
roar_off_t   roar_vio_basic_lseek   (struct roar_vio_calls * vio, roar_off_t offset, int whence);
int     roar_vio_basic_sync    (struct roar_vio_calls * vio);
int     roar_vio_basic_ctl     (struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data);
int     roar_vio_basic_close   (struct roar_vio_calls * vio);

// null
// this is a read and write in one!
ssize_t roar_vio_null_rw    (struct roar_vio_calls * vio, void *buf, size_t count);
int     roar_vio_null_sync  (struct roar_vio_calls * vio);

// pass

int     roar_vio_open_pass    (struct roar_vio_calls * calls, struct roar_vio_calls * dst);
ssize_t roar_vio_pass_read    (struct roar_vio_calls * vio, void *buf, size_t count);
ssize_t roar_vio_pass_write   (struct roar_vio_calls * vio, void *buf, size_t count);
roar_off_t   roar_vio_pass_lseek   (struct roar_vio_calls * vio, roar_off_t offset, int whence);
int     roar_vio_pass_sync    (struct roar_vio_calls * vio);
int     roar_vio_pass_ctl     (struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data);
int     roar_vio_pass_close   (struct roar_vio_calls * vio);

// re-read/write

int     roar_vio_open_re (struct roar_vio_calls * calls, struct roar_vio_calls * dst);
ssize_t roar_vio_re_read (struct roar_vio_calls * vio, void *buf, size_t count);
ssize_t roar_vio_re_write(struct roar_vio_calls * vio, void *buf, size_t count);
roar_off_t   roar_vio_re_lseek(struct roar_vio_calls * vio, roar_off_t offset, int whence);

#endif

//ll
