package nme.media;
#if (cpp || neko)


class SoundLoaderContext
{

	public function new()
	{
		
	}
	
}


#elseif js

class SoundLoaderContext {
	public var bufferTime : Float;
	public var checkPolicyFile : Bool;
	public function new(?bufferTime : Float, ?checkPolicyFile : Bool) {
		this.bufferTime = bufferTime;
		this.checkPolicyFile = checkPolicyFile;
	}
}

#else
typedef SoundLoaderContext = flash.media.SoundLoaderContext;
#end