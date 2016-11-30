//vio_cmd.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2009-2013
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

#ifndef _LIBROARVIO_CMD_H_
#define _LIBROARVIO_CMD_H_

#include "libroar.h"

#define ROAR_VIO_CMD_OPTS_NONE      0x00
#define ROAR_VIO_CMD_OPTS_NONBLOCK  0x01
#define ROAR_VIO_CMD_OPTS_ON_DEMAND 0x02

#define ROAR_VIO_CMD_BUFSIZE        1024

#define ROAR_VIO_CMD_STATE_NONE     0
#define ROAR_VIO_CMD_STATE_OPEN     1
#define ROAR_VIO_CMD_STATE_CLOSING  2
#define ROAR_VIO_CMD_STATE_CLOSED   3


// for OpenPGP interface:
#define ROAR_VIO_PGP_OPTS_NONE      0x00
#define ROAR_VIO_PGP_OPTS_ASCII     0x01
#define ROAR_VIO_PGP_OPTS_SIGN      0x02
#define ROAR_VIO_PGP_OPTS_TEXTMODE  0x04


struct roar_vio_cmd_child {
 int opened;
 pid_t pid;
 int in;
 int out;
 char * cmd;
};

struct roar_vio_cmd_state {
 struct roar_vio_calls * next;
 int options;

 int state;

 struct roar_vio_cmd_child reader;
 struct roar_vio_cmd_child writer;
};

struct roar_vio_2popen_state {
 int options;
 int state;

 struct roar_vio_cmd_child child;
};

int roar_vio_open_cmd(struct roar_vio_calls * calls, struct roar_vio_calls * dst,
                      char * reader, char * writer, int options);
int roar_vio_cmd_close(struct roar_vio_calls * vio);
int roar_vio_cmd_fork(struct roar_vio_cmd_child * child);
int roar_vio_cmd_wait(struct roar_vio_cmd_child * child);

int roar_vio_open_2popen(struct roar_vio_calls * calls, char * command, int options);
int roar_vio_2popen_close(struct roar_vio_calls * vio);
// possible VIOs:

// cmd:
ssize_t roar_vio_cmd_read    (struct roar_vio_calls * vio, void *buf, size_t count);
ssize_t roar_vio_cmd_write   (struct roar_vio_calls * vio, void *buf, size_t count);
int     roar_vio_cmd_sync    (struct roar_vio_calls * vio);
int     roar_vio_cmd_ctl     (struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data);

// MISC:
int roar_vio_open_gzip(struct roar_vio_calls * calls, struct roar_vio_calls * dst, int level);

int roar_vio_open_gpg(struct roar_vio_calls * calls, struct roar_vio_calls * dst, char * pw, int wronly, char * opts, int options);
int roar_vio_open_pgp_decrypt(struct roar_vio_calls * calls, struct roar_vio_calls * dst, char * pw);
int roar_vio_open_pgp_store(struct roar_vio_calls * calls, struct roar_vio_calls * dst, int options);
int roar_vio_open_pgp_encrypt_sym(struct roar_vio_calls * calls, struct roar_vio_calls * dst, char * pw, int options);
int roar_vio_open_pgp_encrypt_pub(struct roar_vio_calls * calls, struct roar_vio_calls * dst, char * pw, int options, char * recipient);

#endif

//ll
