//roarfeatures.h:

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

#ifndef _LIBROARFEATURES_H_
#define _LIBROARFEATURES_H_

#include "libroar.h"

// libroar1 features:
#define ROAR_FT_FUNC_SET_FLAGS2
#define ROAR_FT_FUNC_LIST_FILTERED
#define ROAR_FT_FUNC_WAIT
#define ROAR_FT_FUNC_VS_CTL
#define ROAR_FT_FUNC_SET_VOL2
#define ROAR_FT_FUNC_CONNECT2
#define ROAR_FT_FUNC_SIMPLE_CONNECT2
#define ROAR_FT_FUNC_PANIC
#define ROAR_FT_FUNC_RESET
#define ROAR_FT_FUNC_CLOCK_GETTIME
#define ROAR_FT_FUNC_BUFFER_MOVEINTOQUEUE
#define ROAR_FT_FUNC_CTL_C2M2
#define ROAR_FT_FUNC_CTL_M2C2
#define ROAR_FT_FUNC_GET_PATH
#define ROAR_FT_FUNC_MM_STRDUP2
#define ROAR_FT_FEATURE_VS
#define ROAR_FT_FEATURE_VS_FILE
#define ROAR_FT_FEATURE_VS_BUFFERED
#define ROAR_FT_FEATURE_CRC24
#define ROAR_FT_FEATURE_HASH_TIGER
#define ROAR_FT_FEATURE_CAPS_STANDARDS
#define ROAR_FT_FEATURE_SERVER_INFO_IT_SERVER
#define ROAR_FT_FEATURE_HASH_API
#define ROAR_FT_FEATURE_RANDOM_NONCE
#define ROAR_FT_FEATURE_UUID         /* see #230 */
#define ROAR_FT_FEATURE_COMMON_PROTO /* see #257 */
#define ROAR_FT_FEATURE_SELECTOR_HANDLING /* see #285 */
#define ROAR_FT_FEATURE_WATCHDOG /* see #291 */

// libroar2 features:
#define ROAR_FT_SONAME_LIBROAR2

#endif

//ll
