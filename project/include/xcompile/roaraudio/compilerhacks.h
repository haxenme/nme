//compilerhacks.h:

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

#ifndef _ROARAUDIO_COMPILERHACKS_H_
#define _ROARAUDIO_COMPILERHACKS_H_

// just informative macros:
#define _LIBROAR_GOOD_CAST
#define _LIBROAR_BAD_CAST

#if defined(__GNUC__) && __GNUC__ >= 4
#define _LIBROAR_ATTR_DEPRECATED        __attribute__((deprecated))
#define _LIBROAR_ATTR_PURE              __attribute__ ((pure))
#define _LIBROAR_ATTR_USE_RESULT        __attribute__ ((warn_unused_result))
#define _LIBROAR_ATTR_PRINTF(str,args)  __attribute__ ((format (printf, str, args)))

// gcc does not only add a warning on NULL argument for the following
// but also asumes they are never NULL (but allows them to be NULL)
// and breaks our check this way.
#if 0
#define _LIBROAR_ATTR_NONNULL(x, index...) __attribute__((nonnull ( x, ##index )))
#define _LIBROAR_ATTR_NONNULL_ALL       __attribute__((nonnull))
#endif
#endif

// add more defintions for other compilers here.



#ifndef _LIBROAR_ATTR_DEPRECATED
#define _LIBROAR_ATTR_DEPRECATED
#endif
#ifndef _LIBROAR_ATTR_NONNULL
#define _LIBROAR_ATTR_NONNULL(index...)
#endif
#ifndef _LIBROAR_ATTR_NONNULL_ALL
#define _LIBROAR_ATTR_NONNULL_ALL
#endif
#ifndef _LIBROAR_ATTR_PURE
#define _LIBROAR_ATTR_PURE
#endif
#ifndef _LIBROAR_ATTR_USE_RESULT
#define _LIBROAR_ATTR_USE_RESULT
#endif
#ifndef _LIBROAR_ATTR_PRINTF
#define _LIBROAR_ATTR_PRINTF(str,args)
#endif

#ifndef _LIBROAR_IGNORE_RET
#define _LIBROAR_IGNORE_RET(x) ((void)((x)+1))
#endif

#ifndef _LIBROAR_NOATTR_TO_STATIC
#define _LIBROAR_ATTR_TO_STATIC _LIBROAR_ATTR_DEPRECATED
#else
#define _LIBROAR_ATTR_TO_STATIC
#endif

#ifdef _LIBROAR_NOATTR_WARNINGS
#undef _LIBROAR_ATTR_DEPRECATED
#define _LIBROAR_ATTR_DEPRECATED
#undef _LIBROAR_ATTR_USE_RESULT
#define _LIBROAR_ATTR_USE_RESULT
#endif

#endif

//ll
