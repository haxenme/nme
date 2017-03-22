//vio_rtp.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2010-2013
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

#ifndef _LIBROARVIO_RTP_H_
#define _LIBROARVIO_RTP_H_

#include "libroar.h"

#define ROAR_RTP_FLAG_PADDING    0x02
#define ROAR_RTP_FLAG_EXTENSION  0x03
#define ROAR_RTP_FLAG_MARKER     0x08

/*
RFC 3551                    RTP A/V Profile                    July 2003


               PT   encoding    media type  clock rate   channels
                    name                    (Hz)
               ___________________________________________________
               0    PCMU        A            8,000       1
               1    reserved    A
               2    reserved    A
               3    GSM         A            8,000       1
               4    G723        A            8,000       1
               5    DVI4        A            8,000       1
               6    DVI4        A           16,000       1
               7    LPC         A            8,000       1
               8    PCMA        A            8,000       1
               9    G722        A            8,000       1
               10   L16         A           44,100       2
               11   L16         A           44,100       1
               12   QCELP       A            8,000       1
               13   CN          A            8,000       1
               14   MPA         A           90,000       (see text)
               15   G728        A            8,000       1
               16   DVI4        A           11,025       1
               17   DVI4        A           22,050       1
               18   G729        A            8,000       1
               19   reserved    A
               20   unassigned  A
               21   unassigned  A
               22   unassigned  A
               23   unassigned  A
               dyn  G726-40     A            8,000       1
               dyn  G726-32     A            8,000       1
               dyn  G726-24     A            8,000       1
               dyn  G726-16     A            8,000       1
               dyn  G729D       A            8,000       1
               dyn  G729E       A            8,000       1
               dyn  GSM-EFR     A            8,000       1
               dyn  L8          A            var.        var.
               dyn  RED         A                        (see text)
               dyn  VDVI        A            var.        1

               Table 4: Payload types (PT) for audio encodings
 */

#define ROAR_RTP_PT_A_PCMU         0 /* mu-Law */
#define ROAR_RTP_PT_A_PCMA         8 /* A-Law  */
#define ROAR_RTP_PT_A_L16_441_2   10
#define ROAR_RTP_PT_A_L16_441_1   11
#define ROAR_RTP_PT_UNKNOWN      127 /* non standard asignment */

struct roar_rtp_header {
 int version;
 int flags;
 int csrc_count;
 int payload_type;
 uint16_t seq_num;
 uint32_t ts;
 uint32_t ssrc;
 uint32_t csrc[16];
};

struct roar_rtp_inst {
 struct roar_vio_calls * vio;
 struct roar_rtp_header header;
 struct roar_buffer    * io;
 struct roar_audio_info  info;
 size_t                  mtu;
 int                     bpf; // byte per frame

 // read speific things
 struct roar_buffer    * rx_decoded; // buffer to hold allready decoded data
};

int roar_vio_open_rtp        (struct roar_vio_calls * calls, struct roar_vio_calls * dst,
                              char * dstr, struct roar_vio_defaults * odef);

ssize_t roar_vio_rtp_read    (struct roar_vio_calls * vio, void *buf, size_t count);
ssize_t roar_vio_rtp_write   (struct roar_vio_calls * vio, void *buf, size_t count);
int     roar_vio_rtp_sync    (struct roar_vio_calls * vio);
int     roar_vio_rtp_ctl     (struct roar_vio_calls * vio, roar_vio_ctl_t cmd, void * data);
int     roar_vio_rtp_close   (struct roar_vio_calls * vio);

#endif

//ll
