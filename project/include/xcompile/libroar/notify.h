//notify.h:

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

#ifndef _LIBROARNOTIFY_H_
#define _LIBROARNOTIFY_H_

#include "libroar.h"

#define ROAR_EVENT_FLAG_NONE        ROAR_EVENT_NETFLAG_NONE
#define ROAR_EVENT_FLAG_NETTRANS    ROAR_EVENT_NETFLAG_DATA
#define ROAR_EVENT_FLAG_PROXYEVENT  ROAR_EVENT_NETFLAG_PROXYEVENT

struct roar_event {
 uint32_t flags;
 uint32_t event;
 uint32_t event_proxy;
 int emitter;
 int target;
 int target_type;
 int arg0;
 int arg1;
 void * arg2;
 ssize_t arg2_len;
};

struct roar_subscriber;

struct roar_notify_core;

#define ROAR_EVENT_GET_TYPE(x) ((x) == NULL ? ROAR_NOTIFY_SPECIAL : ((x)->flags & ROAR_EVENT_FLAG_PROXYEVENT ? (x)->event_proxy : (x)->event))

struct roar_notify_core * roar_notify_core_new(ssize_t lists);
int roar_notify_core_ref(struct roar_notify_core * core);
int roar_notify_core_unref(struct roar_notify_core * core);
#define roar_notify_core_free(x) roar_notify_core_unref((x))

int roar_notify_core_new_global(ssize_t lists);

struct roar_notify_core * roar_notify_core_swap_global(struct roar_notify_core * core);

int roar_notify_core_register_proxy(struct roar_notify_core * core, void (*cb)(struct roar_notify_core * core, struct roar_event * event, void * userdata), void * userdata);

struct roar_subscriber * roar_notify_core_subscribe(struct roar_notify_core * core, struct roar_event * event, void (*cb)(struct roar_notify_core * core, struct roar_event * event, void * userdata), void * userdata);
int roar_notify_core_unsubscribe(struct roar_notify_core * core, struct roar_subscriber * subscriber);

int roar_notify_core_emit(struct roar_notify_core * core, struct roar_event * event);

int roar_notify_core_emit_simple(uint32_t event, int emitter, int target, int target_type, int arg0, int arg1, void * arg2, ssize_t arg2_len);

#define roar_notify_core_emit_snoargs(event,emitter,target,target_type) roar_notify_core_emit_simple((event),(emitter),(target),(target_type),-1,-1,NULL,0)

int roar_event_to_blob(struct roar_event * event, void * blob, size_t * len);
int roar_event_from_blob(struct roar_event * event, void * blob, size_t * len);

#endif

//ll
