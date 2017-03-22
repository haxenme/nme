//nnode.h:

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

#ifndef _LIBROARNNODE_H_
#define _LIBROARNNODE_H_

#include "libroar.h"

struct roar_nnode {
 int socktype;
 union {
  unsigned char inet4[4];
  unsigned char inet6[16];
  struct {
   int area;
   int node;
  } decnet;
 } addr;
};

int roar_nnode_new        (struct roar_nnode * nnode, int socktype);
int roar_nnode_new_from_af(struct roar_nnode * nnode, int af);
int roar_nnode_new_from_sockaddr(struct roar_nnode * nnode, struct sockaddr * addr, socklen_t len);
int roar_nnode_new_from_fh(struct roar_nnode * nnode, int fh, int remote);

int roar_nnode_free       (struct roar_nnode * nnode);

int roar_nnode_get_socktype (struct roar_nnode * nnode);

int roar_nnode_to_str     (struct roar_nnode * nnode, char * str, size_t len);

int roar_nnode_from_blob  (struct roar_nnode * nnode, void * blob, size_t * len);
int roar_nnode_to_blob    (struct roar_nnode * nnode, void * blob, size_t * len);

int roar_nnode_cmp        (struct roar_nnode * n0, struct roar_nnode * n1);

#endif

//ll
