//stack.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2009-2013
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

#ifndef _LIBROARSTACK_H_
#define _LIBROARSTACK_H_

#include "libroar.h"

#define ROAR_STACK_SIZE 32

#define ROAR_STACK_FLAG_NONE       0x00
#define ROAR_STACK_FLAG_FREE_SELF  0x01
#define ROAR_STACK_FLAG_FREE_DATA  0x02

struct roar_stack {
 int next;
 int flags;

 void (*free)(void*);

 void * slot[ROAR_STACK_SIZE];
};

int roar_stack_new(struct roar_stack * stack);
struct roar_stack * roar_stack_newalloc(void);

int roar_stack_free(struct roar_stack * stack);

int roar_stack_set_free(struct roar_stack * stack, void (*func)(void*));
int roar_stack_set_flag(struct roar_stack * stack, int flag, int reset);

int roar_stack_push    (struct roar_stack * stack, void *  ptr);
int roar_stack_pop     (struct roar_stack * stack, void ** ptr);
int roar_stack_get_cur (struct roar_stack * stack, void ** ptr);

#endif

//ll
