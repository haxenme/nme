package format.swf;


import flash.display.Sprite;
import format.swf.symbol.MorphShape;


class MorphObject extends Sprite {
	
	
	private var data:MorphShape;
	
	
	public function new (data:MorphShape)	{
		
		super ();
		
		this.data = data;
		
	}
	
	
	public function setRatio (ratio:Int):Bool {
		
		// TODO: this could be cached in child objects.
		
		graphics.clear ();
		var f = ratio / 65536.0;
		
		return data.render (graphics, f);
		
	}
	
	
}