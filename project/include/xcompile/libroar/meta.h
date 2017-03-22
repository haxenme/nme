//meta.h:

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

#ifndef _LIBROARMETA_H_
#define _LIBROARMETA_H_

#include "libroar.h"

int roar_stream_meta_set (struct roar_connection * con, struct roar_stream * s, int mode, struct roar_meta * meta);
int roar_stream_meta_get (struct roar_connection * con, struct roar_stream * s, struct roar_meta * meta);

int roar_stream_meta_list (struct roar_connection * con, struct roar_stream * s, int * types, size_t len);

int roar_meta_free (struct roar_meta * meta);

const char * roar_meta_strtype(const int type);
int    roar_meta_inttype(const char * type);

const char * roar_meta_strgenre(const int genre);
int    roar_meta_intgenre(const char * genre);

int    roar_meta_parse_audioinfo(struct roar_audio_info * info, const char * str);

#endif

//ll
