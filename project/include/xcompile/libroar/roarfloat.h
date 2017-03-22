//roarfloat.h:

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

#ifndef _LIBROARROARFLOAT_H_
#define _LIBROARROARFLOAT_H_

#include "libroar.h"

typedef uint32_t roarfloat32;

#define ROAR_UFLOAT32_MAX  65535

#define ROAR_UFLOAT32_ZERO ROAR_HOST2NET32(0x00000000);
#define ROAR_UFLOAT32_PINF ROAR_HOST2NET32(0x00000001);
#define ROAR_UFLOAT32_NINF ROAR_HOST2NET32(0x0000FFFF);
#define ROAR_UFLOAT32_PNAN ROAR_HOST2NET32(0x00007FFF);
#define ROAR_UFLOAT32_NNAN ROAR_HOST2NET32(0x00008000);

roarfloat32 roar_ufloat32_build(const uint16_t mul, const uint16_t scale);
uint16_t roar_ufloat32_scale(const roarfloat32 f);
uint16_t roar_ufloat32_mul(const roarfloat32 f);

roarfloat32 roar_ufloat32_from_float(const float       f);
float       roar_ufloat32_to_float  (const roarfloat32 f);

int roar_float32_iszero(const roarfloat32 f);
int roar_float32_isinf(const roarfloat32 f);
int roar_float32_isnan(const roarfloat32 f);

#endif

//ll
