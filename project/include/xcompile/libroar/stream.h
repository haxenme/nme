//stream.h:

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

#ifndef _LIBROARSTREAM_H_
#define _LIBROARSTREAM_H_

#include "roaraudio.h"

#define _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL

const char * roar_dir2str (const int dir) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;
int    roar_str2dir (const char * name) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL _LIBROAR_ATTR_PURE;

struct roar_stream_info {
 int block_size;
 int pre_underruns;
 int post_underruns;
 uint32_t codec;
 uint32_t flags;
 char * driver;
 uint_least32_t delay;
 int state;
 int mixer;
 int role;
};

struct roar_stream_rpg {
 int        mode;
 uint16_t   mul;
 uint16_t   div;
};

int roar_stream_connect (struct roar_connection * con, struct roar_stream * s, int dir, int mixer) _LIBROAR_STREAM_STDATTRS;

int roar_stream_new     (struct roar_stream * s, unsigned int rate, unsigned int channels, unsigned int bits, unsigned int codec) _LIBROAR_ATTR_NONNULL_ALL;

int roar_stream_new_by_info (struct roar_stream * s, const struct roar_audio_info * info) _LIBROAR_STREAM_STDATTRS;

int roar_stream_set_rel_id(struct roar_stream * s, int id) _LIBROAR_ATTR_NONNULL_ALL;
int roar_stream_get_rel_id(struct roar_stream * s) _LIBROAR_STREAM_STDATTRS;

int roar_stream_new_by_id(struct roar_stream * s, int id) _LIBROAR_ATTR_NONNULL_ALL;
int roar_stream_new_empty(struct roar_stream * s) _LIBROAR_STREAM_STDATTRS;

int roar_stream_set_id (struct roar_stream * s, int id) _LIBROAR_ATTR_NONNULL_ALL;
int roar_stream_get_id (struct roar_stream * s) _LIBROAR_STREAM_STDATTRS;

int roar_stream_set_fh (struct roar_stream * s, int fh) _LIBROAR_ATTR_NONNULL_ALL;
int roar_stream_get_fh (struct roar_stream * s) _LIBROAR_STREAM_STDATTRS;

int roar_stream_set_dir (struct roar_stream * s, int dir) _LIBROAR_ATTR_NONNULL_ALL;
int roar_stream_get_dir (struct roar_stream * s) _LIBROAR_STREAM_STDATTRS;

int roar_stream_exec    (struct roar_connection * con, struct roar_stream * s) _LIBROAR_STREAM_STDATTRS;
int roar_stream_connect_to (struct roar_connection * con, struct roar_stream * s, int type, char * host, int port);
int roar_stream_connect_to_ask (struct roar_connection * con, struct roar_stream * s, int type, char * host, int port);
int roar_stream_passfh  (struct roar_connection * con, struct roar_stream * s, int fh) _LIBROAR_STREAM_STDATTRS;

int roar_stream_attach_simple (struct roar_connection * con, struct roar_stream * s, int client) _LIBROAR_STREAM_STDATTRS;

int roar_stream_get_info (struct roar_connection * con, struct roar_stream * s, struct roar_stream_info * info) _LIBROAR_STREAM_STDATTRS;
int roar_stream_get_name (struct roar_connection * con, struct roar_stream * s, char * name, size_t len) _LIBROAR_STREAM_STDATTRS;

int roar_stream_get_chanmap (struct roar_connection * con, struct roar_stream * s, char * map, size_t * len) _LIBROAR_STREAM_STDATTRS;
int roar_stream_set_chanmap (struct roar_connection * con, struct roar_stream * s, char * map, size_t   len) _LIBROAR_STREAM_STDATTRS;

int roar_stream_set_flags  (struct roar_connection * con, struct roar_stream * s, uint32_t flags, int action) _LIBROAR_STREAM_STDATTRS;

int roar_stream_set_role  (struct roar_connection * con, struct roar_stream * s, int role) _LIBROAR_STREAM_STDATTRS;

int roar_stream_get_rpg   (struct roar_connection * con, struct roar_stream * s, struct roar_stream_rpg * rpg) _LIBROAR_STREAM_STDATTRS;
int roar_stream_set_rpg   (struct roar_connection * con, struct roar_stream * s, const struct roar_stream_rpg * rpg) _LIBROAR_STREAM_STDATTRS;

int roar_stream_s2m     (struct roar_stream * s, struct roar_message * m);
int roar_stream_m2s     (struct roar_stream * s, struct roar_message * m);

int32_t      roar_str2codec (const char   * codec) _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_PURE;
const char * roar_codec2str (const uint32_t codec) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;

int32_t      roar_mime2codec (const char   * mime) _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_PURE;
const char * roar_codec2mime (const uint32_t codec) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;

int32_t roar_str2rate(const char * rate) _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_PURE;
int32_t roar_str2bits(const char * bits) _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_PURE;
int32_t roar_str2channels(const char * channels) _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_PURE;

const char * roar_streamstate2str(int streamstate) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;

int    roar_str2role  (const char * role) _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_PURE;
const char * roar_role2str  (const int    role) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;

const char * roar_rpgmode2str(const int rpgmode) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_PURE;

ssize_t roar_info2samplesize (struct roar_audio_info * info) _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_PURE;
ssize_t roar_info2framesize  (struct roar_audio_info * info) _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_PURE;
ssize_t roar_info2bitspersec (struct roar_audio_info * info) _LIBROAR_STREAM_STDATTRS _LIBROAR_ATTR_PURE;

int     roar_profile2info    (struct roar_audio_info * info, const char * profile) _LIBROAR_STREAM_STDATTRS;
ssize_t roar_profiles_list   (const char ** list, size_t len, size_t offset) _LIBROAR_STREAM_STDATTRS;

#endif

//ll
