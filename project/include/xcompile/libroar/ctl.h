//ctl.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2008-2013
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

#ifndef _LIBROARCTL_H_
#define _LIBROARCTL_H_

#include "libroar.h"

#define _LIBROAR_CTL_STDATTRS _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL

int roar_get_clientid  (struct roar_connection * con) _LIBROAR_CTL_STDATTRS;

int roar_get_standby   (struct roar_connection * con) _LIBROAR_CTL_STDATTRS;
int roar_set_standby   (struct roar_connection * con, int state) _LIBROAR_CTL_STDATTRS;

int roar_terminate      (struct roar_connection * con, int terminate) _LIBROAR_CTL_STDATTRS;
int roar_server_oinfo   (struct roar_connection * con, struct roar_stream * s, int dir) _LIBROAR_CTL_STDATTRS;


int roar_list         (struct roar_connection * con, int * items,   int max, int cmd) _LIBROAR_CTL_STDATTRS;
int roar_list_filtered(struct roar_connection * con, int * items,   int max, int cmd, unsigned char filter, unsigned char cmp, uint32_t id) _LIBROAR_CTL_STDATTRS;

/*
int roar_list_clients (struct roar_connection * con, int * clients, int max);
int roar_list_streams (struct roar_connection * con, int * streams, int max);
*/
#define roar_list_clients(c,i,m) roar_list((c),(i),(m),ROAR_CMD_LIST_CLIENTS)
#define roar_list_streams(c,i,m) roar_list((c),(i),(m),ROAR_CMD_LIST_STREAMS)

int roar_get_client   (struct roar_connection * con, struct roar_client * client, int id) _LIBROAR_CTL_STDATTRS;
int roar_get_stream   (struct roar_connection * con, struct roar_stream * stream, int id) _LIBROAR_CTL_STDATTRS;

int roar_kick         (struct roar_connection * con, int type, int id) _LIBROAR_ATTR_NONNULL_ALL;

int roar_set_vol      (struct roar_connection * con, int id, struct roar_mixer_settings * mixer, int   channels, int mode) _LIBROAR_CTL_STDATTRS;
int roar_get_vol      (struct roar_connection * con, int id, struct roar_mixer_settings * mixer, int * channels) _LIBROAR_CTL_STDATTRS;

// filter...
int roar_ctl_f2m      (struct roar_message * m, unsigned char   filter, unsigned char   cmp, uint32_t   id);
int roar_ctl_m2f      (struct roar_message * m, unsigned char * filter, unsigned char * cmp, uint32_t * id);
#define roar_ctl_f2m_any(m) roar_ctl_f2m((m), ROAR_CTL_FILTER_ANY, ROAR_CTL_FILTER_ANY, ROAR_CTL_FILTER_ANY)

int roar_filter_match (const unsigned cmp, const uint32_t a, const uint32_t b) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;

// int array
int roar_ctl_ia2m     (struct roar_message * m, int * data, size_t len);
int roar_ctl_m2ia     (struct roar_message * m, int * data, size_t len);

// client
int roar_ctl_c2m      (struct roar_message * m, struct roar_client * c);
int roar_ctl_m2c      (struct roar_message * m, struct roar_client * c);
int roar_ctl_c2m2     (struct roar_message * m, struct roar_client * c, void ** data);
int roar_ctl_m2c2     (struct roar_message * m, struct roar_client * c, void  * data);

int    roar_str2proto (const char * proto) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;
const char * roar_proto2str (const int    proto) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;

int    roar_str2byteorder (const char * byteorder) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;
const char * roar_byteorder2str (const int    byteorder) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;

int    roar_str2ot        (const char * ot) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;
const char * roar_ot2str  (const int    ot) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;

int roar_conv_volume (struct roar_mixer_settings * dst, struct roar_mixer_settings * src, int dstchans, int srcchans) _LIBROAR_CTL_STDATTRS;

#endif

//ll
