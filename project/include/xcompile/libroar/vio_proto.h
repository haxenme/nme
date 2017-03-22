//vio_proto.h:

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

#ifndef _LIBROARVIO_PROTO_H_
#define _LIBROARVIO_PROTO_H_

#include "libroar.h"

struct roar_vio_defaults;

#define ROAR_VIO_PROTO_P_NONE      0
#define ROAR_VIO_PROTO_P_HTTP      1
#define ROAR_VIO_PROTO_P_GOPHER    2
#define ROAR_VIO_PROTO_P_ICY       3

struct roar_vio_proto {
 struct roar_vio_calls * next;
 struct {
  struct roar_buffer * buffer;
 } reader, writer;
 struct {
  size_t metaint;
  size_t leftint;
  struct roar_buffer * mdbuf;
 } metadata;
 char * content_type;
 int proto;
};

int roar_vio_proto_init_def  (struct roar_vio_defaults * def, char * dstr, int proto, struct roar_vio_defaults * odef);

int roar_vio_open_proto      (struct roar_vio_calls * calls, struct roar_vio_calls * dst,
                              const char * dstr, int proto, struct roar_vio_defaults * odef);

ssize_t roar_vio_proto_read    (struct roar_vio_calls * vio, void *buf, size_t count);
ssize_t roar_vio_proto_write   (struct roar_vio_calls * vio, void *buf, size_t count);
int     roar_vio_proto_sync    (struct roar_vio_calls * vio);
int     roar_vio_proto_ctl     (struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data);
int     roar_vio_proto_close   (struct roar_vio_calls * vio);

int roar_vio_open_proto_http   (struct roar_vio_calls * calls, struct roar_vio_calls * dst, const char * host, const char * file, struct roar_userpass * up);
int roar_vio_open_proto_gopher (struct roar_vio_calls * calls, struct roar_vio_calls * dst, const char * host, const char * file);
#endif

//ll
