package native.media;


class SoundTransform {
	
	
	public var pan:Float;
	public var volume:Float;
	
	
	public function new (vol:Float = 1.0, panning:Float = 0.0) {
		
		volume = vol;
		pan = panning;
		
	}
	
	
	public function clone () {
		
		return new SoundTransform (volume, pan);
		
	}
	
	
}