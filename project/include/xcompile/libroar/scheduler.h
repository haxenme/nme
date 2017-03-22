//scheduler.h:

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

#ifndef _LIBROARSCHEDULER_H_
#define _LIBROARSCHEDULER_H_

#include "libroar.h"

enum roar_scheduler_type {
 ROAR_SCHEDULER_NONE = 0,
 ROAR_SCHEDULER_VIO,
 ROAR_SCHEDULER_TIMEOUT,
 ROAR_SCHEDULER_PLUGIN,
 ROAR_SCHEDULER_PLUGINCONTAINER,
 ROAR_SCHEDULER_CPI_LISTEN,
 ROAR_SCHEDULER_CPI_CLIENT,
 ROAR_SCHEDULER_CPI_SERVICE, // listen for CPI registrations.
 // for future use.
 ROAR_SCHEDULER_CONNECTION,
 ROAR_SCHEDULER_VSS
};

enum roar_scheduler_strategy {
 ROAR_SCHEDULER_STRATEGY_DEFAULT = -1,
 ROAR_SCHEDULER_STRATEGY_SELECT  =  1,
 ROAR_SCHEDULER_STRATEGY_WAIT,
 ROAR_SCHEDULER_STRATEGY_SELECTORWAIT,
 ROAR_SCHEDULER_STRATEGY_WAITORSELECT,
};

#define ROAR_SCHEDULER_FLAG_DEFAULT -1
#define ROAR_SCHEDULER_FLAG_NONE    0x0000
#define ROAR_SCHEDULER_FLAG_FREE    0x0001
#define ROAR_SCHEDULER_FLAG_STUB    0x0002
#define ROAR_SCHEDULER_FLAG_KEEP_RUNNING 0x0004 /* keep _run() running in case of no work */

struct roar_scheduler_source {
 enum roar_scheduler_type type;
 int flags;
 struct roar_dl_lhandle * lhandle;
 struct roar_vio_calls * vio;
 int (*cb)(struct roar_scheduler_source * source, void * userdata, int eventsa);
 void * userdata;
 union {
  void * vp; // dummy.
  int eventsq;
  struct roar_vio_selecttv timeout;
  struct roar_plugincontainer * container;
  struct {
   int proto;
   const struct roar_dl_proto * impl;
   int client;
   struct roar_buffer *obuffer;
   void * userdata;
   const struct roar_keyval * protopara;
   ssize_t protoparalen;
  } cpi;
  struct roar_connection * con;
  roar_vs_t * vss;
 } handle;
};

struct roar_scheduler;

struct roar_scheduler * roar_scheduler_new(int flags, enum roar_scheduler_strategy strategy);
int                     roar_scheduler_ref(struct roar_scheduler * sched);
int                     roar_scheduler_unref(struct roar_scheduler * sched);

int                     roar_scheduler_iterate(struct roar_scheduler * sched);
int                     roar_scheduler_run(struct roar_scheduler * sched);

int                     roar_scheduler_source_add(struct roar_scheduler * sched,
                                                  struct roar_scheduler_source * source);
int                     roar_scheduler_source_del(struct roar_scheduler * sched,
                                                  struct roar_scheduler_source * source);

#endif

//ll
