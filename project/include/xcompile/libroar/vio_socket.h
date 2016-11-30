//vio_socket.h:

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

#ifndef _LIBROARVIO_SOCKET_H_
#define _LIBROARVIO_SOCKET_H_

#include "libroar.h"

struct roar_vio_defaults;

int     roar_vio_open_def_socket          (struct roar_vio_calls * calls, struct roar_vio_defaults * def, char * opts);

int     roar_vio_socket_init_socket_def   (struct roar_vio_defaults * def, int domain, int type);

int     roar_vio_socket_init_dstr_def     (struct roar_vio_defaults * def, char * dstr, int hint, int type, struct roar_vio_defaults * odef);

int     roar_vio_socket_conv_def          (struct roar_vio_defaults * def, int domain);

int     roar_vio_socket_get_port          (char * service, int domain, int type);

int     roar_vio_socket_init_unix_def     (struct roar_vio_defaults * def, const char * path);

int     roar_vio_socket_init_decnetnode_def(struct roar_vio_defaults * def);
int     roar_vio_socket_init_decnet_def   (struct roar_vio_defaults * def, const char * node, int object, char * objname);

int     roar_vio_socket_init_inet4host_def(struct roar_vio_defaults * def);
int     roar_vio_socket_init_inet4_def    (struct roar_vio_defaults * def, const char * host, int port, int type);
int     roar_vio_socket_init_tcp4_def     (struct roar_vio_defaults * def, const char * host, int port);
int     roar_vio_socket_init_udp4_def     (struct roar_vio_defaults * def, const char * host, int port);
int     roar_vio_socket_init_inet6host_def(struct roar_vio_defaults * def);
int     roar_vio_socket_init_inet6_def    (struct roar_vio_defaults * def, const char * host, int port, int type);
int     roar_vio_socket_init_tcp6_def     (struct roar_vio_defaults * def, const char * host, int port);
int     roar_vio_socket_init_udp6_def     (struct roar_vio_defaults * def, const char * host, int port);

#endif

//ll
