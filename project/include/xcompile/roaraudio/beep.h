//beep.h:

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

#ifndef _ROARAUDIO_BEEP_H_
#define _ROARAUDIO_BEEP_H_

#define ROAR_BEEP_MAX_VOL  65535
#define ROAR_BEEP_MAX_TIME 65535 /* ms */
#define ROAR_BEEP_MAX_FREQ 65535 /* Hz */
#define ROAR_BEEP_MAX_POS  32767

#define ROAR_BEEP_DEFAULT_VOL  (ROAR_BEEP_MAX_VOL/4)
#define ROAR_BEEP_DEFAULT_TIME 256 /* ms */
#define ROAR_BEEP_DEFAULT_FREQ 440 /* Hz */
#define ROAR_BEEP_DEFAULT_TYPE ROAR_BEEP_TYPE_DEFAULT

#define ROAR_BEEP_TYPE_DEFAULT            0
#define ROAR_BEEP_TYPE_CBELL              1
#define ROAR_BEEP_TYPE_XBELL              2
#define ROAR_BEEP_TYPE_ERROR              3

#endif

//ll
