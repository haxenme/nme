#ifndef foosubscribehfoo
#define foosubscribehfoo

/***
  This file is part of PulseAudio.

  Copyright 2004-2006 Lennart Poettering
  Copyright 2006 Pierre Ossman <ossman@cendio.se> for Cendio AB

  PulseAudio is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published
  by the Free Software Foundation; either version 2.1 of the License,
  or (at your option) any later version.

  PulseAudio is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with PulseAudio; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  USA.
***/

#include <inttypes.h>

#include <pulse/def.h>
#include <pulse/context.h>
#include <pulse/cdecl.h>
#include <pulse/version.h>

/** \page subscribe Event Subscription
 *
 * \section overv_sec Overview
 *
 * The application can be notified, asynchronously, whenever the internal
 * layout of the server changes. Possible notifications are described in the
 * \ref pa_subscription_event_type and \ref pa_subscription_mask
 * enumerations.
 *
 * The application sets the notification mask using pa_context_subscribe()
 * and the function that will be called whenever a notification occurs using
 * pa_context_set_subscribe_callback().
 */

/** \file
 * Daemon introspection event subscription subsystem.
 *
 * See also \subpage subscribe
 */

PA_C_DECL_BEGIN

/** Subscription event callback prototype */
typedef void (*pa_context_subscribe_cb_t)(pa_context *c, pa_subscription_event_type_t t, uint32_t idx, void *userdata);

/** Enable event notification */
pa_operation* pa_context_subscribe(pa_context *c, pa_subscription_mask_t m, pa_context_success_cb_t cb, void *userdata);

/** Set the context specific call back function that is called whenever the state of the daemon changes */
void pa_context_set_subscribe_callback(pa_context *c, pa_context_subscribe_cb_t cb, void *userdata);

PA_C_DECL_END

#endif
