//client.h:

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

#ifndef _ROARAUDIO_CLIENT_H_
#define _ROARAUDIO_CLIENT_H_

#define ROAR_BUFFER_NAME 80

#define ROAR_CLIENTS_MAX 64
#define ROAR_CLIENTS_MAX_STREAMS_PER_CLIENT 12

#define ROAR_PROTO_NONE             0
#define ROAR_PROTO_ROARAUDIO        1
#define ROAR_PROTO_ESOUND           2
#define ROAR_PROTO_AUTO             3 /* auto detect */
#define ROAR_PROTO_HTTP             4
#define ROAR_PROTO_GOPHER           5
#define ROAR_PROTO_ICY              7 /* Nullsoft ICY */
#define ROAR_PROTO_SIMPLE           8 /* PulseAudio Simple */
#define ROAR_PROTO_RSOUND           9
#define ROAR_PROTO_RPLAY           10
#define ROAR_PROTO_IRC             11 /* ID just for fun */
#define ROAR_PROTO_DCC             12
#define ROAR_PROTO_ECHO            13 /* for testing and stuff */
#define ROAR_PROTO_DISCARD         14 /* RFC 863 */
#define ROAR_PROTO_WHOIS           15
#define ROAR_PROTO_FINGER          16
#define ROAR_PROTO_QUOTE           17 /* RFC 865: Quote of the Day Protocol */
#define ROAR_PROTO_DAYTIME         18
#define ROAR_PROTO_GAME            19 /* a game, may be any game */
#define ROAR_PROTO_TELNET          20
#define ROAR_PROTO_DHCP            21
#define ROAR_PROTO_SSH             22
#define ROAR_PROTO_TIME            23 /* Time protocol, RFC 868 */
#define ROAR_PROTO_RLOGIN          24
#define ROAR_PROTO_RPLD            25 /* RoarAudio Playlist Daemon Protocol */
#define ROAR_PROTO_MPD             26 /* Music Player Daemon */

#define ROAR_BYTEORDER_UNKNOWN      0x00
#define ROAR_BYTEORDER_LE           ROAR_CODEC_LE
#define ROAR_BYTEORDER_BE           ROAR_CODEC_BE
#define ROAR_BYTEORDER_PDP          ROAR_CODEC_PDP
#define ROAR_BYTEORDER_NETWORK      ROAR_BYTEORDER_BE

#if BYTE_ORDER == BIG_ENDIAN
#define ROAR_BYTEORDER_NATIVE       ROAR_CODEC_BE
#elif BYTE_ORDER == LITTLE_ENDIAN
#define ROAR_BYTEORDER_NATIVE       ROAR_CODEC_LE
#else
#define ROAR_BYTEORDER_NATIVE       ROAR_CODEC_PDP
#endif

#define ROAR_CLIENTPASS_FLAG_NONE    0x0000
#define ROAR_CLIENTPASS_FLAG_LISTEN  0x0001

#endif

//ll
