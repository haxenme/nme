//keyval.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2010-2013
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

#ifndef _LIBROARKEYVAL_H_
#define _LIBROARKEYVAL_H_

#include "libroar.h"

struct roar_keyval {
 char * key;
 char * value;
};

struct roar_keyval * roar_keyval_lookup (struct roar_keyval *  kv, const char * key, ssize_t len, int casesens);

/* Split string into kv array.
 * Array needs to be freed with roar_mm_free().
 * String is not copied and destroyed by splitting but not freed.
 * fdel is list of seperator chars between kv-pairs.
 * kdel is list of seperator chars between keys and values.
 */
ssize_t              roar_keyval_split  (struct roar_keyval ** kv, char * str, const char * fdel, const char * kdel, int quotes);

void * roar_keyval_copy(struct roar_keyval ** copy, const struct roar_keyval * src, ssize_t len);

#endif

//ll
