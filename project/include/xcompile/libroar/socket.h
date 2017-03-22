//socket.h:

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

#ifndef _LIBROARSOCKET_H_
#define _LIBROARSOCKET_H_

#include "libroar.h"

#define ROAR_SOCKET_MODE_NONE    0
#define ROAR_SOCKET_MODE_LISTEN  1
#define ROAR_SOCKET_MODE_CONNECT 2

#define ROAR_SOCKET_QUEUE_LEN 8

#define ROAR_SOCKET_BLOCK     1
#define ROAR_SOCKET_NONBLOCK  2

#define ROAR_SOCKET_MAX_HOSTNAMELEN 64

int roar_socket_listen  (int type, const char * host, int port);
int roar_socket_connect (int type, const char * host, int port);

// TODO: those function should be made /static/.
#if 0
int roar_socket_new_decnet_seqpacket (void) _LIBROAR_ATTR_TO_STATIC;
int roar_socket_new_ipxspx (void) _LIBROAR_ATTR_TO_STATIC;
#endif

int roar_socket_new        (int type);

int roar_socket_open       (int mode, int type, const char * host, int port);

const char * roar_socket_get_local_nodename(void);

int roar_socket_nonblock(int fh, int state);

int roar_socket_dup_udp_local_end (int fh);

int roar_socket_send_fh (int sock, int fh, char * mes, size_t   len);
int roar_socket_recv_fh (int sock,         char * mes, size_t * len);

#endif

//ll
