#if flash


package nme.media;


@:native ("flash.media.SoundTransform")
@:final extern class SoundTransform {
	var leftToLeft : Float;
	var leftToRight : Float;
	var pan : Float;
	var rightToLeft : Float;
	var rightToRight : Float;
	var volume : Float;
	function new(vol : Float = 1, panning : Float = 0) : Void;
}


#else


package nme.media;

class SoundTransform
{
	public var pan : Float;
	public var volume : Float;

   public function new(vol:Float = 1.0, panning:Float = 0.0)
	{
		volume = vol;
		pan = panning;
	}
	public function clone()
	{
		return new SoundTransform(volume,pan);
	}
}


#end