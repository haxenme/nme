//services.h:

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

#ifndef _LIBROARSERVICES_H_
#define _LIBROARSERVICES_H_

#include "libroar.h"

enum roar_service_num {
 // Error value in case any function returns this type.
 // roar_error must be set on return.
 ROAR_SERVICE_NUM_ERROR   = -1,
#define ROAR_SERVICE_NUM_ERROR ROAR_SERVICE_NUM_ERROR
 // reserved for future use.
 ROAR_SERVICE_NUM_DEFAULT =  0,
//#define ROAR_SERVICE_NUM_DEFAULT ROAR_SERVICE_NUM_DEFAULT
 // current number of objects.
 ROAR_SERVICE_NUM_CURRENT =  1,
#define ROAR_SERVICE_NUM_CURRENT ROAR_SERVICE_NUM_CURRENT
 // minumum number of objects. Optional.
 ROAR_SERVICE_NUM_MIN,
#define ROAR_SERVICE_NUM_MIN ROAR_SERVICE_NUM_MIN
 // maximum number of objects. Optional.
 ROAR_SERVICE_NUM_MAX,
#define ROAR_SERVICE_NUM_MAX ROAR_SERVICE_NUM_MAX
 // average number of objects. Optional.
 ROAR_SERVICE_NUM_AVG,
#define ROAR_SERVICE_NUM_AVG ROAR_SERVICE_NUM_AVG
 // Hint for buffer size used to list(). list() can still return 'buffer to short'.
 ROAR_SERVICE_NUM_BUFFER,
#define ROAR_SERVICE_NUM_BUFFER ROAR_SERVICE_NUM_BUFFER
};

// clients:
#define ROAR_SERVICE_CLIENT_NAME "client"
#define ROAR_SERVICE_CLIENT_ABI  "1.0beta9-pr1"
struct roar_client;
struct roar_service_client {
 // get list of client IDs.
 // buffer is passed as ids, buffer size (in elements) is passed as len.
 // returns the number of elements stored in ids or -1 on error.
 ssize_t (*list)(int * ids, size_t len);
 // get the number of clients. See also comments above on what.
 ssize_t (*num)(enum roar_service_num what);
 // get a client by ID. The object returned is a copy and must not be motified.
 int (*get)(int id, struct roar_client * client);
 // kick a client by ID. The reason for the kick is stored in error and msg.
 // if msg is NULL it defaults to roar_error2str(error).
 int (*kick)(int id, int error, const char * msg);
 // return status of client as returned by CPI's status() callback.
 int (*status)(int id);

 // optional functions follow:

 // set PID, UID and/or GID for client.
 // if any ID is -1 the old value is not touched if clear is false.
 // if clear is false IDs passed as -1 are reset to 'not set'.
 // if altering IDs changes the permissions of a given client is up to the
 // provider.
 int (*set_ids)(int id, int clear, int pid, int uid, int gid);
 // set the name of the client.
 // the name is copied within this call so the bufer holding it can be freed.
 int (*set_name)(int id, const char * name);
 // this will change the protocol of the client.
 int (*set_proto)(int id, int proto);
 // this execes the stream.
 // the stream must be owned by the client.
 // if stream is -1 the client is execed.
 // This will result in the client be completly reset to a state
 // as directly after accept(). This must be followed by a call to set_proto().
 int (*exec)(int id, int stream);
};

// streams:
struct roar_stream_info;
struct roar_stream_rpg;
struct roar_service_stream {
 // get list of stream IDs.
 // buffer is passed as ids, buffer size (in elements) is passed as len.
 // returns the number of elements stored in ids or -1 on error.
 ssize_t (*list)(int * ids, size_t len);
 // get the number of streams. See also comments above on what.
 ssize_t (*num)(enum roar_service_num what);
 // get a stream by ID. The object returned is a copy and must not be motified.
 int (*get)(int id, struct roar_stream * s, struct roar_stream_info * info);
 // kick a stream by ID. The reason for the kick is stored in error and msg.
 // if msg is NULL it defaults to roar_error2str(error).
 int (*kick)(int id, int error, const char * msg);

 // optional functions follow:

 // create a new stream.
 // if parent is set to -1 a normal stream is created.
 // if it is set to the ID of an existing stream it is created as child/virtual stream.
 // if mixer is set to -1 the default mixer is used.
 int (*new)(const struct roar_audio_info * info, int dir, int parent, int mixer);
 // get the ID of the client owning the stream.
 int (*get_client)(int id);
 // set the owner of the stream.
 // if the stream is already owned by a client it is moved if possible.
 int (*set_client)(int id, int client);
 // set role of stream.
 // if role is passed as -1 the role is cleared.
 int (*set_role)(int id, int role);
 // alter stream flags.
 int (*set_flag)(int id, uint32_t flags, int action);
 // get name of stream.
 // the buffer returned in *name must be freed using roar_mm_free().
 int (*get_name)(int id, char ** name);
 // set name of stream.
 // stream name will be copied so the buffer can be freed after this call.
 // passing NULL will unset the stream name.
 int (*set_name)(int id, const char * name);
 // set volume and rpg settings.
 // If mixer or rpg is NULL the corresponding setting is not touched.
 // if both are NULL this does nothing.
 int (*set_volume)(int id, const struct roar_mixer_settings * mixer, const struct roar_stream_rpg * rpg);
};

// about:
#define ROAR_SERVICE_ABOUT_NAME "about"
#define ROAR_SERVICE_ABOUT_ABI  "1.0beta9"
struct roar_service_about {
 int (*show)(const struct roar_dl_libraryname * libname);
};

// help:
#define ROAR_SERVICE_HELP_NAME "help"
#define ROAR_SERVICE_HELP_ABI  "1.0beta9"
struct roar_service_help {
 int (*show)(const struct roar_dl_libraryname * libname, const char * topic);
};

// prefs:
// procctl:
#define ROAR_SERVICE_PROCCTL_ERROR     ((uint_least32_t)0xFFFFFFFFUL)
#define ROAR_SERVICE_PROCCTL_NONE      ((uint_least32_t)0x00000000UL)
#define ROAR_SERVICE_PROCCTL_ALL       ((uint_least32_t)0x7FFFFFFFUL)
#define ROAR_SERVICE_PROCCTL_CONFIG    ((uint_least32_t)0x00000001UL)
#define ROAR_SERVICE_PROCCTL_LOGFILE   ((uint_least32_t)0x00000002UL)
#define ROAR_SERVICE_PROCCTL_PIDFILE   ((uint_least32_t)0x00000004UL)

struct roar_service_procctl {
 // terminate the process.
 // rv is the return POSIX return code.
 // a value of zero means no error.
 // a value of -1 means the provider should decide the value
 // based on the other parameters.
 // a value smaller than -1 is not allowed.
 // all other values indicate some kind of error.
 // error and msg give a closer information why the process is terminated.
 // those can be be used in case rv is set to -1. they can also be printed
 // or logged by the the provider for later inspection.
 int (*exit)(int rv, int error, const char * msg);

 // optional functions follow:

 // restart the process.
 int (*restart)(void);
 // daemonize the process.
 // the process is moved into background, detaching from the console.
 int (*daemonize)(void);
 // reload config or other parts. See above.
 int (*reload)(uint_least32_t what);
 // reopen logfiles or other parts. See above.
 int (*reopen)(uint_least32_t what);
};

// queue:
struct roar_service_queue {
 ssize_t (*list)(int * ids, size_t len);
 ssize_t (*num)(enum roar_service_num what);
 int (*get_name)(int id, char ** name);
 // status?
 int (*play)(int id);
 int (*stop)(int id);
 int (*pause)(int id, int how);
 int (*next)(int id);
 int (*prev)(int id);
};

#endif

//ll
