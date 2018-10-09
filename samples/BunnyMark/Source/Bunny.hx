package;


#if nme

class Bunny
{
   public var x:Float;
   public var y:Float;
   public var speedX:Float;
   public var speedY:Float;
   public function new() { }
}


#else

import openfl.display.Tile;

class Bunny extends Tile {
	
	
	public var speedX:Float;
	public var speedY:Float;
	
	
	public function new () {
		
		super (0);
		
	}
	
	
}
#end
