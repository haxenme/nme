//simple.h:

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

#ifndef _LIBROARSIMPLE_H_
#define _LIBROARSIMPLE_H_

#include "libroar.h"

int roar_simple_connect (struct roar_connection * con, const char * server, const char * name);
int roar_simple_connect2(struct roar_connection * con, const char * server, const char * name, int flags, uint_least32_t timeout);

int roar_simple_new_stream_attachexeced_obj (struct roar_connection * con, struct roar_stream * s, uint32_t rate, uint32_t channels, uint32_t bits, uint32_t codec, int dir, int mixer);

int roar_simple_play_file(const char * file, const char * server, const char * name);

int roar_simple_connect_virtual(struct roar_connection * con, struct roar_stream * s, int parent, int dir);

#endif

//ll
