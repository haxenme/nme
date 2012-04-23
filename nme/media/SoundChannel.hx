package nme.media;
#if code_completion


@:final extern class SoundChannel extends nme.events.EventDispatcher {
	var leftPeak(default,null) : Float;
	var position(default,null) : Float;
	var rightPeak(default,null) : Float;
	var soundTransform : SoundTransform;
	function new() : Void;
	function stop() : Void;
}


#elseif (cpp || neko)
typedef SoundChannel = neash.media.SoundChannel;
#elseif js
typedef SoundChannel = jeash.media.SoundChannel;
#else
typedef SoundChannel = flash.media.SoundChannel;
#end