//typedefs.h:

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

#ifndef _ROARAUDIO_TYPEDEFS_H_
#define _ROARAUDIO_TYPEDEFS_H_

#include <roaraudio.h>

// IO:
typedef struct roar_vio_calls        VIO;

// Network:
typedef struct roar_nnode            NNode;

// Buffers, Ram, GP-Structs:
typedef struct roar_keyval           KeyVal;
typedef struct roar_buffer         * RoarBuffer;
typedef void                       * RoarMem; // for use with roar_mm_*()

// Audio:
typedef struct roar_audio_info       AudioInfo;
typedef struct roar_mixer_settings   RoarMixer;

// Meta Data:
typedef struct roar_meta             RoarMeta;

// Protocol:
typedef struct roar_connection       RoarConnection;
typedef struct roar_message          RoarMsg;
typedef struct roar_beep             RoarBeep;

// Objects:
typedef struct roar_client           RoarClient;
typedef struct roar_stream           RoarStream;

// RoarDL:
typedef struct roar_dl_lhandle       LHandle;

// ID types:
typedef int                          RoarSID;
typedef int                          RoarCID;

// Protocol:
typedef int                          RoarCMD;

#endif

//ll
