//vio_string.h:

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

#ifndef _LIBROARVIO_STRING_H_
#define _LIBROARVIO_STRING_H_

#include "libroar.h"

// some alias functions:
#define roar_vio_puts(vio,s) roar_vio_write((vio), (s), roar_mm_strlen((s)))
//#define roar_vio_putc(vio,c) roar_vio_write((vio), &(c), 1)
int     roar_vio_putc    (struct roar_vio_calls * vio, char c) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;
int     roar_vio_getc    (struct roar_vio_calls * vio) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;
char *  roar_vio_fgets   (struct roar_vio_calls * vio, char * s, size_t size) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;

int     roar_vio_printf  (struct roar_vio_calls * vio, const char *format, ...) _LIBROAR_ATTR_NONNULL(1, 2) _LIBROAR_ATTR_PRINTF(2, 3);

#endif

//ll
