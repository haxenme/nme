package nme.media;
#if code_completion


extern class Sound extends nme.events.EventDispatcher {
	var bytesLoaded(default,null) : Int;
	var bytesTotal(default,null) : Int;
	var id3(default,null) : ID3Info;
	var isBuffering(default,null) : Bool;
	@:require(flash10_1) var isURLInaccessible(default,null) : Bool;
	var length(default,null) : Float;
	var url(default,null) : String;
	function new(?stream : nme.net.URLRequest, ?context : SoundLoaderContext) : Void;
	function close() : Void;
	@:require(flash10) function extract(target : nme.utils.ByteArray, length : Float, startPosition : Float = -1) : Float;
	function load(stream : nme.net.URLRequest, ?context : SoundLoaderContext) : Void;
	@:require(flash11) function loadCompressedDataFromByteArray(bytes : nme.utils.ByteArray, bytesLength : Int) : Void;
	@:require(flash11) function loadPCMFromByteArray(bytes : nme.utils.ByteArray, samples : Int, ?format : String, stereo : Bool = true, sampleRate : Float = 44100) : Void;
	function play(startTime : Float = 0, loops : Int = 0, ?sndTransform : SoundTransform) : SoundChannel;
}


#elseif (cpp || neko)
typedef Sound = neash.media.Sound;
#elseif js
typedef Sound = jeash.media.Sound;
#else
typedef Sound = flash.media.Sound;
#end