//basic.h:

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

#ifndef _LIBROARBASIC_H_
#define _LIBROARBASIC_H_

#include "libroar.h"

#define LIBROAR_BUFFER_SMALL   80
#define LIBROAR_BUFFER_MSGDATA LIBROAR_BUFFER_SMALL
#define _ROAR_MESSAGE_VERSION 0

#if ROAR_MAX_CHANNELS > (LIBROAR_BUFFER_SMALL - 10)
#error ROAR_MAX_CHANNELS too large change ROAR_MAX_CHANNELS or LIBROAR_BUFFER_SMALL
#endif

#define ROAR_CON_FLAGS_NONE        0x00000000UL
#define ROAR_CON_FLAGS_FH          0x00000001UL /* obsoleted */
#define ROAR_CON_FLAGS_VIO         0x00000002UL /* mandatory */
#define ROAR_CON_FLAGS_ISCLIENT    0x00000004UL
#define ROAR_CON_FLAGS_SUPPORT_V2  0x00000008UL /* mandatory if con.version == 2 */
#define ROAR_CON_FLAGS_SUPPORT_EF  0x00000010UL /* Both peers support error frames */
#define ROAR_CON_FLAGS_FREESELF    0x00000020UL /* Free the connection object */
#define ROAR_CON_FLAGS_TERMINATE   0x00000040UL /* Send TERMINATE before QUIT */

struct roar_message {
 int cmd;
 unsigned int stream;
 uint32_t pos;
 size_t datalen;
 char data[LIBROAR_BUFFER_MSGDATA];
 int16_t seq;
 int32_t flags;
 int32_t crc;
 int version;
 uint64_t pos64;
};

struct roar_stds; // "caps.h" will be included later.

struct roar_connection {
 size_t refc;
 uint32_t flags;
 int version;
 struct roar_vio_calls * viocon;
 struct roar_vio_calls   viocon_store;
 struct roar_error_frame errorframe;
 void * cb_userdata;
 void (*cb)(struct roar_connection * con, struct roar_message * mes, void * data, void * userdata);
 struct roar_stds * server_stds;
 char * server_name;
};


int roar_connect      (struct roar_connection * con, const char * server, int flags, uint_least32_t timeout);
int roar_connect_none (struct roar_connection * con);
int roar_connect_vio  (struct roar_connection * con, struct roar_vio_calls * vio);
int roar_connect_fh   (struct roar_connection * con, int fh);
int roar_get_connection_fh  (struct roar_connection * con);
struct roar_vio_calls * roar_get_connection_vio2 (struct roar_connection * con);
const char * roar_get_connection_server(struct roar_connection * con);
int roar_connectionref(struct roar_connection * con);
int roar_connectionunref(struct roar_connection * con);
#define roar_disconnect(x) roar_connectionunref((x))

int roar_set_connection_callback(struct roar_connection * con,
                                 void (*cb)(struct roar_connection * con,
                                            struct roar_message    * mes,
                                            void                   * data,
                                            void                   * userdata),
                                 void * userdata);

int roar_set_connection_version(struct roar_connection * con, int version);

int16_t roar_message_genseq(struct roar_connection * con, int is_client);

int roar_sync         (struct roar_connection * con);
int roar_wait_msg     (struct roar_connection * con, int16_t seq, int16_t seqmask);

int roar_noop         (struct roar_connection * con);

int roar_identify     (struct roar_connection * con, const char * name);

int roar_send_message (struct roar_connection * con, struct roar_message * mes, char *  data);
int roar_recv_message (struct roar_connection * con, struct roar_message * mes, char ** data);
int roar_req          (struct roar_connection * con, struct roar_message * mes, char ** data);
int roar_recv_message2 (struct roar_connection * con, struct roar_message * mes, char ** data,
                        struct roar_error_frame * errorframe);
int roar_req2          (struct roar_connection * con, struct roar_message * mes, char ** data,
                        struct roar_error_frame * errorframe);
#define roar_req3(con,mes,data) roar_req2((con), (mes), (data), roar_err_errorframe())

int roar_vsend_message(struct roar_vio_calls  * vio, struct roar_message * mes, char *  data);
int roar_vrecv_message(struct roar_vio_calls  * vio, struct roar_message * mes, char ** data);
int roar_vreq         (struct roar_vio_calls  * vio, struct roar_message * mes, char ** data);
int roar_vrecv_message2(struct roar_vio_calls  * vio, struct roar_message * mes, char ** data,
                        struct roar_error_frame * errorframe);
int roar_vreq2         (struct roar_vio_calls  * vio, struct roar_message * mes, char ** data,
                        struct roar_error_frame * errorframe);
#endif

//ll
