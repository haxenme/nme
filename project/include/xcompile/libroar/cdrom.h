//cdrom.h:

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

#ifndef _LIBROARCDROM_H_
#define _LIBROARCDROM_H_

#include "libroar.h"

#define ROAR_CDROM_MAX_DEVLEN 80

#define ROAR_CDROM_RATE      44100
#define ROAR_CDROM_CHANNELS  2
#define ROAR_CDROM_BITS      16
#define ROAR_CDROM_CODEC     ROAR_CODEC_DEFAULT /* we ask cdparanoia to output in host byte order */

#define ROAR_CDROM_STREAMINFO ROAR_CDROM_RATE, ROAR_CDROM_CHANNELS, ROAR_CDROM_BITS, ROAR_CDROM_CODEC

struct roar_cdrom {
 int play_local;
 int fh;
 int stream;
 int mixer;
 pid_t player;
 char device[ROAR_CDROM_MAX_DEVLEN];
 struct roar_connection * con;
};

struct roar_cdrom_title {
 int track;                 // 0..n, -1 = unset/end of list
 uint32_t start;            // offset in samples
 uint32_t length;           // length in samples
};

int roar_cdrom_open (struct roar_connection * con, struct roar_cdrom * cdrom, const char * device, int mixer);
int roar_cdrom_close(struct roar_cdrom * cdrom);
int roar_cdrom_stop (struct roar_cdrom * cdrom);
int roar_cdrom_play (struct roar_cdrom * cdrom, int track);

#endif

//ll
