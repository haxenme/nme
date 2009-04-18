
#undef free_lock
#undef lock_release

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <neko.h>
#include "threadaccess.h"

#ifdef NEKO_WINDOWS
#	define LOCK(l)		EnterCriticalSection(&(l))
#	define UNLOCK(l)	LeaveCriticalSection(&(l))
#	define SIGNAL(l)	ReleaseSemaphore(l,1,NULL)
#else
#	define LOCK(l)		pthread_mutex_lock(&(l))
#	define UNLOCK(l)	pthread_mutex_unlock(&(l))
#	define SIGNAL(l)	pthread_cond_signal(&(l))
#endif


static void _deque_add( vdeque *q, value msg ) {
	tqueue *t;
	t = (tqueue*)alloc(sizeof(tqueue));
	t->msg = msg;
	t->next = NULL;
	LOCK(q->lock);
	if( q->last == NULL )
		q->first = t;
	else
		q->last->next = t;
	q->last = t;
	SIGNAL(q->wait);
	UNLOCK(q->lock);
}

/**
	thread_send : 'thread -> msg:any -> void
	<doc>Send a message into the target thread message queue</doc>
**/
void thread_send( value vt, value msg ) {
	vkind k_thread;
	kind_share(&k_thread, "thread");

	vthread *t;
	if(val_is_kind(vt,k_thread)) {
		t = val_thread(vt);
		_deque_add(&t->q,msg);
	}
}


