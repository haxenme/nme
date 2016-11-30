//error.h:

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

#ifndef _LIBROARERROR_H_
#define _LIBROARERROR_H_

#include "libroar.h"

struct roar_message;

enum roar_error_type {
 ROAR_ERROR_TYPE_ROARAUDIO = 0,
 ROAR_ERROR_TYPE_ERRNO,
 ROAR_ERROR_TYPE_WINSOCK,
 ROAR_ERROR_TYPE_HERROR,
 ROAR_ERROR_TYPE_YIFF,
 ROAR_ERROR_TYPE_APPLICATION,
 ROAR_ERROR_TYPE_HTTP,
 ROAR_ERROR_TYPE_EAI /* getaddrinfo() and friends */
};

/*
  Off Size (Byte)
    | | /- Name
    0 1 Version
    1 1 Cmd
    2 1 RA Errno
    3 1 RA SubErrno
    4 2 Portable Errno
    6 2 Flags
   (8 0 Datalen)
    8 N Data
 */

struct roar_error_frame {
 int version;
 int cmd;
 int ra_errno;
 int ra_suberrno;
 int p_errno;
 uint16_t flags;
 size_t datalen;
 void * data;
};

struct roar_error_state {
 size_t refc;
 int libroar_error; // roar_error
 int system_error; // errno
#ifdef ROAR_TARGET_WIN32
 int winsock_error; // WSAGetLastError(), WSASetLastError()
#endif
#ifdef ROAR_HAVE_VAR_H_ERRNO
 int syssock_herror; // h_errno
#endif
#ifdef __YIFF__
 yiffc_error_t yiffc_error; // yiffc_error
#endif
};

struct roar_error_frame * roar_err_errorframe(void);

int    roar_err_init(struct roar_error_frame * frame);
void * roar_err_buildmsg(struct roar_message * mes, void ** data, struct roar_error_frame * frame);
int    roar_err_parsemsg(struct roar_message * mes, void *  data, struct roar_error_frame * frame);

#define roar_error (*roar_errno2())
int *  roar_errno2(void);

// clear RoarAudio's error value
void   roar_err_clear(void);

// clear system's error value (errno)
void   roar_err_clear_errno(void);

// clear all error values (to be used before calling roar_err_update())
void   roar_err_clear_all(void);

// syncs RoarAudio's and system's error values
void   roar_err_update(void);

// test of system's error value is set to 'no error'
int    roar_err_is_errno_clear(void);

// set RoarAudio's error value
void   roar_err_set(const int error);

// sync RoarAudio's error value with the value from the system
void   roar_err_from_errno(void);

// sync systen's error value with the value from RoarAudio
void   roar_err_to_errno(void);

// Convert error codes between diffrent representations.
// returnes the error or ROAR_ERROR_NONE on success so it does not alter global error state.
int    roar_err_convert(int * out, const enum roar_error_type outtype, const int in, const enum roar_error_type intype);

// Outputs a default error for the given type.
// returnes the error or ROAR_ERROR_NONE on success so it does not alter global error state.
int    roar_err_get_default_error(int * out, const enum roar_error_type type);

// Resets the stored state to 'no error' state. This can be used
// to init the state.
int    roar_err_initstore(struct roar_error_state * state);

// store a error state (both libroar and system)
// returnes the error or ROAR_ERROR_NONE on success so it does not alter global error state.
int    roar_err_store(struct roar_error_state * state);

// restore error state to values at time of call to roar_err_store()
// returnes the error or ROAR_ERROR_NONE on success so it does not alter global error state.
int    roar_err_restore(struct roar_error_state * state);

// Return a string descriping the error
const char * roar_error2str(const int error);

// Error string looking like a read only variable.
#define roar_errorstring (roar_error2str(roar_error))

#endif

//ll
