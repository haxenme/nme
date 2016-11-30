//vs.h:

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
 *  and are therefore GPL. Because of this it may be illegal to use
 *  them with any software that uses libesd, libartsc or libpulse*.
 */

#ifndef _LIBROARVS_H_
#define _LIBROARVS_H_

#include "libroar.h"

#define _LIBROAR_VS_STDATTRS _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1)

struct roar_vs;

typedef struct roar_vs roar_vs_t;
typedef signed long int roar_mus_t;

/* return readable string describing the problem */
const char * roar_vs_strerr(int error) _LIBROAR_ATTR_PURE _LIBROAR_ATTR_USE_RESULT;

/* create a new VS object from normal RoarAudio connection object
 * The connection must not be closed caller before roar_vs_close() is called.
 * The connection is not closed by roar_vs_close().
 */
roar_vs_t * roar_vs_new_from_con(struct roar_connection * con, int * error) _LIBROAR_VS_STDATTRS;

/* create a new VS object with a new connection */
roar_vs_t * roar_vs_new(const char * server, const char * name, int * error) _LIBROAR_ATTR_USE_RESULT;

/* start a the stream in the VS object */
int roar_vs_stream(roar_vs_t * vss, const struct roar_audio_info * info, int dir, int * error) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1, 2);

/* connect to server and start stream in once
 * this is basically roar_vs_new() and roar_vs_stream() in one function.
 */
roar_vs_t * roar_vs_new_simple(const char * server, const char * name, int rate, int channels, int codec, int bits, int dir, int * error) _LIBROAR_ATTR_USE_RESULT;

/* create a VS object for playback.
 * This is roar_vs_new_simple() with direction set to 'playback' (wave form data)
 */
#define roar_vs_new_playback(s,n,r,c,e,b,error) roar_vs_new_simple((s), (n), (r), (c), (e), (b), ROAR_DIR_PLAY, (error))


/* Attach a open file.
 */

int roar_vs_file(roar_vs_t * vss, struct roar_vio_calls * vio, int closefile, int * error) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1, 2);

/* Open a file and attach it.
 */
int roar_vs_file_simple(roar_vs_t * vss, const char * filename, int * error) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1, 2);

/* Connects to a server to just play a file.
 */
roar_vs_t * roar_vs_new_from_file(const char * server, const char * name, const char * filename, int * error) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(3);

/* Switch to buffered mode.
 * After swiching to buffered mode you can use the buffered
 * mode functions. You must use roar_vs_iterate() to send data
 * from local buffer to server.
 * This is currently not thread safe but you may implement it in
 * diffrent thread if you do the locking yourself.
 * Takes the size for the used buffers as argument.
 * Buffer size should be a value of 2^n. Typical values are 2048 and 4096.
 */
int roar_vs_buffer(roar_vs_t * vss, size_t buffer, int * error) _LIBROAR_VS_STDATTRS;


/* Boolean TRUE for VS functions */
#define ROAR_VS_TRUE     1
/* Boolean FALSE for VS functions */
#define ROAR_VS_FALSE    0
/* Boolean TOGGLE for VS functions */
#define ROAR_VS_TOGGLE  -1
/* Boolean value used to ask for a value, do not change the value only ask for current value */
#define ROAR_VS_ASK     -2

/* close and free the VS object
 * This does all needed cleanup.
 * If server connection was made by VS it is closed, too.
 * If server connection was provided by caller it is untouched.
 */
int roar_vs_close(roar_vs_t * vss, int killit, int * error) _LIBROAR_ATTR_NONNULL(1);

/* write data to a stream
 * This function writes some data to the stream.
 * return is number of bytes written or -1 on error.
 * return value can be zero to indicate no data can be written but no error.
 * this may be the case with non-blocking streams.
 * returned value can be less then requested value. indicates a short write.
 * you should wait some (short!) time (for example one main loop iteration) and try again.
 */
ssize_t roar_vs_write(roar_vs_t * vss, const void * buf, size_t len, int * error) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1, 2);

/* read data from a stream
 * This function reads some data from the stream.
 * return is number of bytes read or -1 on error.
 * return value can be zero to indicate no data can be read but no error.
 * this may be the case with non-blocking streams.
 * returned value can be less then requested value. indicates a short read.
 * you should wait some (short!) time (for example one main loop iteration) and try again.
 */
ssize_t roar_vs_read (roar_vs_t * vss,       void * buf, size_t len, int * error) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1, 2);

/* wait value for waiting */
#define ROAR_VS_WAIT    1
/* wait value for no waiting */
#define ROAR_VS_NOWAIT  0
/* Trigger action but do not wait for it to complet */
#define ROAR_VS_ASYNC  -1

/* sync a stream with the server (flush buffers)
 * Returns 0 on no error and -1 on error.
 */
int     roar_vs_sync (roar_vs_t * vss, int wait, int * error) _LIBROAR_ATTR_NONNULL(1);

/* set blocking mode of stream
 * returns old blocking state
 */
int     roar_vs_blocking (roar_vs_t * vss, int val, int * error) _LIBROAR_VS_STDATTRS;

/* do not supply backend offset */
#define ROAR_VS_BACKEND_NONE    -1
/* use first found primary stream of same mixer as offset source */
#define ROAR_VS_BACKEND_FIRST   -2
/* use mean of primary streams of same mixer as offset source */
#define ROAR_VS_BACKEND_MEAN    -3
/* default backend, now handled at runtime, old value was hard coded to _FIRST */
#define ROAR_VS_BACKEND_DEFAULT -4

/* get server's position of stream
 * returns server's position of the stream or -1 on error.
 * The returned server position is the position in samples
 * plus a offset provided by the selected backend
 */
ssize_t roar_vs_position(roar_vs_t * vss, int backend, int * error) _LIBROAR_VS_STDATTRS;

/* get latency between playback and local write counter
 * This function may fail because the used codec uses
 * non-fixed bitrate.
 * if this function fails it returns zero and sets error or
 * clear error to ROAR_ERROR_NONE.
 * If non-zero is returned error is untouched.
 * return value is in mu-sec (units of 10^-6s).
 * Note that the returned value may be negative (the server being
 * ahead of us). This is normal in case we read a stream.
 */
roar_mus_t roar_vs_latency(roar_vs_t * vss, int backend, int wait, int * error) _LIBROAR_VS_STDATTRS;

/* set pause flag
 * The pause flag should be set whenever the user presses the pause button or similar.
 * The stream may be come blocking after the pause flag has been set.
 * returns old pause setting (useful with ROAR_VS_TOGGLE)
 */
int     roar_vs_pause(roar_vs_t * vss, int val, int * error) _LIBROAR_ATTR_NONNULL(1);

/* set the mute flag of the stream
 * The pause flag should be set whenever the user mutes the stream in some way.
 * This flag is used so the volume is not changed and can be restored by the server
 * while unmuting.
 * It is very recommended to use this flag and not just set the volume to zero
 * returns old mute setting (useful with ROAR_VS_TOGGLE)
 */
int     roar_vs_mute (roar_vs_t * vss, int val, int * error) _LIBROAR_ATTR_NONNULL(1);

/* set volume of stream (all channels to the same value)
 * volume c is float from 0 ('muted', see above) to 1 (full volume).
 * Returns 0 on no error and -1 on error.
 */
int     roar_vs_volume_mono   (roar_vs_t * vss, float c, int * error) _LIBROAR_ATTR_NONNULL(1);
/* set volume of stream (like volume + balance, stereo mode)
 * volume l and r are floats from 0 ('muted', see above) to 1 (full volume).
 * Returns 0 on no error and -1 on error.
 */
int     roar_vs_volume_stereo (roar_vs_t * vss, float l, float r, int * error) _LIBROAR_ATTR_NONNULL(1);

/* get volume from stream (like volume + balance, stereo mode)
 * volume pointers l and r are floats from 0 ('muted', see above) to 1 (full volume).
 * Returns 0 on no error and -1 on error.
 * NOTE: if you want a 'mono' volume (like roar_vs_volume_mono() takes)
 * you can just use: c = (*l + *r)/2
 */
int     roar_vs_volume_get    (roar_vs_t * vss, float * l, float * r, int * error) _LIBROAR_ATTR_USE_RESULT _LIBROAR_ATTR_NONNULL(1, 2, 3);

/* set an array of meta data for the stream
 * This sets an array of meta data stored in kv of length len for
 * the stream.
 * This should be called before streaming is started using read or write functions
 * but may be called at any time (for example to updata meta data).
 * Returns 0 on no error and -1 on error.
 * Example:
 * struct roar_keyval kv = {.key = "TITLE", .value = "Some title"};
 * ret = roar_vs_meta(vss, &kv, 1, &err);
 */
int     roar_vs_meta          (roar_vs_t * vss, struct roar_keyval * kv, size_t len, int * error) _LIBROAR_ATTR_NONNULL(1, 2);

/* sets the stream role
 * see ../roaraudio/stream.h for possible roles
 * Returns 0 on no error and -1 on error.
 */
int     roar_vs_role          (roar_vs_t * vss, int role, int * error) _LIBROAR_ATTR_NONNULL(1);

/* Run a single iteration.
 * This will try to read data from source, write it to the stream
 * and flush the buffer in buffered mode.
 * Returns -1 on error, 0 on EOF and positive true value on no error.
 */
int     roar_vs_iterate       (roar_vs_t * vss, int wait, int * error) _LIBROAR_ATTR_NONNULL(1);

/* Iterate until EOF or error.
 * Very simple main loop.
 * Returns 0 on no error and -1 on error.
 */
int     roar_vs_run           (roar_vs_t * vss, int * error) _LIBROAR_ATTR_NONNULL(1);

ssize_t roar_vs_get_avail_read(roar_vs_t * vss, int * error) _LIBROAR_VS_STDATTRS;
ssize_t roar_vs_get_avail_write(roar_vs_t * vss, int * error) _LIBROAR_VS_STDATTRS;

/* If in buffered mode drop all data from internal buffer.
 * This drops all data in current ringbuffers. You can
 * select if data is only droped in write or read buffer.
 * This may be usefull in case of seeking and such
 * but should be avoided as it may break the bitstream.
 */
int     roar_vs_reset_buffer(roar_vs_t * vss, int writering, int readring, int * error) _LIBROAR_VS_STDATTRS _LIBROAR_ATTR_DEPRECATED;

/* Misc controls.
 * Use of this should be avoided by application.
 */

enum roar_vs_ctlcmd {
 ROAR_VS_CMD_NOOP      = 0,
#define ROAR_VS_CMD_NOOP ROAR_VS_CMD_NOOP
 ROAR_VS_CMD_SET_MIXER,
#define ROAR_VS_CMD_SET_MIXER ROAR_VS_CMD_SET_MIXER
 ROAR_VS_CMD_GET_MIXER,
#define ROAR_VS_CMD_GET_MIXER ROAR_VS_CMD_GET_MIXER
 ROAR_VS_CMD_SET_FIRST_PRIM,
#define ROAR_VS_CMD_SET_FIRST_PRIM ROAR_VS_CMD_SET_FIRST_PRIM
 ROAR_VS_CMD_GET_FIRST_PRIM,
#define ROAR_VS_CMD_GET_FIRST_PRIM ROAR_VS_CMD_GET_FIRST_PRIM

 // Latency control:
 ROAR_VS_CMD_SET_LATC_P,
#define ROAR_VS_CMD_SET_LATC_P ROAR_VS_CMD_SET_LATC_P
 ROAR_VS_CMD_GET_LATC_P,
#define ROAR_VS_CMD_GET_LATC_P ROAR_VS_CMD_GET_LATC_P
 ROAR_VS_CMD_SET_LATC_TARGET,
#define ROAR_VS_CMD_SET_LATC_TARGET ROAR_VS_CMD_SET_LATC_TARGET
 ROAR_VS_CMD_GET_LATC_TARGET,
#define ROAR_VS_CMD_GET_LATC_TARGET ROAR_VS_CMD_GET_LATC_TARGET
 ROAR_VS_CMD_SET_LATC_WINDOW,
#define ROAR_VS_CMD_SET_LATC_WINDOW ROAR_VS_CMD_SET_LATC_WINDOW
 ROAR_VS_CMD_GET_LATC_WINDOW,
#define ROAR_VS_CMD_GET_LATC_WINDOW ROAR_VS_CMD_GET_LATC_WINDOW
 ROAR_VS_CMD_SET_LATC_MINLAG,
#define ROAR_VS_CMD_SET_LATC_MINLAG ROAR_VS_CMD_SET_LATC_MINLAG
 ROAR_VS_CMD_GET_LATC_MINLAG,
#define ROAR_VS_CMD_GET_LATC_MINLAG ROAR_VS_CMD_GET_LATC_MINLAG

 // Volume:
 ROAR_VS_CMD_SET_FREE_VOLUME,
#define ROAR_VS_CMD_SET_FREE_VOLUME ROAR_VS_CMD_SET_FREE_VOLUME
 ROAR_VS_CMD_GET_FREE_VOLUME,
#define ROAR_VS_CMD_GET_FREE_VOLUME ROAR_VS_CMD_GET_FREE_VOLUME

 // auto pause flag, needed for sync streams:
 ROAR_VS_CMD_SET_DEFAULT_PAUSED,
#define ROAR_VS_CMD_SET_DEFAULT_PAUSED ROAR_VS_CMD_SET_DEFAULT_PAUSED
 ROAR_VS_CMD_GET_DEFAULT_PAUSED,
#define ROAR_VS_CMD_GET_DEFAULT_PAUSED ROAR_VS_CMD_GET_DEFAULT_PAUSED

 // Async operation:
 ROAR_VS_CMD_SET_ASYNC,
#define ROAR_VS_CMD_SET_ASYNC ROAR_VS_CMD_SET_ASYNC
 ROAR_VS_CMD_GET_ASYNC,
#define ROAR_VS_CMD_GET_ASYNC ROAR_VS_CMD_GET_ASYNC
 ROAR_VS_CMD_LOCK_ASYNC,
#define ROAR_VS_CMD_LOCK_ASYNC ROAR_VS_CMD_LOCK_ASYNC
 ROAR_VS_CMD_UNLOCK_ASYNC,
#define ROAR_VS_CMD_UNLOCK_ASYNC ROAR_VS_CMD_UNLOCK_ASYNC
};

typedef enum roar_vs_ctlcmd roar_vs_ctlcmd;

#define ROAR_VS_ASYNCLEVEL_NONE   0
#define ROAR_VS_ASYNCLEVEL_ENABLE 1
#define ROAR_VS_ASYNCLEVEL_AUTO   2

int     roar_vs_ctl           (roar_vs_t * vss, roar_vs_ctlcmd cmd, void * argp, int * error) _LIBROAR_VS_STDATTRS;


/* Get used connection object
 * This may be useful if you want to use functions from the main API.
 * Returns used connection object or NULL on error.
 */
struct roar_connection * roar_vs_connection_obj(roar_vs_t * vss, int * error) _LIBROAR_VS_STDATTRS;

/* Get used stream object
 * This may be useful if you want to use functions from the main API.
 * Returns used stream object or NULL on error.
 */
struct roar_stream     * roar_vs_stream_obj    (roar_vs_t * vss, int * error) _LIBROAR_VS_STDATTRS;

/* Get used VIO object
 * This may be useful if you want to use functions from the main API.
 * For example this can be used in non-blocking mode
 * to test if we can read or write. To test that use roar_vio_select().
 * Returns used VIO object or NULL on error.
 */
struct roar_vio_calls  * roar_vs_vio_obj       (roar_vs_t * vss, int * error) _LIBROAR_VS_STDATTRS;

/* send NOOP command to server
 * This can be used to ping the server.
 * This is of no use normally.
 * Returns 0 on no error and -1 on error.
 */
#define roar_vs_noop(v, error) roar_noop(roar_vs_connection_obj((v), (error)))

#endif

//ll
