package nme.media;
#if (cpp || neko)


class SoundTransform
{
	
	public var pan:Float;
	public var volume:Float;
	
	
	public function new(vol:Float = 1.0, panning:Float = 0.0)
	{
		volume = vol;
		pan = panning;
	}
	
	
	public function clone()
	{
		return new SoundTransform(volume, pan);
	}
	
}


#elseif js

class SoundTransform {
	public var leftToLeft : Float;
	public var leftToRight : Float;
	public var pan : Float;
	public var rightToLeft : Float;
	public var rightToRight : Float;
	public var volume : Float;
	public function new(?vol : Float, ?panning : Float) : Void {
	}
}

#else
typedef SoundTransform = flash.media.SoundTransform;
#end