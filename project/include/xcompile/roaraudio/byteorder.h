//byteorder.h:

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

#ifndef _ROARAUDIO_BYTEORDER_H_
#define _ROARAUDIO_BYTEORDER_H_

#define _ROAR_MOVE_BYTE(x,p,n) ( \
                                ((uint_least64_t)( \
                                 ((uint_least64_t)((uint_least64_t)(x) & ((uint_least64_t)0xFFUL << (8*(p))))) >> (8*(p)) \
                                )) << ((n)-8*((p)+1)) \
                               )

#if BYTE_ORDER == BIG_ENDIAN && !defined(ROAR_TARGET_WIN32)

#define ROAR_NET2HOST64(x) (x)
#define ROAR_HOST2NET64(x) (x)
#define ROAR_NET2HOST32(x) (x)
#define ROAR_HOST2NET32(x) (x)
#define ROAR_NET2HOST16(x) (x)
#define ROAR_HOST2NET16(x) (x)

#define ROAR_BE2HOST64(x) (x)
#define ROAR_HOST2BE64(x) (x)
#define ROAR_BE2HOST32(x) (x)
#define ROAR_HOST2BE32(x) (x)
#define ROAR_BE2HOST16(x) (x)
#define ROAR_HOST2BE16(x) (x)

#define ROAR_LE2HOST32(x) ROAR_HOST2LE32(x)
#define ROAR_HOST2LE32(x) (_ROAR_MOVE_BYTE((x), 0, 32) | _ROAR_MOVE_BYTE((x), 1, 32) | \
                           _ROAR_MOVE_BYTE((x), 2, 32) | _ROAR_MOVE_BYTE((x), 3, 32) )
#define ROAR_LE2HOST16(x) ROAR_HOST2LE16(x)
#define ROAR_HOST2LE16(x) (_ROAR_MOVE_BYTE((x), 0, 16) | _ROAR_MOVE_BYTE((x), 1, 16) )

//#elif BYTE_ORDER == LITTLE_ENDIAN
#else
#if BYTE_ORDER == LITTLE_ENDIAN
#define ROAR_NET2HOST64(x) ROAR_HOST2NET64(x)
#define ROAR_HOST2NET64(x) ((uint_least64_t) \
                            (_ROAR_MOVE_BYTE((x), 0, 64) | _ROAR_MOVE_BYTE((x), 1, 64) | \
                             _ROAR_MOVE_BYTE((x), 2, 64) | _ROAR_MOVE_BYTE((x), 3, 64) | \
                             _ROAR_MOVE_BYTE((x), 4, 64) | _ROAR_MOVE_BYTE((x), 5, 64) | \
                             _ROAR_MOVE_BYTE((x), 6, 64) | _ROAR_MOVE_BYTE((x), 7, 64) ) )
#else
/* PDP byte order */
#endif

#define ROAR_NET2HOST32(x) ntohl((x))
#define ROAR_HOST2NET32(x) htonl((x))
#define ROAR_NET2HOST16(x) ntohs((x))
#define ROAR_HOST2NET16(x) htons((x))

#define ROAR_BE2HOST32(x) ntohl(x)
#define ROAR_HOST2BE32(x) htonl(x)
#define ROAR_BE2HOST16(x) ntohs(x)
#define ROAR_HOST2BE16(x) htons(x)

#define ROAR_LE2HOST64(x) (x)
#define ROAR_HOST2LE64(x) (x)
#define ROAR_LE2HOST32(x) (x)
#define ROAR_HOST2LE32(x) (x)
#define ROAR_LE2HOST16(x) (x)
#define ROAR_HOST2LE16(x) (x)

#endif

#endif

//ll
