//stream.h:

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

#ifndef _ROARAUDIO_STREAM_H_
#define _ROARAUDIO_STREAM_H_

#define ROAR_DIR_DEFAULT ROAR_DIR_PLAY

#define ROAR_DIR_PLAY        1
#define ROAR_DIR_RECORD      2
#define ROAR_DIR_MONITOR     3
#define ROAR_DIR_FILTER      4

#define ROAR_DIR_OUTPUT      5

#define ROAR_DIR_MIXING      6
//#define ROAR_DIR_INTERNAL 7

#define ROAR_DIR_META        8
#define ROAR_DIR_BIDIR       9

#define ROAR_DIR_THRU       10

#define ROAR_DIR_BRIDGE     11

// MIDI:
#define ROAR_DIR_MIDI_IN    12
#define ROAR_DIR_MIDI_OUT   13

// Light Control:
#define ROAR_DIR_LIGHT_IN   14
#define ROAR_DIR_LIGHT_OUT  15

// Raw Data:
#define ROAR_DIR_RAW_IN     16
#define ROAR_DIR_RAW_OUT    17

// Complex (multi-content container):
#define ROAR_DIR_COMPLEX_IN  18
#define ROAR_DIR_COMPLEX_OUT 19

// Radio Data and Transmitter Control System:
#define ROAR_DIR_RDTCS_IN    20
#define ROAR_DIR_RDTCS_OUT   21

// RECORD+PLAY:
#define ROAR_DIR_RECPLAY     22

// Max DIR +1:
#define ROAR_DIR_DIRIDS      23

// Stream flags:
#define ROAR_FLAG_NONE           0x0000
#define ROAR_FLAG_PRIMARY        0x0001
#define ROAR_FLAG_OUTPUT         0x0002
#define ROAR_FLAG_DRIVER         ROAR_FLAG_OUTPUT
#define ROAR_FLAG_SOURCE         0x0004
#define ROAR_FLAG_SYNC           0x0008
#define ROAR_FLAG_META           0x0010
#define ROAR_FLAG_AUTOCONF       0x0020
#define ROAR_FLAG_CLEANMETA      0x0040
#define ROAR_FLAG_HWMIXER        0x0080
#define ROAR_FLAG_PAUSE          0x0100
#define ROAR_FLAG_MUTE           0x0200
#define ROAR_FLAG_MMAP           0x0400
#define ROAR_FLAG_ANTIECHO       0x0800
#define ROAR_FLAG_VIRTUAL        0x1000
#define ROAR_FLAG_RECSOURCE      0x2000
#define ROAR_FLAG_PASSMIXER      0x4000
#define ROAR_FLAG_PRETHRU        0x8000
// next are the exteded flags (> 16 bits)
//#define ROAR_FLAG_SYNC           0x08
#define ROAR_FLAG_IMMUTABLE      0x00010000
#define ROAR_FLAG_ENHANCE        0x00020000
#define ROAR_FLAG_SINGLESINK     0x00040000

#define ROAR_SET_FLAG            0
#define ROAR_RESET_FLAG          1
#define ROAR_TOGGLE_FLAG         2
#define ROAR_NOOP_FLAG           3
#define ROAR_PROTECT_FLAG        0x8000
#define ROAR_SET_FLAG_PROTECT    (ROAR_SET_FLAG|ROAR_PROTECT_FLAG)
#define ROAR_RESET_FLAG_PROTECT  (ROAR_RESET_FLAG|ROAR_PROTECT_FLAG)

// Stream states:
#define ROAR_STREAMSTATE_UNKNOWN   -1
#define ROAR_STREAMSTATE_NULL       0
#define ROAR_STREAMSTATE_UNUSED     ROAR_STREAMSTATE_NULL
#define ROAR_STREAMSTATE_INITING    1
#define ROAR_STREAMSTATE_NEW        2
#define ROAR_STREAMSTATE_OLD        3
#define ROAR_STREAMSTATE_CLOSING    4

// Stream roles:
// PA currently defines: video, music, game, event, phone, animation, production, a11y
// RA includes         : YES    YES    YES   YES    YES    NO         NO          NO

#define ROAR_ROLE_UNKNOWN          -1
#define ROAR_ROLE_NONE              0
#define ROAR_ROLE_MUSIC             1
#define ROAR_ROLE_VIDEO             2
#define ROAR_ROLE_GAME              3
#define ROAR_ROLE_EVENT             4
#define ROAR_ROLE_BEEP              5
#define ROAR_ROLE_PHONE             6
#define ROAR_ROLE_BACKGROUND_MUSIC  7
#define ROAR_ROLE_VOICE             8
#define ROAR_ROLE_INSTRUMENT        9
#define ROAR_ROLE_RHYTHM           10
#define ROAR_ROLE_CLICK            11
#define ROAR_ROLE_MIXED            12


#define ROAR_CARE_NOPOS  0
#define ROAR_CARE_POS    1

#define ROAR_STREAM(a) ((struct roar_stream*)(a))

#define ROAR_STREAMS_MAX  64


struct roar_stream {
 int id;

 int fh;
 int dir;
 int care_pos;

 uint32_t pos;
 uint32_t pos_rel_id; // TODO: why is this not int?

 struct roar_audio_info info;
};

#endif

//ll
