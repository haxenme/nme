//muconthacks.h:

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

#ifndef _ROARAUDIO_MUCONTHACKS_H_
#define _ROARAUDIO_MUCONTHACKS_H_

#ifdef ROAR_TARGET_MICROCONTROLLER

#define SHUT_RD   0
#define SHUT_WR   1
#define SHUT_RDWR 2

#define SOCK_STREAM     1
#define SOCK_DGRAM      2
#define SOCK_RAW        3
#define SOCK_RDM        4
#define SOCK_SEQPACKET  5

#define O_RDONLY       0x01
#define O_WRONLY       0x02
#define O_RDWR         (O_RDONLY|O_WRONLY)
#define O_NONBLOCK     0x04
#define O_CREAT        0x08
#define O_TRUNC        0x10

#define EAGAIN         11
#define ENOSYS         38

struct sockaddr {
 sa_family_t sa_family;
};

int    bind    (int sockfd, const struct sockaddr *my_addr,   socklen_t addrlen);
int    connect (int sockfd, const struct sockaddr *serv_addr, socklen_t addrlen);
char * strerror(int errnum);

// some dummy funcs:
#define getpid()    2
#define getuid()    0
#define getgid()    0
#define getenv(x)   NULL

#endif

#endif

//ll
