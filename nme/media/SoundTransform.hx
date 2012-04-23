package nme.media;
#if code_completion


@:final extern class SoundTransform {
	var leftToLeft : Float;
	var leftToRight : Float;
	var pan : Float;
	var rightToLeft : Float;
	var rightToRight : Float;
	var volume : Float;
	function new(vol : Float = 1, panning : Float = 0) : Void;
}


#elseif (cpp || neko)
typedef SoundTransform = neash.media.SoundTransform;
#elseif js
typedef SoundTransform = jeash.media.SoundTransform;
#else
typedef SoundTransform = flash.media.SoundTransform;
#end