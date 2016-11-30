//serverinfo.h:

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

#ifndef _LIBROARSERVERINFO_H_
#define _LIBROARSERVERINFO_H_

#include "libroar.h"

struct roar_server_info {
 const char * version;
 const char * location;
 const char * description;
 const char * contact;
 const char * serial;
 const char * address;
 const char * uiurl;
 const char * hostid;
 const char * license;
 const char * build;
 struct {
  const char * sysname;
  const char * release;
  const char * nodename;
  const char * machine;
 } un;
};

struct roar_server_info * roar_server_info(struct roar_connection * con);
struct roar_server_info * roar_library_info(void);
int roar_server_info_free(struct roar_server_info * info);

int roar_server_info_to_mes(struct roar_message * mes, struct roar_server_info * info, void ** data);
struct roar_server_info * roar_server_info_from_mes(struct roar_message * mes, void * data);

#endif

//ll
