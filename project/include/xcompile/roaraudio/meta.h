//meta.h:

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

#ifndef _ROARAUDIO_META_H_
#define _ROARAUDIO_META_H_

#define ROAR_META_TYPE_NONE           0
#define ROAR_META_TYPE_TITLE          1
#define ROAR_META_TYPE_ALBUM          2
#define ROAR_META_TYPE_AUTHOR         3
#define ROAR_META_TYPE_AUTOR          ROAR_META_TYPE_AUTHOR
#define ROAR_META_TYPE_ARTIST         ROAR_META_TYPE_AUTHOR
#define ROAR_META_TYPE_VERSION        4
#define ROAR_META_TYPE_DATE           5
#define ROAR_META_TYPE_LICENSE        6
#define ROAR_META_TYPE_TRACKNUMBER    7
#define ROAR_META_TYPE_ORGANIZATION   8
#define ROAR_META_TYPE_DESCRIPTION    9
#define ROAR_META_TYPE_GENRE          10
#define ROAR_META_TYPE_LOCATION       11
#define ROAR_META_TYPE_CONTACT        12
#define ROAR_META_TYPE_STREAMURL      13
#define ROAR_META_TYPE_HOMEPAGE       14
#define ROAR_META_TYPE_THUMBNAIL      15
#define ROAR_META_TYPE_LENGTH         16
#define ROAR_META_TYPE_COMMENT        17
#define ROAR_META_TYPE_OTHER          18
#define ROAR_META_TYPE_FILENAME       19
#define ROAR_META_TYPE_FILEURL        20
#define ROAR_META_TYPE_SERVER         21
#define ROAR_META_TYPE_DURATION       22
#define ROAR_META_TYPE_WWW            ROAR_META_TYPE_HOMEPAGE
#define ROAR_META_TYPE_WOAF           23 /* ID3: Official audio file webpage */
#define ROAR_META_TYPE_ENCODER        24
#define ROAR_META_TYPE_ENCODEDBY      ROAR_META_TYPE_ENCODER
#define ROAR_META_TYPE_YEAR           25
#define ROAR_META_TYPE_DISCID         26
#define ROAR_META_TYPE_RPG_TRACK_PEAK 27
#define ROAR_META_TYPE_RPG_TRACK_GAIN 28
#define ROAR_META_TYPE_RPG_ALBUM_PEAK 29
#define ROAR_META_TYPE_RPG_ALBUM_GAIN 30
#define ROAR_META_TYPE_HASH           31
#define ROAR_META_TYPE_SIGNALINFO     32
#define ROAR_META_TYPE_AUDIOINFO      ROAR_META_TYPE_SIGNALINFO
#define ROAR_META_TYPE_OFFSET         33
#define ROAR_META_TYPE_PERFORMER      34
#define ROAR_META_TYPE_COPYRIGHT      35
#define ROAR_META_TYPE_LIKENESS       36
#define ROAR_META_TYPE_COMPOSER       37
#define ROAR_META_TYPE_RIGHTS         38
#define ROAR_META_TYPE_ISRC           39
#define ROAR_META_TYPE_LANGUAGE       40
#define ROAR_META_TYPE_GTIN           41
#define ROAR_META_TYPE_ISBN           ROAR_META_TYPE_GTIN
#define ROAR_META_TYPE_EAN            ROAR_META_TYPE_GTIN
#define ROAR_META_TYPE_PUBLISHER      42
#define ROAR_META_TYPE_DISCNUMBER     43
#define ROAR_META_TYPE_SOURCEMEDIA    44
#define ROAR_META_TYPE_LABEL          45
#define ROAR_META_TYPE_LABELNO        46


#define ROAR_META_MODE_SET           0
#define ROAR_META_MODE_ADD           1
#define ROAR_META_MODE_DELETE        2
#define ROAR_META_MODE_CLEAR         3
#define ROAR_META_MODE_FINALIZE      4

#define ROAR_META_MAX_NAMELEN 32

#define ROAR_META_MAX_PER_STREAM 16

struct roar_meta {
 int    type;
 char   key[ROAR_META_MAX_NAMELEN];
 char * value;
};

#endif

//ll
