//proto_gopher.h:

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

#ifndef _ROARAUDIO_PROTO_GOPHER_H_
#define _ROARAUDIO_PROTO_GOPHER_H_

#define ROAR_GOPHER_FLAGS_NONE       0x0000
#define ROAR_GOPHER_FLAGS_PLUS       0x0001

// offical:
#define ROAR_GOPHER_TYPE_FILE        '0'
#define ROAR_GOPHER_TYPE_DIR         '1'
#define ROAR_GOPHER_TYPE_CSO_PB      '2' /* Item is a CSO phone-book server */
#define ROAR_GOPHER_TYPE_ERROR       '3'
#define ROAR_GOPHER_TYPE_BINHEXED    '4' /* Item is a BinHexed Macintosh file. */
#define ROAR_GOPHER_TYPE_DOSBIN      '5' /* Item is DOS binary archive of some sort. */
#define ROAR_GOPHER_TYPE_UUENCODED   '6' /* Item is a UNIX uuencoded file. */
#define ROAR_GOPHER_TYPE_SEARCH      '7' /* Item is an Index-Search server. */
#define ROAR_GOPHER_TYPE_TELNET      '8'
#define ROAR_GOPHER_TYPE_BIN         '9' /* Item is a binary file! */
#define ROAR_GOPHER_TYPE_REDUNDANT   '+' /* Item is a redundant server */
#define ROAR_GOPHER_TYPE_TN3270      'T' /* Item points to a text-based tn3270 session. */
#define ROAR_GOPHER_TYPE_GIF         'g' /* Item is a GIF format graphics file. */
#define ROAR_GOPHER_TYPE_IMAGE       'I' /* Item is some kind of image file.  Client decides how to display. */
#define ROAR_GOPHER_TYPE_INFO        'i' /* text in menus */

// inoffical:
#define ROAR_GOPHER_TYPE_SOUND       's'
#define ROAR_GOPHER_TYPE_MOVIE       ';'
#define ROAR_GOPHER_TYPE_MIME        'M'
#define ROAR_GOPHER_TYPE_HTML        'h'

struct roar_gopher_menu_item {
 int flags;
 char type;
 const char * name;
 const char * selector;
 const char * host;
 unsigned int port;
};

struct roar_gopher_menu {
 int flags;
 struct roar_gopher_menu_item * items;
 size_t items_len;
};

#endif

//ll
