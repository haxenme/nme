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

/**
* @author	Russell Weir
*/
class Sound
{
	/** Sets number of sound channels available in SDL **/
	public static var numChannels(__getNumChannels,__setNumChannels) : Int;
	/** Allows automatic increase of channel count, to maximum of [maxChannels] **/
	public static var autoAllocChannels : Bool = true;
	/** No more than this many channels will be automatically created **/
	public static var maxChannels : Int = 32;

	/** length in milliseconds **/
	public var length(__getLength, null) : Int;

	/** sound resource handle **/
	var __s:Dynamic;

	public function new ( file : String=null )
	{
		load(file);
	}

	/**
	* Manually free the sound resource. Once this call has been made, make no
	* attempts at using this Sound. This is not a required call, as the
	* garbage collector will free the sound resource automatically
	*/
	public function destroy()
	{
		nme_sound_free( __s );
	}

	/**
	* Load from a file path
	*
	* @param file Local file path
	**/
	public function load( file : String ) {
		if(file != null) {
			#if neko
				__s = nme_sound_loadwav( untyped file.__s );
			#else
				__s = nme_sound_loadwav( file );
			#end
		}
	}

	public function loadFromBytes( bytes:haxe.io.BytesData )
	{
		var len = #if neko neko.NativeString.length(bytes) #else bytes.length #end;

		if(bytes == null || len == 0)
			throw "Null data";
		__s = nme_sound_loadbytes( bytes, len );
	}

	public function loadFromByteArray( bytes : nme.utils.ByteArray )
	{
		__s = nme_sound_loadbytearray(bytes.get_handle());
	}

	/**
	* Play the sound on a channel.
	*
	* @param loops Number of times to loop the clip, -1 for continuous
	* @param channel Either a specified channel, or -1 (default) for first available channel
	* @return Channel number assigned to clip, <0 on error (generally out of free channels)
	**/
	public function play( loops:Int, channel : Int=-1 ) : Int
	{
		if ( loops < 0 )
			loops = -1;
		var rv = nme_sound_playchannel( __s, channel, loops );

		// only attempts again if the user has not specified the channel
		if( rv < 0 && numChannels < maxChannels && autoAllocChannels && channel != -1) {
			// increase channels by 50%
			var max = maxChannels + (Std.int(maxChannels / 2));
			if(max > maxChannels)
				max = maxChannels;
			numChannels = max;
			// try to start the sound again
			rv = nme_sound_playchannel( __s, channel, loops );
		}

		return rv;
	}


	private function __getLength() : Int
	{
		return nme_sound_getlength( __s );
	}



	//////////////////////////// Statics /////////////////////////////////
	static inline var QUIT : String = "quit";

	/**
	* This is a dynamic method that may be overridden to receive sound complete
	* events. Be aware that this handler operates in it's own thread, so
	* the handler must be thread safe.
	*
	* @param channel The channel number that has finished playing.
	*/
	public static dynamic function onChannelFinished(channel:Int) : Void {
	}

	/**
	* Sets the playhead to position milliseconds on specified channel.
	*
	* @param channel Channel number
	* @param position Playhead position in milliseconds
	**/
	public static function setChannelPosition( channel:Int, position:Int) : Bool {
		if( channel < 0 )
			return false;
		return nme_sound_setchannelposition( channel, position );
	}



	static function __getNumChannels() : Int {
		return nme_sound_setchannels( -1 );
	}

	static function __setNumChannels( count : Int ) : Int
	{
		var v = count;
		if ( v < 1 )
			v = 1;

		if ( v > maxChannels )
			v = maxChannels;

		if(v == nme_sound_setchannels( -1 ))
			return count;

		nme_sound_setchannels( v );
		return count;
	}

	static var nme_sound_loadwav = nme.Loader.load("nme_sound_loadwav", 1);
	static var nme_sound_free = nme.Loader.load("nme_sound_free", 1);
	static var nme_sound_setchannels = nme.Loader.load("nme_sound_setchannels", 1);
	static var nme_sound_volume = nme.Loader.load("nme_sound_volume", 2);
	static var nme_sound_loadbytearray = nme.Loader.load("nme_sound_loadbytearray", 1);
	static var nme_sound_loadbytes = nme.Loader.load("nme_sound_loadbytes", 2);
	static var nme_sound_playchannel = nme.Loader.load("nme_sound_playchannel", 3);
	static var nme_sound_playchanneltimed = nme.Loader.load("nme_sound_playchanneltimed", 4);
	static var nme_sound_fadeinchannel = nme.Loader.load("nme_sound_fadeinchannel", 4);
	static var nme_sound_fadeinchanneltimed = nme.Loader.load("nme_sound_fadeinchanneltimed", 5);
	static var nme_sound_fadeoutchannel = nme.Loader.load("nme_sound_fadeoutchannel", 2);
	static var nme_sound_getlength = nme.Loader.load("nme_sound_getlength", 1);
	static var nme_sound_pause = nme.Loader.load("nme_sound_pause", 1);
	static var nme_sound_resume = nme.Loader.load("nme_sound_resume", 1);
	static var nme_sound_setchannelposition = nme.Loader.load("nme_sound_setchannelposition", 2);
	static var nme_sound_stop = nme.Loader.load("nme_sound_stop", 1);
	static var nme_sound_stoptimed = nme.Loader.load("nme_sound_stoptimed", 2);
	static var nme_sound_isplaying = nme.Loader.load("nme_sound_isplaying", 1);
	static var nme_sound_ispaused = nme.Loader.load("nme_sound_ispaused", 1);
	static var nme_sound_isfading = nme.Loader.load("nme_sound_isfading", 1);
	static var nme_sound_reservechannels = nme.Loader.load("nme_sound_reservechannels", 1);
	static var nme_sound_groupchannel = nme.Loader.load("nme_sound_groupchannel", 2);
	static var nme_sound_groupchannels = nme.Loader.load("nme_sound_groupchannels", 3);
	static var nme_sound_groupcount = nme.Loader.load("nme_sound_groupcount", 1);
	static var nme_sound_groupavailable = nme.Loader.load("nme_sound_groupavailable", 1);
	static var nme_sound_fadeoutgroup = nme.Loader.load("nme_sound_fadeoutgroup", 2);
	static var nme_sound_stopgroup = nme.Loader.load("nme_sound_stopgroup", 1);
}

