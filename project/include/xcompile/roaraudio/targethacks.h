//targethacks.h:

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

#ifndef _ROARAUDIO_TARGETHACKS_H_
#define _ROARAUDIO_TARGETHACKS_H_

#ifndef ROAR_HAVE_T_ID_T
#define id_t      int
#endif

#ifndef ROAR_HAVE_T_PID_T
#define pid_t     int
#endif

#ifndef ROAR_HAVE_T_UID_T
#define uid_t     int
#endif

#ifndef ROAR_HAVE_T_GID_T
#define gid_t     int
#endif

#ifndef ROAR_HAVE_T_SOCKLEN_T
#define socklen_t int
#endif

#ifndef ROAR_HAVE_T_MODE_T
#define mode_t    unsigned int
#endif

#ifndef ROAR_HAVE_T_OFF_T
#define off_t     int
#endif

/*
#define size_t    unsigned int
*/
#ifndef ROAR_HAVE_T_SSIZE_T
#define ssize_t   signed   int
#endif

#ifndef ROAR_HAVE_T_TIME_T
#define time_t    int64_t
#endif

#ifndef ROAR_HAVE_T_SA_FAMILY_T
#define sa_family_t char
#endif

#ifndef ROAR_HAVE_CONST_M_PI_2
#define M_PI_2 1.57079632679 /* pi/2 */
#endif

// funny printf() hacks:
#ifdef ROAR_TARGET_WIN32
#define LIBROAR__longlong long
#define LIBROAR__ll       "l"
#else
#define LIBROAR__longlong long long
#define LIBROAR__ll       "ll"
#endif

#endif

//ll
