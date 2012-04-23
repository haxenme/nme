package nme.media;
#if code_completion


extern class SoundLoaderContext {
	var bufferTime : Float;
	var checkPolicyFile : Bool;
	function new(bufferTime : Float = 1000, checkPolicyFile : Bool = false) : Void;
}


#elseif (cpp || neko)
typedef SoundLoaderContext = neash.media.SoundLoaderContext;
#elseif js
typedef SoundLoaderContext = jeash.media.SoundLoaderContext;
#else
typedef SoundLoaderContext = flash.media.SoundLoaderContext;
#end