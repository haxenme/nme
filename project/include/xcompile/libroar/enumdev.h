//enumdev.h:

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

#ifndef _LIBROARENUMDEV_H_
#define _LIBROARENUMDEV_H_

#include "libroar.h"

#define ROAR_ENUM_FLAG_NONE         0x0000 /* no flags set                     */
#define ROAR_ENUM_FLAG_DESC         0x0001 /* ask for server description     1 */
#define ROAR_ENUM_FLAG_LOCATION     0x0002 /* ask for server location        1 */
#define ROAR_ENUM_FLAG_NONBLOCK     0x0004 /* do not block                     */
#define ROAR_ENUM_FLAG_HARDNONBLOCK 0x0008 /* do even less block than NONBLOCK */
#define ROAR_ENUM_FLAG_LOCALONLY    0x0010 /* only list local servers          */
/*
 * 1 = This is a request. The result may include or not include the data anyway.
 *     This is only so the lib does not need to spend extra work when data is not needed.
 */

struct roar_server {
 const char * server;
 const char * description;
 const char * location;
};

struct roar_mixer {
 const int dir;
 //...
};

/* Get a list of possible devices
 *
 * This function returns a list of possible device names.
 * The list is for suggestions in GUIs and simular.
 * A implementation SHOULD (VERY, VERY RECOMMENDED) have a freeform
 * input so the user can enter any server address.
 *
 * The list returned is a array of struct roar_server elements.
 * The final element has the member server set to NULL.
 * This element represents the default server (libroar will try to find
 * a server on it's own).
 *
 */
struct roar_server * roar_enum_servers(int flags, int dir, int socktype);

/* Free the server list
 */
int roar_enum_servers_free(struct roar_server * servs);

/* Return the number of elements in the server list
 *
 * This function is a optimized way to find out how may entry are in the server list.
 * However you should not call this too often and avoid needing to know the total at all.
 * Write software in a way that it tests for the server == NULL condition.
 */
ssize_t roar_enum_servers_num(struct roar_server * servs);

#endif

//ll
