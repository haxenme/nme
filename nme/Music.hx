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
 
package nme;

class Music
{
	static var __m;
	static var INFINITE_LOOP : Int = -1;
	
	public static function init( file : String )
	{
		__m = nme_music_init( file );
	   if (__m==null)
		   throw("invalid music:" + file);
	}
	
	public static function free()
	{
		nme_music_free( __m );
	}
	
	public static function play( loops : Int )
	{
		if (__m!=null)
		{
			// loops:
			// -1 = infinite
			if ( loops < -1 ) loops = -1;
			nme_music_play( __m, loops );
		}
	}
	
	public static function fadeIn( loops : Int, fadeTimeMS : Int, position : Float )
	{
		// loops:
		// -1 = infinite
		// 0  = don't play
		// 1+ = number of loops
		if ( loops < -1 ) loops = -1;
		if ( position == 0 )
			nme_music_fadeinplay( __m, loops, fadeTimeMS );
		else
			nme_music_fadeinplaypos( __m, loops, fadeTimeMS, position );
	}
	
	public static function fadeOut( fadeTimeMS : Int )
	{
		if ( fadeTimeMS < 0 ) fadeTimeMS = Std.int( Math.abs( fadeTimeMS ) );
		nme_music_fadeout( fadeTimeMS );
	}
	
	public static function stop()
	{
		nme_music_stop();
	}
	
	public static function pause()
	{
		nme_music_pause();
	}
	
	public static function resume()
	{
		nme_music_resume();
	}
	
	public static function restart()
	{
		nme_music_restart();
	}
	
	public static function setVolume( vol : Int )
	{
		if ( vol < 0 ) vol = 0;
		if ( vol > 128 ) vol = 128;
		nme_music_volume( vol );
	}
	
	public static function isPlaying() : Bool
	{
		return ( nme_music_isplaying() == 1 );
	}
	
	public static function isPaused() : Bool
	{
		return ( nme_music_ispaused() == 1 );
	}
	
	public static function isFading() : Bool
	{
		return ( nme_music_isfading() == 1 );
	}
	
	static var nme_music_init = nme.Loader.load("nme_music_init", 1);
	static var nme_music_free = nme.Loader.load("nme_music_free", 1);
	static var nme_music_play = nme.Loader.load("nme_music_play", 2);
	static var nme_music_fadeinplay = nme.Loader.load("nme_music_fadeinplay", 3);
	static var nme_music_fadeinplaypos = nme.Loader.load("nme_music_fadeinplaypos", 4);
	static var nme_music_fadeout = nme.Loader.load("nme_music_fadeout", 1);
	static var nme_music_stop = nme.Loader.load("nme_music_stop", 0);
	static var nme_music_pause = nme.Loader.load("nme_music_pause", 0);
	static var nme_music_resume = nme.Loader.load("nme_music_resume", 0);
	static var nme_music_restart = nme.Loader.load("nme_music_restart", 0);
	static var nme_music_volume = nme.Loader.load("nme_music_volume", 1);
	static var nme_music_isplaying = nme.Loader.load("nme_music_isplaying", 0);
	static var nme_music_ispaused = nme.Loader.load("nme_music_ispaused", 0);
	static var nme_music_isfading = nme.Loader.load("nme_music_isfading", 0);
}
