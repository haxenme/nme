//time.h:

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

#ifndef _LIBROARTIME_H_
#define _LIBROARTIME_H_

#include "libroar.h"

struct roar_time {
 int64_t  t_sec;   // secund part of system time
 uint64_t t_ssec;  // sub secs in 2^-64sec units.
 uint64_t c_freq;  // clock freq in nHz. (use zero for unknown/undefined)
 uint64_t c_drift; // clock drift in 2^-64sec per sec. (use zero for unknown/undefined)
};

int roar_time_to_msg(struct roar_message * mes,  struct roar_time    * time);
int roar_time_from_msg(struct roar_time  * time, struct roar_message * mes);

int roar_get_time  (struct roar_connection * con, struct roar_time * time);

int roar_clock_gettime(struct roar_time * rt, int clock);

#endif

//ll
