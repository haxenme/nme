//vio_ctl.h:

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

#ifndef _LIBROARVIO_CTL_H_
#define _LIBROARVIO_CTL_H_

#include "libroar.h"

// CTLs:
/*
 * 0xAAAABBBB
 * AAAA:
 *   0x0001 -> Basic stream calls
 *   0x0002 -> Driver calls
 *
 * BBBB:
 *   0x0XXX -> Client
 *   0x1XXX -> Server
 */

#define ROAR_VIO_CTL_GET                  0x1UL
#define ROAR_VIO_CTL_SET                  0x2UL

#define ROAR_VIO_CTL_CLIENT            0x0000UL
#define ROAR_VIO_CTL_SERVER            0x1000UL

#define ROAR_VIO_CTL_GENERIC     (0x0000UL<<16)
#define ROAR_VIO_CTL_STREAM      (0x0001UL<<16)
#define ROAR_VIO_CTL_DRIVER      (0x0002UL<<16)

// basic calls:
#define ROAR_VIO_CTL_GET_NEXT            (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x0100)
#define ROAR_VIO_CTL_SET_NEXT            (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x0100)
#define ROAR_VIO_CTL_GET_FH              (ROAR_VIO_CTL_GENERIC|0x0110)
#define ROAR_VIO_CTL_GET_READ_FH         (ROAR_VIO_CTL_GENERIC|0x0111)
#define ROAR_VIO_CTL_GET_WRITE_FH        (ROAR_VIO_CTL_GENERIC|0x0112)
#define ROAR_VIO_CTL_GET_SELECT_FH       (ROAR_VIO_CTL_GENERIC|0x0113)
#define ROAR_VIO_CTL_GET_SELECT_READ_FH  (ROAR_VIO_CTL_GENERIC|0x0114)
#define ROAR_VIO_CTL_GET_SELECT_WRITE_FH (ROAR_VIO_CTL_GENERIC|0x0115)
#define ROAR_VIO_CTL_SELECT              (ROAR_VIO_CTL_GENERIC|0x0120)
#define ROAR_VIO_CTL_GET_UMMAP           (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x0130) /* Use mmap(), int as bool */
#define ROAR_VIO_CTL_SET_UMMAP           (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x0130) /* ** */
#define ROAR_VIO_CTL_GET_SHUTDOWN        (ROAR_VIO_CTL_GENERIC|0x0140) /* shutdown(), need specs */
#define ROAR_VIO_CTL_SET_NOSYNC          (ROAR_VIO_CTL_GENERIC|0x0150) /* delete call of vio sync() from object */
#define ROAR_VIO_CTL_GET_NAME            (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x0160) /* get name of VIO */
#define ROAR_VIO_CTL_ACCEPT              (ROAR_VIO_CTL_GENERIC|0x0170) /* accept(), vio* */
#define ROAR_VIO_CTL_SHUTDOWN            (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x0174) /* shutdown(), int */
#define ROAR_VIO_CTL_SYSIO_IOCTL         (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x0180) /* ioctl(), */
                                                                                        /* struct roar_vio_sysio_ioctl* */
#define ROAR_VIO_CTL_FSTAT               (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x0184) /* fstat() */
#define ROAR_VIO_CTL_GET_SOCKNAME        (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x0188) /* getsockname() */
#define ROAR_VIO_CTL_GET_PEERNAME        (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x018C) /* getpeername() */

// NOTE: The following two blocks have some discontinuity in the used IDs:
// 0x0190 was used by both ROAR_VIO_CTL_[GS]ET_SYSIO_SOCKOPT and ROAR_VIO_CTL_[GS]ET_MIMETYPE.
// we fixed this by changeing IDs for both and add new consts for the conflicting IDs.
// roar_vio_ctl() will print a warning if they are used.
#define ROAR_VIO_CTL_CONFLICTING_ID_0    (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x0190)
#define ROAR_VIO_CTL_CONFLICTING_ID_1    (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x0190)

#define ROAR_VIO_CTL_GET_SYSIO_SOCKOPT   (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x0198) /* getsockopt() */
#define ROAR_VIO_CTL_SET_SYSIO_SOCKOPT   (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x0198) /* setsockopt() */

// more about network based protocols:
#define ROAR_VIO_CTL_GET_MIMETYPE        (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x019C)
#define ROAR_VIO_CTL_SET_MIMETYPE        (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x019C)
#define ROAR_VIO_CTL_GET_USERPASS        (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x0194)
#define ROAR_VIO_CTL_SET_USERPASS        (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x0194)

// Implement roar_vio_nonblock()...
#define ROAR_VIO_CTL_NONBLOCK            (ROAR_VIO_CTL_GENERIC|0x01A0) /* roar_vio_nonblock(), int */

// get or set data format used for read and write calls, see below
#define ROAR_VIO_CTL_GET_DATA_FORMAT   (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_GET|0x0170)
#define ROAR_VIO_CTL_SET_DATA_FORMAT   (ROAR_VIO_CTL_GENERIC|ROAR_VIO_CTL_SET|0x0170)

// stream:
#define ROAR_VIO_CTL_SET_STREAM    (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_CLIENT|ROAR_VIO_CTL_SET) /* normal streams */
#define ROAR_VIO_CTL_GET_STREAM    (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_CLIENT|ROAR_VIO_CTL_GET)
#define ROAR_VIO_CTL_SET_DMXSCHAN  (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_CLIENT|ROAR_VIO_CTL_SET|0x10) /* simple DMX Channel */
#define ROAR_VIO_CTL_GET_DMXSCHAN  (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_CLIENT|ROAR_VIO_CTL_GET|0x10)
#define ROAR_VIO_CTL_SET_DMXUNIV   (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_CLIENT|ROAR_VIO_CTL_SET|0x20) /* DMX Universe */
#define ROAR_VIO_CTL_GET_DMXUNIV   (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_CLIENT|ROAR_VIO_CTL_GET|0x20)

#define ROAR_VIO_CTL_SET_SSTREAM   (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_SERVER|ROAR_VIO_CTL_SET) /* server streams */
#define ROAR_VIO_CTL_GET_SSTREAM   (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_SERVER|ROAR_VIO_CTL_GET)
#define ROAR_VIO_CTL_SET_SSTREAMID (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_SERVER|ROAR_VIO_CTL_SET|0x10) /* server streams */
#define ROAR_VIO_CTL_GET_SSTREAMID (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_SERVER|ROAR_VIO_CTL_GET|0x10)

#define ROAR_VIO_CTL_SET_AUINFO    (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_SET|0x2000) /* set a struct roar_audio_info */
#define ROAR_VIO_CTL_GET_AUINFO    (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_GET|0x2000) /* get a struct roar_audio_info */

#define ROAR_VIO_CTL_GET_DELAY     (ROAR_VIO_CTL_STREAM|ROAR_VIO_CTL_GET|0x010) /* return in bytes as the vio interface */
                                              /* does not know anything about streams */

#define ROAR_VIO_CTL_GET_DBLOCKS   (ROAR_VIO_CTL_DRIVER|0x0001) /* get Driver Blocks */
#define ROAR_VIO_CTL_SET_DBLOCKS   (ROAR_VIO_CTL_DRIVER|0x0002) /* set Driver Blocks */
#define ROAR_VIO_CTL_GET_DBLKSIZE  (ROAR_VIO_CTL_DRIVER|0x0003) /* get Driver Blocks size (in byte) */
#define ROAR_VIO_CTL_SET_DBLKSIZE  (ROAR_VIO_CTL_DRIVER|0x0004) /* set Driver Blocks size (in byte) */
#define ROAR_VIO_CTL_GET_VOLUME    (ROAR_VIO_CTL_DRIVER|ROAR_VIO_CTL_GET|0x10)
#define ROAR_VIO_CTL_SET_VOLUME    (ROAR_VIO_CTL_DRIVER|ROAR_VIO_CTL_SET|0x10)
#define ROAR_VIO_CTL_GET_RECORD    (ROAR_VIO_CTL_DRIVER|ROAR_VIO_CTL_GET|0x20) /* int */
#define ROAR_VIO_CTL_SET_RECORD    (ROAR_VIO_CTL_DRIVER|ROAR_VIO_CTL_SET|0x20) /* int */

// consts for ROAR_VIO_CTL_SHUTDOWN:
#define ROAR_VIO_SHUTDOWN_READ        0x1
#define ROAR_VIO_SHUTDOWN_WRITE       0x2
#define ROAR_VIO_SHUTDOWN_LISTEN      0x4 /* like close() on listen sock but allow padding requests */
                                          /* to be accept()ed                                       */
#define ROAR_VIO_SHUTDOWN_RW       (ROAR_VIO_SHUTDOWN_READ|ROAR_VIO_SHUTDOWN_WRITE)

// Data format used for read/write():

// _D_ata _F_ormat _T_ypes:
// generic types:
#define ROAR_VIO_DFT_UNKNOWN           -1
#define ROAR_VIO_DFT_NULL          0x0000
#define ROAR_VIO_DFT_RAW           0x0001 /* raw bytes, default */
#define ROAR_VIO_DFT_PACKET        0x0002 /* a packet of some kind including headers */
#define ROAR_VIO_DFT_UNFRAMED      0x0003 /* a packet of some kind excluding headers */

// RoarAudio types:
#define ROAR_VIO_DFT_RA_MESSAGE    0x0101
#define ROAR_VIO_DFT_RA_BUFFER     0x0102

// extern types:
#define ROAR_VIO_DFT_OGG_PAGE      0x0201
#define ROAR_VIO_DFT_OGG_PACKET    0x0202

struct roar_vio_dataformat {
 unsigned int type;
};

struct roar_vio_sysio_ioctl {
 long long int   cmd;
 void          * argp;
};

struct roar_vio_sysio_sockopt {
 int         level;
 int         optname;
 void      * optval;
 socklen_t   optlen;
};

#if 0
          struct stat {
              dev_t     st_dev;     /* ID of device containing file */
              ino_t     st_ino;     /* inode number */
            X mode_t    st_mode;    /* protection */
            X nlink_t   st_nlink;   /* number of hard links */
            X uid_t     st_uid;     /* user ID of owner */
            X gid_t     st_gid;     /* group ID of owner */
              dev_t     st_rdev;    /* device ID (if special file) */
            X off_t     st_size;    /* total size, in bytes */
            X blksize_t st_blksize; /* blocksize for filesystem I/O */
            X blkcnt_t  st_blocks;  /* number of blocks allocated */
              time_t    st_atime;   /* time of last access */
              time_t    st_mtime;   /* time of last modification */
              time_t    st_ctime;   /* time of last status change */
          };
#endif

struct roar_vio_stat {
 mode_t mode;
 size_t linkc;
 uid_t  uid;
 gid_t  gid;
 size_t size;
 size_t blksize;
 size_t blocks;
};

// struct for userpass:
struct roar_userpass {
 int subtype;
 char * user;
 char * pass;
};

// for ROAR_VIO_CTL_GET_SOCKNAME and ROAR_VIO_CTL_GET_PEERNAME
struct roar_sockname {
 int flags;
 int type;
 char * addr;
 int port;
};

#endif

//ll
