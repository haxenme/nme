//roarslp.h:

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

#ifndef _LIBROARSLP_H_
#define _LIBROARSLP_H_

#include "libroar.h"

#define ROAR_SLP_MAX_MATCHES       8
#define ROAR_SLP_MAX_URL_LEN       256
#define ROAR_SLP_URL_TYPE_ROAR     "service:mixer.fellig:roar"
#define ROAR_SLP_URL_TYPE_ROAR_LEN 25
#define ROAR_SLP_URL_TYPE_ESD      "service:mixer.fellig:esd"
#define ROAR_SLP_URL_TYPE_ESD_LEN  24
#define ROAR_SLP_URL_TYPE          ROAR_SLP_URL_TYPE_ROAR
#define ROAR_SLP_URL_TYPE_LEN      ROAR_SLP_URL_TYPE_ROAR_LEN

#ifndef ROAR_HAVE_LIBSLP
#define SLPHandle  void *
#define SLPError   int
#define SLPBoolean int
#define SLP_FALSE  0
#define SLP_TRUE   1
#endif

struct roar_slp_search {
 char dummy[8];
};

struct roar_slp_match {
 char   url[ROAR_SLP_MAX_URL_LEN];
 time_t tod; // Time Of Dead (found+TTL)
};

struct roar_slp_cookie {
 SLPError                 callbackerr;
 struct roar_slp_search * search;
 struct roar_slp_match    match[ROAR_SLP_MAX_MATCHES];
 int                      matchcount;
};

SLPBoolean roar_slp_url_callback(SLPHandle        hslp,
                                 const char     * srvurl,
                                 unsigned short   lifetime,
                                 SLPError         errcode,
                                 void           * cookie);

int roar_slp_search          (struct roar_slp_cookie * cookie, char * type);
int roar_slp_cookie_init     (struct roar_slp_cookie * cookie, struct roar_slp_search * search);

char * roar_slp_find_roard   (int nocache);
int    roar_slp_find_roard_r (char * addr, size_t len, int nocache);

#endif

//ll
