/*
 * Copyright (c) 2006, Lee McColl Sylvester - www.designrealm.co.uk
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

// On windows, seems we have to include this before neko
#include <iostream>

#include "nsdl.h"
#include "nme.h"
#include "ByteArray.h"
#include "renderer/QuickVec.h"

/////////////// Sound event handling ///////////////////

#ifdef NEKO_WINDOWS
#include <windows.h>
typedef CRITICAL_SECTION hxMutex;
void MutexInit(hxMutex &ioMutex) { InitializeCriticalSection(&ioMutex); }
void MutexLock(hxMutex &ioMutex) { EnterCriticalSection(&ioMutex); }
void MutexUnlock(hxMutex &ioMutex) { LeaveCriticalSection(&ioMutex); }
#else
#include <pthreads.h>
typedef pthread_mutex_t hxMutex;
void MutexInit(hxMutex &ioMutex) { pthread_mutex_init(&ioMutex); }
void MutexLock(hxMutex &ioMutex) { pthread_mutex_lock(&ioMutex); }
void MutexUnlock(hxMutex &ioMutex) { pthread_mutex_unlock(&ioMutex); }
#endif

hxMutex sgChannelListMutex;

struct BootMutex { BootMutex() { MutexInit(sgChannelListMutex); } };
static BootMutex boot;

class AutoLock
{
public:
   AutoLock()
	{
		MutexLock(sgChannelListMutex);
	}
	~AutoLock()
	{
		MutexUnlock(sgChannelListMutex);
	}
};


QuickVec<int> sgDoneChannels;

void onSdlMixerChannelDone(int channel)
{
	AutoLock a;
	sgDoneChannels.push_back(channel);
}

int soundGetNextDoneChannel()
{
	AutoLock a;
	if (sgDoneChannels.empty())
		return -1;
	int result = sgDoneChannels[0];
	sgDoneChannels.EraseAt(0);
	return result;
}


/////////////////////////////////////////////////////////

void nme_sound_free( value snd )
{
	if ( val_is_kind( snd, k_snd ) )
	{
		val_gc( snd, NULL );

		Mix_Chunk *chunk = SOUND( snd );
		Mix_FreeChunk( chunk );
	}
}

value nme_sound_loadwav( value file )
{
	val_check( file, string );

	Mix_Chunk *snd = Mix_LoadWAV( val_string( file ) );
	if ( snd == NULL )
		printf("unable to load sound %s\n", val_string( file ));

	value v = alloc_abstract( k_snd, snd );
	val_gc( v, nme_sound_free );
	return v;
}

/**
* Loads a sound (wav/mp3/ogg etc) from an NME ByteArray
*
* @param p_bytes String value
* @param p_len number of bytes to use from p_bytes
* @return Sound instance handle (Mix_Chunk)
**/
value nme_sound_loadbytearray( value p_hndByteArray )
{
	ByteArray *ba = BYTEARRAY(p_hndByteArray);
	if(!ba || ba->mSize == 0)
		return val_null;

	Mix_Chunk *snd = Mix_LoadWAV_RW(SDL_RWFromConstMem(ba->mPtr, ba->mSize), 0);
	if ( snd == NULL ) {
		printf("nme_sound_loadbytearray: unable to load sound\n");
		return val_null;
	}

	value v = alloc_abstract( k_snd, snd );
	val_gc( v, nme_sound_free );
	return v;
}

/**
* Loads a sound (wav/mp3/ogg etc) from a memory buffer.
*
* @param p_bytes String value
* @param p_len number of bytes to use from p_bytes
* @return Sound instance handle (Mix_Chunk)
**/
value nme_sound_loadbytes( value p_bytes, value p_len )
{
	val_check( p_len, int );

	int len = val_int( p_len );
	#ifdef HXCPP
		Array<unsigned char> b = p_bytes;
		if (b == null() || len < 1)
			failure("nme_sound_loadbytes: bytes expected");
		const char *bytes = (const char *)&b[0];
	#else
		val_check( p_bytes, string );
		const char *bytes = val_string(p_bytes);
	#endif

	Mix_Chunk *snd = Mix_LoadWAV_RW(SDL_RWFromConstMem(bytes, len), 0);
	if ( snd == NULL ) {
		printf("nme_sound_loadbytes: unable to load sound\n");
		return val_null;
	}

	value v = alloc_abstract( k_snd, snd );
	val_gc( v, nme_sound_free );
	return v;
}

/**
* Sets a sound channel play head position.
* @param p_millis Position in milliseconds. This may be longer than the clip length.
**/
value nme_sound_setchannelposition( value channel, value position ) {
	val_check( channel, int );
	val_check( position, int );

	return alloc_bool( Mix_SetChannelPosition(val_int(channel), val_int(position)) );
}

/**
* Returns the length in milliseconds of the sound clip
*
* @param snd Sound instance
* @return length in milliseconds
**/
value nme_sound_getlength( value snd )
{
	val_check_kind( snd, k_snd );

	Mix_Chunk *chunk = SOUND( snd );
	return alloc_int( chunk->length_ticks );
}

value nme_sound_setchannels( value cnt )
{
	val_check( cnt, int );

	return alloc_int( Mix_AllocateChannels( val_int( cnt ) ) );
}

value nme_sound_volume( value snd, value volume )
{
	val_check_kind( snd, k_snd );
	val_check( volume, int );

	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_VolumeChunk( chunk, val_int( volume ) ) );
}

value nme_sound_playchannel( value snd, value channel, value loop )
{
	static bool is_set = false;
	if (!is_set)
	{
		is_set = true;
		Mix_ChannelFinished(onSdlMixerChannelDone);
	}

	val_check_kind( snd, k_snd );
	val_check( channel, int );
	val_check( loop, int );

	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_PlayChannel( val_int( channel ), chunk, val_int( loop ) ) );
}

value nme_sound_playchanneltimed( value snd, value channel, value loop, value ticks )
{
	val_check_kind( snd, k_snd );
	val_check( channel, int );
	val_check( loop, int );
	val_check( ticks, int );

	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_PlayChannelTimed( val_int( channel ), chunk, val_int( loop ), val_int( ticks ) ) );
}

value nme_sound_fadeinchannel( value snd, value channel, value loop, value ms )
{
	val_check_kind( snd, k_snd );
	val_check( channel, int );
	val_check( loop, int );
	val_check( ms, int );

	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_FadeInChannel( val_int( channel ), chunk, val_int( loop ), val_int( ms ) ) );
}

value nme_sound_fadeinchanneltimed( value snd, value channel, value loop, value ms, value ticks )
{
	val_check_kind( snd, k_snd );
	val_check( channel, int );
	val_check( loop, int );
	val_check( ms, int );
	val_check( ticks, int );

	Mix_Chunk *chunk = SOUND( snd );

	return alloc_int( Mix_FadeInChannelTimed( val_int( channel ), chunk, val_int( loop ), val_int( ms ), val_int( ticks ) ) );
}

value nme_sound_fadeoutchannel( value channel, value ms )
{
	val_check( channel, int );
	val_check( ms, int );

	return alloc_int( Mix_FadeOutChannel( val_int( channel ), val_int( ms ) ) );
}

value nme_sound_pause( value channel )
{
	val_check( channel, int );

	Mix_Pause( val_int( channel ) );

	return alloc_int( 0 );
}

value nme_sound_resume( value channel )
{
	val_check( channel, int );

	Mix_Resume( val_int( channel ) );

	return alloc_int( 0 );
}

value nme_sound_stop( value channel )
{
	val_check( channel, int );

	Mix_HaltChannel( val_int( channel ) );

	return alloc_int( 0 );
}

value nme_sound_stoptimed( value channel, value ticks )
{
	val_check( channel, int );
	val_check( ticks, int );

	return alloc_int( Mix_ExpireChannel( val_int( channel ), val_int( ticks ) ) );
}

value nme_sound_isplaying( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_Playing( val_int( channel ) ) );
}

value nme_sound_ispaused( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_Paused( val_int( channel ) ) );
}

value nme_sound_isfading( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_FadingChannel( val_int( channel ) ) );
}

value nme_sound_reservechannels( value cnt )
{
	val_check( cnt, int );

	return alloc_int( Mix_ReserveChannels( val_int( cnt ) ) );
}

value nme_sound_groupchannels( value from, value to, value group )
{
	val_check( from, int );
	val_check( to, int );
	val_check( group, int );

	return alloc_int( Mix_GroupChannels( val_int( from ), val_int( to ), val_int( group ) ) );
}

value nme_sound_groupchannel( value channel, value group )
{
	val_check( channel, int );
	val_check( group, int );

	return alloc_int( Mix_GroupChannel( val_int( channel ), val_int( group ) ) );
}

value nme_sound_groupcount( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_GroupCount( val_int( channel ) ) );
}

value nme_sound_groupavailable( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_GroupAvailable( val_int( channel ) ) );
}

value nme_sound_fadeoutgroup( value channel, value ms )
{
	val_check( channel, int );
	val_check( ms, int );

	return alloc_int( Mix_FadeOutGroup( val_int( channel ), val_int( ms ) ) );
}

value nme_sound_stopgroup( value channel )
{
	val_check( channel, int );

	return alloc_int( Mix_HaltGroup( val_int( channel ) ) );
}



// music relative functions



void nme_music_free( value music )
{
	if ( val_is_kind( music, k_mus ) )
	{
		val_gc( music, NULL );

		Mix_Music *msc = MUSIC( music );
		Mix_FreeMusic( msc );
	}
}

value nme_music_init( value file )
{
	val_check( file, string );

	Mix_Music *music;
	music = Mix_LoadMUS( val_string( file ) );
	if(!music)
   {
		printf("%s : %s\n", val_string( file ), Mix_GetError());
      return val_null;
   }

	value v = alloc_abstract( k_mus, music );
	val_gc( v, nme_music_free );
	return v;
}

value nme_music_play( value music, value loops )
{
	val_check_kind( music, k_mus );
	val_check( loops, int );

	Mix_Music *msc = MUSIC( music );

	return alloc_int( Mix_PlayMusic( msc, val_int( loops ) ) );
}

value nme_music_fadeinplay( value music, value loops, value ms )
{
	val_check_kind( music, k_mus );
	val_check( loops, int );
	val_check( ms, int );

	Mix_Music *msc = MUSIC( music );

	return alloc_int( Mix_FadeInMusic( msc, val_int( loops ), val_int( ms ) ) );
}

value nme_music_fadeinplaypos( value music, value loops, value ms, value pos )
{
	val_check_kind( music, k_mus );
	val_check( loops, int );
	val_check( ms, int );
	val_check( pos, int );

	Mix_Music *msc = MUSIC( music );

	return alloc_int( Mix_FadeInMusicPos( msc, val_int( loops ), val_int( ms ), val_int( pos ) ) );
}

value nme_music_fadeout( value ms )
{
	val_check( ms, int );

	return alloc_int( Mix_FadeOutMusic( val_int( ms ) ) );
}

value nme_music_stop()
{
	return alloc_int( Mix_HaltMusic() );
}

value nme_music_pause()
{
	Mix_PauseMusic();

	return alloc_int( 0 );
}

value nme_music_resume()
{
	Mix_ResumeMusic();

	return alloc_int( 0 );
}

value nme_music_restart()
{
	Mix_RewindMusic();

	return alloc_int( 0 );
}

value nme_music_volume( value volume )
{
	val_check( volume, int );

	return alloc_int( Mix_VolumeMusic( val_int( volume ) ) );
}

value nme_music_isplaying()
{
	return alloc_int( Mix_PlayingMusic() );
}

value nme_music_ispaused()
{
	return alloc_int( Mix_PausedMusic() );
}

value nme_music_isfading()
{
	return alloc_int( Mix_FadingMusic() );
}

DEFINE_PRIM(nme_sound_loadwav, 1);
DEFINE_PRIM(nme_sound_free, 1);
DEFINE_PRIM(nme_sound_setchannels, 1);
DEFINE_PRIM(nme_sound_volume, 2);
DEFINE_PRIM(nme_sound_playchannel, 3);
DEFINE_PRIM(nme_sound_playchanneltimed, 4);
DEFINE_PRIM(nme_sound_fadeinchannel, 4);
DEFINE_PRIM(nme_sound_fadeinchanneltimed, 5);
DEFINE_PRIM(nme_sound_fadeoutchannel, 2);
DEFINE_PRIM(nme_sound_getlength, 1);
DEFINE_PRIM(nme_sound_loadbytearray, 1);
DEFINE_PRIM(nme_sound_loadbytes, 2);
DEFINE_PRIM(nme_sound_pause, 1);
DEFINE_PRIM(nme_sound_resume, 1);
DEFINE_PRIM(nme_sound_setchannelposition, 2);
DEFINE_PRIM(nme_sound_stop, 1);
DEFINE_PRIM(nme_sound_stoptimed, 2);
DEFINE_PRIM(nme_sound_isplaying, 1);
DEFINE_PRIM(nme_sound_ispaused, 1);
DEFINE_PRIM(nme_sound_isfading, 1);
DEFINE_PRIM(nme_sound_reservechannels, 1);
DEFINE_PRIM(nme_sound_groupchannel, 2);
DEFINE_PRIM(nme_sound_groupchannels, 3);
DEFINE_PRIM(nme_sound_groupcount, 1);
DEFINE_PRIM(nme_sound_groupavailable, 1);
DEFINE_PRIM(nme_sound_fadeoutgroup, 2);
DEFINE_PRIM(nme_sound_stopgroup, 1);

DEFINE_PRIM(nme_music_init, 1);
DEFINE_PRIM(nme_music_free, 1);
DEFINE_PRIM(nme_music_play, 2);
DEFINE_PRIM(nme_music_fadeinplay, 3);
DEFINE_PRIM(nme_music_fadeinplaypos, 4);
DEFINE_PRIM(nme_music_fadeout, 1);
DEFINE_PRIM(nme_music_stop, 0);
DEFINE_PRIM(nme_music_pause, 0);
DEFINE_PRIM(nme_music_resume, 0);
DEFINE_PRIM(nme_music_restart, 0);
DEFINE_PRIM(nme_music_volume, 1);
DEFINE_PRIM(nme_music_isplaying, 0);
DEFINE_PRIM(nme_music_ispaused, 0);
DEFINE_PRIM(nme_music_isfading, 0);
