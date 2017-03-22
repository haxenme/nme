//config.h:

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

#ifndef _LIBROARCONFIG_H_
#define _LIBROARCONFIG_H_

#include "libroar.h"

struct roar_connection;

// WorkAroundS:
#define ROAR_LIBROAR_CONFIG_WAS_NONE        0x00
#define ROAR_LIBROAR_CONFIG_WAS_USE_EXECED  0x01
#define ROAR_LIBROAR_CONFIG_WAS_NO_SLP      0x02

#define ROAR_LIBROAR_CONFIG_PSET_Q          0x0001
#define ROAR_LIBROAR_CONFIG_PSET_COMPLEXITY 0x0002
#define ROAR_LIBROAR_CONFIG_PSET_DTX        0x0004
#define ROAR_LIBROAR_CONFIG_PSET_MAX_CC     0x0008
#define ROAR_LIBROAR_CONFIG_PSET_ABR        0x0010 /* need to implement */
#define ROAR_LIBROAR_CONFIG_PSET_VAD        0x0020 /* need to implement */
#define ROAR_LIBROAR_CONFIG_PSET_AGC        0x0040 /* need to implement */
#define ROAR_LIBROAR_CONFIG_PSET_DENOISE    0x0080 /* need to implement */
#define ROAR_LIBROAR_CONFIG_PSET_VBR        0x0100
#define ROAR_LIBROAR_CONFIG_PSET_MODE       0x0200

#define ROAR_LIBROAR_CONFIG_MODE_NB         ROAR_SPEEX_MODE_NB
#define ROAR_LIBROAR_CONFIG_MODE_WB         ROAR_SPEEX_MODE_WB
#define ROAR_LIBROAR_CONFIG_MODE_UWB        ROAR_SPEEX_MODE_UWB

// mode of operation:
enum roar_libroar_config_opmode {
 ROAR_LIBROAR_CONFIG_OPMODE_NORMAL = 0,
#define ROAR_LIBROAR_CONFIG_OPMODE_NORMAL   ROAR_LIBROAR_CONFIG_OPMODE_NORMAL
 ROAR_LIBROAR_CONFIG_OPMODE_FUNNY  = 1,
#define ROAR_LIBROAR_CONFIG_OPMODE_FUNNY    ROAR_LIBROAR_CONFIG_OPMODE_FUNNY
 ROAR_LIBROAR_CONFIG_OPMODE_MS     = 2,
#define ROAR_LIBROAR_CONFIG_OPMODE_MS       ROAR_LIBROAR_CONFIG_OPMODE_MS
};

struct roar_libroar_forkapi {
 int   (*prefork)(void ** context, void * userdata);
 pid_t (*fork   )(void ** context, void * userdata);
 int   (*failed )(void ** context, void * userdata);
 int   (*parent )(void ** context, void * userdata, pid_t child);
 int   (*child  )(void ** context, void * userdata);
 void * userdata;
};

struct roar_libroar_memmgrapi {
 void *  (*calloc)   (void * userdata, size_t nmemb, size_t size);
 void *  (*malloc)   (void * userdata, size_t size);
 int     (*free)     (void * userdata, void * ptr);
 void *  (*realloc)  (void * userdata, void * ptr, size_t size);
 int     (*reset)    (void * userdata);
 ssize_t (*sizeofbuf)(void * userdata, void * ptr);

// TODO: Memmory locking is not yet supported this way.
 int (*mlock)        (void * userdata, const void * addr, size_t len);
 int (*munlock)      (void * userdata, const void * addr, size_t len);
 int (*mlockall)     (void * userdata, int flags);
 int (*munlockall)   (void * userdata);

 void * userdata;
};

struct roar_libroar_config_codec {
 uint32_t codec; // Codec ID

 // parameters which are set:
 unsigned int para_set;

 // the folloing ints are 256 times there correct value
 // to emulate a .8 bit fixed point float.
 int q;
 int complexity;

 // currectly bools:
 int dtx;
 int vbr;

 // sizes:
 size_t max_cc;

 // enums:
 int mode;
};

struct roar_libroar_config {
 struct {
  int workarounds;
 } workaround;
 const char * server;
 struct {
  int sysio;
  int obsolete;
 } warnings;
 struct {
  size_t num;
  struct roar_libroar_config_codec * codec;
 } codecs;
 struct roar_audio_info info;
 char * authfile;
 char * serversfile;
 struct {
  char * display;
 } x11;
 size_t nowarncounter;
#ifdef ROAR_SUPPORT_TRAP
 enum roar_trap_policy trap_policy;
#endif
 enum roar_libroar_config_opmode opmode;
 const struct roar_libroar_forkapi * forkapi;
 struct roar_vio_calls * (*connect_internal)(struct roar_connection * con, const char * server, int type, int flags, uint_least32_t timeout);
 char * daemonimage;
 int serverflags;
 int protocolversion;
};

struct roar_libroar_config * roar_libroar_get_config_ptr(void) _LIBROAR_ATTR_USE_RESULT;
struct roar_libroar_config * roar_libroar_get_config(void) _LIBROAR_ATTR_USE_RESULT;

int    roar_libroar_reset_config(void);

int    roar_libroar_config_parse(char * txt, char * delm) _LIBROAR_ATTR_NONNULL(1);

struct roar_libroar_config_codec * roar_libroar_config_codec_get(int32_t codec, int create);

int    roar_libroar_set_server(const char * server);
const char * roar_libroar_get_server(void) _LIBROAR_ATTR_USE_RESULT;

int    roar_libroar_set_forkapi(const struct roar_libroar_forkapi * api);
int    roar_libroar_set_memmgrapi(const struct roar_libroar_memmgrapi * api); // implemented in memmgr.c.

int    roar_libroar_set_connect_internal(struct roar_vio_calls * (*func)(struct roar_connection * con, const char * server, int type, int flags, uint_least32_t timeout));

void   roar_libroar_nowarn(void);
void   roar_libroar_warn(void);
#define roar_libroar_iswarn(cfg) (((cfg) == NULL ? roar_libroar_get_config_ptr() : (cfg))->nowarncounter ? 0 : 1)

// get a buffer to a system local path (prefix).
// name is the symbolic name of the path, e.g. "prefix-lib".
// null_as_universal tells of NULL is considered as "universal".
// if not set NULL is considered 'do not add product path, give root prefix'.
// product is the name of the product in standard "product <id/vendor>" format.
// provider is the "<id/vendor>" format. If NULL this is ignored.
// Returns buffer which needs to be freed with roar_mm_free().
// Not all paths support product/provider part. If not supported they are ignored.
char * roar_libroar_get_path(const char * name, int null_as_universal, const char * product, const char * provider) _LIBROAR_ATTR_USE_RESULT;

// This is similar roar_libroar_get_path() with the following diffrences:
// * No product, provider or universal attribute can be passed.
//   The result is as if they were 0, NULL, NULL.
// * The returned buffer is some read-only memory which does not need to be
//   freed.
const char * roar_libroar_get_path_static(const char * name);

// list all known paths:
ssize_t roar_libroar_list_path(const char ** list, size_t len, size_t offset) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL_ALL;

#endif

//ll
