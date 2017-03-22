//caps.h:

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

#ifndef _ROARAUDIO_CAPS_H_
#define _ROARAUDIO_CAPS_H_

// cap flags:
#define ROAR_CF_REQUEST          0x0001

// cap types:
#define ROAR_CT_CAPS             0
#define ROAR_CT_STANDARDS        1

// standard vendors:
#define ROAR_STDV_ROARAUDIO      ((uint32_t)0)
#define ROAR_STDV_PROTO          ((uint32_t)1)
#define ROAR_STDV_RFC            ((uint32_t)2)

// data macros for standards:
#define ROAR_STD_MASK_VENDOR     ((uint32_t)0xFF000000)
#define ROAR_STD_MASK_STD        ((uint32_t)0x00FFFF00)
#define ROAR_STD_MASK_VERSION    ((uint32_t)0x000000FF)

#define ROAR_STD_MAKE(vendor,standard,version) ((((uint32_t)(vendor)   & 0x00FF) << 24) | \
                                                (((uint32_t)(standard) & 0xFFFF) <<  8) | \
                                                 ((uint32_t)(version)  & 0x00FF)        )

#define ROAR_STD_MAKE_RFC(rfc) ROAR_STD_MAKE(ROAR_STDV_RFC, (rfc), 0)

#define ROAR_STD_VENDOR(x)  (((x) & ROAR_STD_MASK_VENDOR) >> 24)
#define ROAR_STD_STD(x)     (((x) & ROAR_STD_MASK_STD)    >>  8)
#define ROAR_STD_VERSION(x) ( (x) & ROAR_STD_MASK_VERSION      )

#endif

//ll
