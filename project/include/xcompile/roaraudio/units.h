//units.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2010-2013
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

#ifndef _ROARAUDIO_UNITS_H_
#define _ROARAUDIO_UNITS_H_

/* suffix: */
#define _MICRO  (1/1000000)
#define _MILI   (1/1000)
#define _ONE    1
#define _KILO   1000
#define _MEGA   ((int_least32_t)_KILO*(int_least32_t)_KILO)
#define _GIGA   ((int_least32_t)_KILO*_MEGA)
#define _TERA   ((int_least32_t)_KILO*_GIGA)


/* Time: */
#ifndef _SEC
#if defined(_UNITS_T_BASE_MSEC)
#define _SEC_TYPE int_least32_t
#define _SEC  (_SEC_TYPE)1000
#elif defined(_UNITS_T_BASE_USEC)
#define _SEC_TYPE int_least32_t
#define _SEC  (_SEC_TYPE)1000000
//#elif defined(_UNITS_T_BASE_SEC)
#else
#define _SEC  1
#define _SEC_TYPE int
#endif
#endif

#ifndef _SEC_TYPE
#define _SEC_TYPE int_least32_t
#endif

#define _MIN  ((_SEC_TYPE)60*_SEC)
#define _HOUR ((_SEC_TYPE)60*_MIN)

#define _MSEC (_SEC*_MILI)
#define _USEC (_SEC*_MICRO)


/* distance */
#ifndef _METER
#if defined(_UNITS_D_BASE_MMETER)
#define _METER_TYPE int
#define _METER 1000
#elif defined(_UNITS_D_BASE_UMETER)
#define _METER_TYPE int_least32_t
#define _METER (_METER_TYPE)1000000
//#elif defined(_UNITS_D_BASE_METER)
#else
#define _METER_TYPE int
#define _METER 1
#endif
#endif

#ifndef _METER_TYPE
#define _METER_TYPE int_least32_t
#endif

#define _AE    ((int_least64_t)149597870691LL     *_METER)
#define _LJ    (9460730472580800LL *_METER)
#define _PC    (30856804413117847LL*_METER) /* TODO: FIXME: get a more corret value */


/* speed */
#define _MPS                   ((double)_METER/_SEC)
#define _KMPH                  (_KILO*_METER/_HOUR)
#define _SPEED_OF_SOUND_AIR    (343. *_MPS)
#define _SPEED_OF_SOUND_WATER  (1407.*_MPS)
#define _SPEED_OF_SOUND        _SPEED_OF_SOUND_AIR
#define _SPEED_OF_LIGHT_VACUUM (299792458LL*_MPS)
#define _SPEED_OF_LIGHT        _SPEED_OF_LIGHT_VACUUM


/* Bits -> Bytes: */
#define _BIT2BYTE(x) (((int)((x)/8)) + ((x) % 8 ? 1 : 0))
#define _BYTE2BIT(x) ((x)*8)

#define _8BIT  _BIT2BYTE(8)
#define _16BIT _BIT2BYTE(16)
#define _24BIT _BIT2BYTE(24)
#define _32BIT _BIT2BYTE(32)
#define _64BIT _BIT2BYTE(64)


#endif

//ll
