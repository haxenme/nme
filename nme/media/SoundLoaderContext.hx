#if flash


package nme.media;


@:native ("flash.media.SoundLoaderContext")
extern class SoundLoaderContext {
	var bufferTime : Float;
	var checkPolicyFile : Bool;
	function new(bufferTime : Float = 1000, checkPolicyFile : Bool = false) : Void;
}


#else



package nme.media;

class SoundLoaderContext
{
   public function new()
	{
	}
}



#end