//vio_select.h:

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

#ifndef _LIBROARVIO_SELECT_H_
#define _LIBROARVIO_SELECT_H_

#include "libroar.h"

#define ROAR_VIO_SELECT_NONE          0x0000
#define ROAR_VIO_SELECT_READ          0x0001
#define ROAR_VIO_SELECT_WRITE         0x0002
#define ROAR_VIO_SELECT_EXCEPT        0x0004
#define ROAR_VIO_SELECT_NO_RETEST     0x4000 /* uppermostt bit set */

#define ROAR_VIO_SELECT_ACTION_NONE   0x00
#define ROAR_VIO_SELECT_ACTION_SELECT 0x01
#define ROAR_VIO_SELECT_ACTION_POLL   0x02
#define ROAR_VIO_SELECT_ACTION_VIOS   0x04 /* VIO Select */

#define ROAR_VIO_SELECT_SETVIO(d,v,q) ((d)->vio = (v)); ((d)->fh = -1); ((d)->eventsq = (q))
#define ROAR_VIO_SELECT_SETSYSIO(d,f,q) ((d)->vio = NULL); ((d)->fh = (f)); ((d)->eventsq = (q))

struct roar_vio_select_internal {
 int action;
 int fh[3];
};

struct roar_vio_select {
 struct roar_vio_calls * vio;
 int fh;
 int eventsq;
 int eventsa;
 union {
  int    si;
  void * vp;
 } ud;
 struct roar_vio_select_internal internal;
};

struct roar_vio_selectctl {
 int strategy;
};

struct roar_vio_selecttv {
 int64_t sec;
 int32_t nsec;
};

ssize_t roar_vio_select(struct roar_vio_select * vios, size_t len, struct roar_vio_selecttv * rtv, struct roar_vio_selectctl * ctl);

#endif

//ll
