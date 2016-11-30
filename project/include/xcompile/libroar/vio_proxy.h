//vio_proxy.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2011-2013
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

#ifndef _LIBROARVIO_PROXY_H_
#define _LIBROARVIO_PROXY_H_

#include "libroar.h"

enum roar_vio_proxy_type {
 ROAR_VIO_PROXY_INVALID = -1,
 ROAR_VIO_PROXY_NONE    = 0,
#define ROAR_VIO_PROXY_NONE ROAR_VIO_PROXY_NONE
 ROAR_VIO_PROXY_SOCKS   = 1, /* unknown version */
#define ROAR_VIO_PROXY_SOCKS ROAR_VIO_PROXY_SOCKS
 ROAR_VIO_PROXY_SOCKS4  = 2,
#define ROAR_VIO_PROXY_SOCKS4 ROAR_VIO_PROXY_SOCKS4
 ROAR_VIO_PROXY_SOCKS4a = 3,
#define ROAR_VIO_PROXY_SOCKS4a ROAR_VIO_PROXY_SOCKS4a
 ROAR_VIO_PROXY_SOCKS4d = 4,
#define ROAR_VIO_PROXY_SOCKS4d ROAR_VIO_PROXY_SOCKS4d
 ROAR_VIO_PROXY_SOCKS5  = 5,
#define ROAR_VIO_PROXY_SOCKS5 ROAR_VIO_PROXY_SOCKS5
 ROAR_VIO_PROXY_HTTP    = 6,
#define ROAR_VIO_PROXY_HTTP ROAR_VIO_PROXY_HTTP
 ROAR_VIO_PROXY_SSH     = 7
#define ROAR_VIO_PROXY_SSH ROAR_VIO_PROXY_SSH
};

int roar_vio_proxy_init_def(struct roar_vio_defaults * def,
                            char * dstr, enum roar_vio_proxy_type type,
                            struct roar_vio_defaults * odef);
int roar_vio_open_proxy    (struct roar_vio_calls * calls, struct roar_vio_calls * dst,
                            enum roar_vio_proxy_type type, struct roar_vio_defaults * odef);

// DSTR interface:
struct roar_vio_dstr_chain;
int roar_vio_proxy_setdef(struct roar_vio_dstr_chain * cur,   struct roar_vio_dstr_chain * next);
int roar_vio_proxy_openvio(struct roar_vio_calls * calls, struct roar_vio_calls * dst, struct roar_vio_dstr_chain * cur, struct roar_vio_dstr_chain * next);

#endif

//ll
