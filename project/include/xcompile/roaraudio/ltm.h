//ltm.h:

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

#ifndef _ROARAUDIO_LTM_H_
#define _ROARAUDIO_LTM_H_

// monitoring targets:
/* Vars used below:
 * t = time
 * w = window size
 * l = history size
 * S(t) = signal at time t
 * H{g}(n) = history of type g element n
 */
#define ROAR_LTM_MT_NONE        0x0000 /* const for init of lists */
#define ROAR_LTM_MT_INACT       0x0001 /* input activit */
#define ROAR_LTM_MT_OUTACT      0x0002 /* output activity */
#define ROAR_LTM_MT_ACT         0x0004 /* any (in+out+other) activity */
#define ROAR_LTM_MT_AVG         0x0008 /* signal avg: SUM{t-w->t}(S(t))/w */
#define ROAR_LTM_MT_PEAK        0x0010 /* signal min and max values: MIN(S(t-w..t)), MAX(S(t-w..t)) */
#define ROAR_LTM_MT_RMS         0x0020 /* signal RMS^2: SUM{t-w->t}(S(t)^2) */
#define ROAR_LTM_MT_RMSPEAK     0x0040 /* signal RMS^2 min and max: MIN(H{RMS}(0..l)), MAX(H{RMS}(0..l)) */
#define ROAR_LTM_MT_HISTORY     0x0080 /* request to hold a history */

#define ROAR_LTM_MTBITS         16     /* number of bits for MTs */

// pre-defined windows:
#define ROAR_LTM_WIN_WORKBLOCK  0      /* The last block which the server worked on */
                                       /* This block does not have any sub-block historys (H()) */

// command sub-sub-types:
#define ROAR_LTM_SST_NOOP       0
#define ROAR_LTM_SST_REGISTER   1
#define ROAR_LTM_SST_UNREGISTER 2
#define ROAR_LTM_SST_GET_RAW    3

#endif

//ll
