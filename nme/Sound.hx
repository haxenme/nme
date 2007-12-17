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

class Sound
{
	var __s:Void;
	
	public function new ( file : String )
	{
		__s = nme_sound_loadwav( untyped file.__s );
	}
	
	public function free()
	{
		nme_sound_free( __s );
	}
	
	public function playChannel( channel : Int, loops : Int )
	{
		if ( loops < -1 ) loops = -1;
		nme_sound_playchannel( __s, channel, loops );
	}
	
	public static function setChannels( num : Int )
	{
		if ( num < 1 ) num = 1;
		nme_sound_setchannels( num );
	}
	
	static var nme_sound_loadwav = neko.Lib.load("nme","nme_sound_loadwav", 1);
	static var nme_sound_free = neko.Lib.load("nme","nme_sound_free", 1);
	static var nme_sound_setchannels = neko.Lib.load("nme","nme_sound_setchannels", 1);
	static var nme_sound_volume = neko.Lib.load("nme","nme_sound_volume", 2);
	static var nme_sound_playchannel = neko.Lib.load("nme","nme_sound_playchannel", 3);
	static var nme_sound_playchanneltimed = neko.Lib.load("nme","nme_sound_playchanneltimed", 4);
	static var nme_sound_fadeinchannel = neko.Lib.load("nme","nme_sound_fadeinchannel", 4);
	static var nme_sound_fadeinchanneltimed = neko.Lib.load("nme","nme_sound_fadeinchanneltimed", 5);
	static var nme_sound_fadeoutchannel = neko.Lib.load("nme","nme_sound_fadeoutchannel", 2);
	static var nme_sound_pause = neko.Lib.load("nme","nme_sound_pause", 1);
	static var nme_sound_resume = neko.Lib.load("nme","nme_sound_resume", 1);
	static var nme_sound_stop = neko.Lib.load("nme","nme_sound_stop", 1);
	static var nme_sound_stoptimed = neko.Lib.load("nme","nme_sound_stoptimed", 2);
	static var nme_sound_isplaying = neko.Lib.load("nme","nme_sound_isplaying", 1);
	static var nme_sound_ispaused = neko.Lib.load("nme","nme_sound_ispaused", 1);
	static var nme_sound_isfading = neko.Lib.load("nme","nme_sound_isfading", 1);
	static var nme_sound_reservechannels = neko.Lib.load("nme","nme_sound_reservechannels", 1);
	static var nme_sound_groupchannel = neko.Lib.load("nme","nme_sound_groupchannel", 2);
	static var nme_sound_groupchannels = neko.Lib.load("nme","nme_sound_groupchannels", 3);
	static var nme_sound_groupcount = neko.Lib.load("nme","nme_sound_groupcount", 1);
	static var nme_sound_groupavailable = neko.Lib.load("nme","nme_sound_groupavailable", 1);
	static var nme_sound_fadeoutgroup = neko.Lib.load("nme","nme_sound_fadeoutgroup", 2);
	static var nme_sound_stopgroup = neko.Lib.load("nme","nme_sound_stopgroup", 1);
}

