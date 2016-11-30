//error.h:

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

#ifndef _ROARAUDIO_ERROR_H_
#define _ROARAUDIO_ERROR_H_

#define ROAR_ERROR_UNKNOWN     -1 /* Unknown (maybe no) error */
#define ROAR_ERROR_NONE         0 /* No error */
#define ROAR_ERROR_PERM         1 /* Operation not permitted */
#define ROAR_ERROR_NOENT        2 /* No such file or directory */
#define ROAR_ERROR_BADMSG       3 /* Bad message */
#define ROAR_ERROR_BUSY         4 /* Device or resource busy */
#define ROAR_ERROR_CONNREFUSED  5 /* Connection refused */
#define ROAR_ERROR_NOSYS        6 /* Function not implemented */
#define ROAR_ERROR_NOTSUP       7 /* Operation not supported */
#define ROAR_ERROR_PIPE         8 /* Broken pipe */
#define ROAR_ERROR_PROTO        9 /* Protocol error */
#define ROAR_ERROR_RANGE       10 /* Result too large/general out of range */
#define ROAR_ERROR_MSGSIZE     11 /* Message too long */
#define ROAR_ERROR_NOMEM       12 /* Not enough space */
#define ROAR_ERROR_INVAL       13 /* Invalid argument */
#define ROAR_ERROR_ALREADY     14 /* Connection already in progress */
#define ROAR_ERROR_BADRQC      15 /* Invalid request code */
#define ROAR_ERROR_DOM         16 /* Mathematics argument out of domain of function */
#define ROAR_ERROR_EXIST       17 /* File or object exists */
#define ROAR_ERROR_FAULT       18 /* Bad address */
#define ROAR_ERROR_IO          19 /* I/O-Error */
#define ROAR_ERROR_KEYEXPIRED  20 /* Key has expired */
#define ROAR_ERROR_KEYREJECTED 21 /* Key was rejected by service */
#define ROAR_ERROR_LOOP        22 /* Too many recursions */
#define ROAR_ERROR_MFILE       23 /* Too many open files or objects */
#define ROAR_ERROR_NAMETOOLONG 24 /* File or object name too long */
#define ROAR_ERROR_NODATA      25 /* No message is available on the read queue */
#define ROAR_ERROR_NODEV       26 /* No such device */
#define ROAR_ERROR_NODRV       27 /* No such driver */
#define ROAR_ERROR_NOSPC       38 /* No space left on device */
#define ROAR_ERROR_TYPEMM      39 /* Type missmatch. Object of diffrent type required */
#define ROAR_ERROR_NORSYS      40 /* Feature not implemented by remote end */
#define ROAR_ERROR_NOTCONN     41 /* Socket or object not connected */
#define ROAR_ERROR_PROTONOSUP  42 /* Protocol not supported */
#define ROAR_ERROR_RIO         43 /* Remote I/O Error */
#define ROAR_ERROR_RO          45 /* File or object is read only */
#define ROAR_ERROR_TIMEDOUT    46 /* Connection timed out */
#define ROAR_ERROR_AGAIN       47 /* Resource temporarily unavailable */
#define ROAR_ERROR_NOISE       48 /* Line too noisy */
#define ROAR_ERROR_LINKDOWN    49 /* Physical or logical link down */
#define ROAR_ERROR_INTERRUPTED 50 /* Operation was interruped */
#define ROAR_ERROR_CAUSALITY   51 /* Causality error */
#define ROAR_ERROR_QUOTA       52 /* Quota exceeded */
#define ROAR_ERROR_BADLIB      53 /* Accessing a corrupted shared library */
#define ROAR_ERROR_NOMEDIUM    54 /* No medium found */
#define ROAR_ERROR_NOTUNIQ     55 /* Name not unique */
#define ROAR_ERROR_ILLSEQ      56 /* Illegal byte sequence */
#define ROAR_ERROR_ADDRINUSE   57 /* Address in use */
#define ROAR_ERROR_HOLE        58 /* Hole in data */
#define ROAR_ERROR_BADVERSION  59 /* Bad version */
#define ROAR_ERROR_NSVERSION   60 /* Not supported version */
#define ROAR_ERROR_BADMAGIC    61 /* Bad magic number */
#define ROAR_ERROR_LOSTSYNC    62 /* Lost synchronization */
#define ROAR_ERROR_BADSEEK     63 /* Can not seek to destination position */
#define ROAR_ERROR_NOSEEK      64 /* Seeking not supported on resource */
#define ROAR_ERROR_BADCKSUM    65 /* Data integrity error */
#define ROAR_ERROR_NOHORSE     66 /* Mount failed */
#define ROAR_ERROR_CHERNOBYL   67 /* Fatal device error */
#define ROAR_ERROR_NOHUG       68 /* Device needs love */
#define ROAR_ERROR_TEXTBUSY    69 /* Text file busy */
#define ROAR_ERROR_NOTEMPTY    70 /* Directory not empty */
#define ROAR_ERROR_NODEUNREACH 71 /* Node is unreachable */
#define ROAR_ERROR_IDREMOVED   72 /* Identifier removed */
#define ROAR_ERROR_INPROGRESS  73 /* Operation in progress */
#define ROAR_ERROR_NOCHILD     74 /* No child processes/object */
#define ROAR_ERROR_NETUNREACH  75 /* Network unreachable */
#define ROAR_ERROR_CANCELED    76 /* Operation canceled */
#define ROAR_ERROR_ISDIR       77 /* Is a directory */
#define ROAR_ERROR_NOTDIR      78 /* Not a directory */
#define ROAR_ERROR_BADEXEC     79 /* Executable file format error */
#define ROAR_ERROR_ISCONN      80 /* Socket/Object is connected */
#define ROAR_ERROR_DEADLOCK    81 /* Resource deadlock would occur */
#define ROAR_ERROR_CONNRST     82 /* Connection reset */
#define ROAR_ERROR_BADFH       83 /* Bad file handle */
#define ROAR_ERROR_NOTSOCK     84 /* Not a socket */
#define ROAR_ERROR_TOOMANYARGS 85 /* Argument list too long */
#define ROAR_ERROR_TOOLARGE    86 /* File/Object too large */
#define ROAR_ERROR_DESTADDRREQ 87 /* Destination address required */
#define ROAR_ERROR_AFNOTSUP    88 /* Address family not supported */
#define ROAR_ERROR_NOPOWER     89 /* Operation can not be completed because we are low on power */
#define ROAR_ERROR_USER        90 /* Error in front of screen */
#define ROAR_ERROR_NFILE       91 /* Too many files/objects open in system */
#define ROAR_ERROR_STALE       92 /* Stale file handle or object */
#define ROAR_ERROR_XDEVLINK    93 /* Cross-device link */
#define ROAR_ERROR_MLINK       94 /* Too many links to file or object */
#define ROAR_ERROR_NONET       95 /* Not connected to any network */
#define ROAR_ERROR_CONNRSTNET  96 /* Connection reset by network */
#define ROAR_ERROR_CONNABORTED 97 /* Connection aborted */
#define ROAR_ERROR_BADHOST     98 /* Bad host software or hardware */
#define ROAR_ERROR_SWITCHPROTO 99 /* Switch protocol */
#define ROAR_ERROR_MOVEDPERM  100 /* Moved Permanently */
#define ROAR_ERROR_MOVEDTEMP  101 /* Moved Temporary */
#define ROAR_ERROR_USEPROXY   102 /* Use Proxy server */
#define ROAR_ERROR_SEEOTHER   103 /* See other resource */
#define ROAR_ERROR_GONE       104 /* Resource gone */
#define ROAR_ERROR_BADLICENSE 105 /* Bad License */
#define ROAR_ERROR_NEEDPAYMENT 106 /* Payment Required */
#define ROAR_ERROR_NSTYPE     107 /* Type or Format not supported */
#define ROAR_ERROR_CENSORED   108 /* Access denied because of censorship */
#define ROAR_ERROR_BADSTATE   109 /* Object is in bad/wrong state */
#define ROAR_ERROR_DISABLED   110 /* This has been disabled by the administrator */

#endif

//ll
