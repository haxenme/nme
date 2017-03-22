//sndiosym.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2009-2013
 *  The code (may) include prototypes and comments (and maybe
 *  other code fragements) from OpenBSD's sndio.
 *  See 'Copyright for sndio' below for more information on
 *  code fragments taken from OpenBSD's sndio.
 *
 * --- Copyright for sndio ---
 * Copyright (c) 2008 Alexandre Ratchov <alex@caoua.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 * --- End of Copyright for sndio ---
 *
 *  This file is part of libroaresd a part of RoarAudio,
 *  a cross-platform sound system for both, home and professional use.
 *  See README for details.
 *
 *  This file is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 3
 *  as published by the Free Software Foundation.
 *
 *  RoarAudio is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this software; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 *  NOTE for everyone want's to change something and send patches:
 *  read README and HACKING! There a addition information on
 *  the license of this document you need to read before you send
 *  any patches.
 */

#ifndef _LIBROARSNDIO_SNDIOSYM_H_
#define _LIBROARSNDIO_SNDIOSYM_H_

#include <roaraudio.h>

#ifdef ROAR_HAVE_H_POLL
#include <poll.h>
#else
struct pollfd;
#endif

#define SIO_PLAY        1
#define SIO_REC         2
#define MIO_OUT		4
#define MIO_IN		8

#define SIO_IGNORE      0       /* pause during xrun */
#define SIO_SYNC        1       /* resync after xrun */
#define SIO_ERROR       2       /* terminate on xrun */
#define SIO_XSTRINGS    {"ignore", "sync", "error"}

#define SIO_NENC	16
#define SIO_NCHAN	8
#define SIO_NRATE	16
#define SIO_NCONF	4

#define SIO_ENCMAX	10

#if BYTE_ORDER == BIG_ENDIAN && !defined(ROAR_TARGET_WIN32)
#define SIO_LE_NATIVE   0
#else
#if BYTE_ORDER == LITTLE_ENDIAN
#define SIO_LE_NATIVE   1
#else
#error Byte Order of this system is not supported within the sndio interface.
#endif
#endif

#define SIO_BPS(bits) (((bits) <= 8) ? 1 : (((bits) <= 16) ? 2 : 4))

#define SIO_SUN_PATH	NULL
#define SIO_AUCAT_PATH	NULL

#define SIO_MAXVOL 127


struct sio_par {
 unsigned bits;          /* bits per sample */
 unsigned bps;           /* bytes per sample */
 unsigned sig;           /* 1 = signed, 0 = unsigned */
 unsigned le;            /* 1 = LE, 0 = BE byte order */
 unsigned msb;           /* 1 = MSB, 0 = LSB aligned */
 unsigned rchan;         /* number channels for recording */
 unsigned pchan;         /* number channels for playback */
 unsigned rate;          /* frames per second */
 unsigned appbufsz;      /* minimum buffer size without xruns */
 unsigned bufsz;         /* end-to-end buffer size (read-only) */
 unsigned round;         /* optimal buffer size divisor */
 unsigned xrun;          /* what to do on overrun/underrun */
};

struct sio_cap {
 struct sio_enc {                /* allowed encodings */
  unsigned bits;                 /* bits per sample */
  unsigned bps;                  /* bytes per sample */
  unsigned sig;                  /* 1 = signed, 0 = unsigned */
  unsigned le;                   /* 1 = LE, 0 = BE byte order */
  unsigned msb;                  /* 1 = MSB, 0 = LSB aligned */
 } enc[SIO_NENC];
 unsigned rchan[SIO_NCHAN];      /* allowed rchans */
 unsigned pchan[SIO_NCHAN];      /* allowed pchans */
 unsigned rate[SIO_NRATE];       /* allowed rates */
 unsigned nconf;                 /* num. of confs[] */
 struct sio_conf {
  unsigned enc;                  /* bitmask of enc[] indexes */
  unsigned rchan;                /* bitmask of rchan[] indexes */
  unsigned pchan;                /* bitmask of pchan[] indexes */
  unsigned rate;                 /* bitmask of rate[] indexes */
 } confs[SIO_NCONF];
};

struct sio_hdl * sio_open(const char * name, unsigned mode, int nbio_flag);
void   sio_close  (struct sio_hdl * hdl);

void   sio_initpar(struct sio_par * par);
int    sio_setpar (struct sio_hdl * hdl, struct sio_par * par);
int    sio_getpar (struct sio_hdl * hdl, struct sio_par * par);

int    sio_getcap (struct sio_hdl * hdl, struct sio_cap * cap);

int    sio_start  (struct sio_hdl * hdl);
int    sio_stop   (struct sio_hdl * hdl);

size_t sio_read   (struct sio_hdl * hdl,       void * addr, size_t nbytes);
size_t sio_write  (struct sio_hdl * hdl, const void * addr, size_t nbytes);

void   sio_onmove (struct sio_hdl * hdl, void (*cb)(void * arg, int delta), void * arg);

int    sio_nfds   (struct sio_hdl * hdl);

int    sio_pollfd (struct sio_hdl * hdl, struct pollfd * pfd, int events);

int    sio_revents(struct sio_hdl * hdl, struct pollfd * pfd);

int    sio_eof    (struct sio_hdl * hdl);

int    sio_setvol (struct sio_hdl * hdl, unsigned vol);
void   sio_onvol  (struct sio_hdl * hdl, void (*cb)(void * arg, unsigned vol), void * arg);

// MIDI:
struct mio_hdl * mio_open   (const char * name, unsigned mode, int nbio_flag);
void             mio_close  (struct mio_hdl * hdl);
size_t           mio_write  (struct mio_hdl * hdl, const void * addr, size_t nbytes);
size_t           mio_read   (struct mio_hdl * hdl, void * addr, size_t nbytes);
int              mio_nfds   (struct mio_hdl * hdl);
int              mio_pollfd (struct mio_hdl * hdl, struct pollfd * pfd, int events);
int              mio_revents(struct mio_hdl * hdl, struct pollfd * pfd);
int              mio_eof    (struct mio_hdl * hdl);

#endif

//ll
