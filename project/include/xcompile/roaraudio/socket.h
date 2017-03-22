//socket.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2008-2013
 *
 *  This file is part of RoarAudio,
 *  a cross-platform sound system for both, home and professional use.
 *  See README for details.
 *
 *  This file is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License version 3
 *  as published by the Free Software Foundation.
 *
 *  RoarAudio is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this software; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 *  NOTE: Even though this file is LGPLed it (may) include GPLed files
 *  so the license of this file is/may therefore downgraded to GPL.
 *  See HACKING for details.
 */

#ifndef _ROARAUDIO_SOCKET_H_
#define _ROARAUDIO_SOCKET_H_

#define ROAR_SOCKET_TYPE_NONE             0
#define ROAR_SOCKET_TYPE_UNKNOWN          ROAR_SOCKET_TYPE_NONE
#define ROAR_SOCKET_TYPE_INET             1
#define ROAR_SOCKET_TYPE_TCP              ROAR_SOCKET_TYPE_INET
#define ROAR_SOCKET_TYPE_UNIX             2
#define ROAR_SOCKET_TYPE_FORK             3
#define ROAR_SOCKET_TYPE_PIPE             ROAR_SOCKET_TYPE_FORK
#define ROAR_SOCKET_TYPE_FILE             4
#define ROAR_SOCKET_TYPE_UDP              5
#define ROAR_SOCKET_TYPE_GENSTR           6 /* generic stream: TCP or UNIX */
#define ROAR_SOCKET_TYPE_DECNET           7 /* DECnet */
#define ROAR_SOCKET_TYPE_TCP6             8
#define ROAR_SOCKET_TYPE_UDP6             9
#define ROAR_SOCKET_TYPE_INET6            ROAR_SOCKET_TYPE_TCP6
#define ROAR_SOCKET_TYPE_IPXSPX           10
#define ROAR_SOCKET_TYPE_IPX              11
#define ROAR_SOCKET_TYPE_LAT_SERVICE      12
#define ROAR_SOCKET_TYPE_LAT_REVERSE_PORT 13

#define ROAR_SOCKET_TYPE_MAX              13

#endif

//ll
