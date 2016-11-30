//ltm.h:

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

#ifndef _LIBROARLTM_H_
#define _LIBROARLTM_H_

#include "libroar.h"

// forward declaration for return type of roar_ltm_get().
// you must not access members directly.
struct roar_ltm_result;

/* Register streams for LTM.
 * Takes
 * - connection to server,
 * - used MT (monitoring type),
 * - used window,
 * - array of streams,
 * - length of the array of streams.
 * Returns -1 on error or 0 on no error.
 *
 * Registration is stacked.
 * This means that if you register a stream twice you need to unregister it twice.
 * This is because maybe clients may witch to use LTM and it would be bad
 * if the first client which disconnects would remove the LTM from the stream.
 */
int roar_ltm_register(struct roar_connection * con, int mt, int window, int * streams, size_t slen);

/* Unregister streams from LTM.
 * This function works just like roar_ltm_register() just that it
 * unregisters the streams again.
 *
 * The set of streams you unregister in one stream does not need to be
 * the same as the set you registered. It is perfectly valid to just
 * unregister a subset. or a larger set of streams.
 *
 * The given mt must match. If it does not the behavior is undefined.
 * The server may refuse the request or just unregister the given bits.
 * you should not do this.
 *
 * you must not unregister streams which got deleted by the server.
 */
int roar_ltm_unregister(struct roar_connection * con, int mt, int window, int * streams, size_t slen);

/* Read values for LTM from the server.
 * This function takes:
 * - The connection to the server,
 * - the monitoring types you request,
 * - the window you request data from,
 * - an array of streams you want data for,
 * - the length of the streams array,
 * - an old result of this function.
 *
 * It returns a pointer to an result object or NULL on error.
 *
 * The MT is allowed to not match the registered mt but must not
 * contain more bits than registered. In most causes this match
 * the registered MT.
 *
 * The window must match the window used then streams got registered.
 *
 * The list of streams must not match a single registration.
 * but all streams must be registered with at least the bits used in mt
 * set at registration.
 *
 * The old result is taken so this function does not need to always
 * allocate new memory. If the given result is as big as needed to store
 * the new result it is overwritten or freed and re-allocated if it is
 * too small.
 * If you do not have a old result set pass NULL.
 *
 * If you no longer need the result and will not call this function again
 * you must free the result with roar_ltm_freeres().
 */
struct roar_ltm_result * roar_ltm_get(struct roar_connection * con, int mt, int window, int * streams, size_t slen, struct roar_ltm_result * oldresult);

/* This function frees the result.
 * This may be defined as macro. Never call the function
 * this references as directly if this is a macro.
 */
#define roar_ltm_freeres(x) roar_mm_free((x))

/* Get number of streams which are included in a result.
 * returns -1 on error.
 */
int roar_ltm_get_numstreams(struct roar_ltm_result * res);

/* Get the mt included in the given result.
 * returns -1 on error.
 */
int roar_ltm_get_mt(struct roar_ltm_result * res);

/* Get the window included in the given result.
 * returns -1 on error.
 */
int roar_ltm_get_window(struct roar_ltm_result * res);

/* Get the number of channels a stream in result has.
 * Takes the result and the index of the stream in the result.
 * The stream index is the index of the stream in the stream list
 * you provided to roar_ltm_get(). This is not the stream id.
 *
 * returns -1 on error.
 *
 * You must use this function to get the number of channels for a stream
 * and not any value you got on some other way.
 * This is because this function returns the value in the very moment in witch the
 * result set was collected in the server.
 */
int roar_ltm_get_numchans(struct roar_ltm_result * res, size_t streamidx);

/* Extract a single value from the result.
 * Takes
 * - the result,
 * - the mt for which you ask,
 * - the index of the stream in the result and
 * - The channel you request a value for.
 *
 * returns -1 on error.
 *
 * The mt parameter must not have more than one bit set.
 *
 * The stream index is the index of the stream in the stream list
 * you provided to roar_ltm_get(). This is not the stream id.
 *
 * The channel is the channel number you ask data for.
 * it must not be bigger than one less what roar_ltm_get_numchans() returned.
 * (channels are counted from zero to N-1, not from 1 to N)
 */
int64_t roar_ltm_extract(struct roar_ltm_result * res, int mt, size_t streamidx, int channel);

#endif

//ll
