//watchdog.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2012-2013
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

#ifndef _LIBROARWATCHDOG_H_
#define _LIBROARWATCHDOG_H_

#include "libroar.h"

enum roar_watchdog_event {
 ROAR_WATCHDOG_START = 0,
 ROAR_WATCHDOG_STOP,
 ROAR_WATCHDOG_TRIGGER,
 ROAR_WATCHDOG_TICK,
 ROAR_WATCHDOG_TIMEOUT,
 ROAR_WATCHDOG_DOUBLETIMEOUT,
};

#define ROAR_WATCHDOG_CONF_DEFAULTS          -1
#define ROAR_WATCHDOG_CONF_RESTART           -2
#define ROAR_WATCHDOG_CONF_STOPPABLE         0x0001
#define ROAR_WATCHDOG_CONF_CLOCK_INTERNAL    0x0000
#define ROAR_WATCHDOG_CONF_CLOCK_EXTERNAL    0x0010
#define ROAR_WATCHDOG_CONF_CLOCK_ROUND_DOWN  0x0000
#define ROAR_WATCHDOG_CONF_CLOCK_ROUND_UP    0x0020
#define ROAR_WATCHDOG_CONF_EVENTS_ONLY_MAJOR 0x0000
#define ROAR_WATCHDOG_CONF_EVENTS_ALSO_MINOR 0x0100

// start the watchdog.
// timeout is in ms.
int roar_watchdog_start(int config, int_least32_t timeout, int (*callback)(enum roar_watchdog_event event));

// Get timeout for watchdog.
// This may be diffrent from the requested time.
int_least32_t roar_watchdog_gettime(void);

// stop it, if stopping is enabled.
int roar_watchdog_stop(void);

// Trigger the watchdog to show that we are still alive.
int roar_watchdog_trigger(void);

// Trigger the watchdog clock. This is only used if configured to run with external clock source.
int roar_watchdog_tick(void);

#endif

//ll
