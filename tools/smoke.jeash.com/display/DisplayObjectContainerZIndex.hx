import flash.display.Sprite;
import flash.Lib;

class DisplayObjectContainerZIndex extends Sprite {
	function new () {
		super();
		var s1:Sprite = new Sprite();
		addChild(s1);

		var s2:Sprite = new Sprite();
		s2.graphics.beginFill(0xff0000);
		s2.graphics.drawRect(0,0,100,100);
		addChild(s2);

		var s1a:Sprite = new Sprite();
		s1a.graphics.beginFill(0x00ff00);
		s1a.graphics.drawRect(0,0,200,200);
		s1.addChild(s1a);
	}

	static function main () 
		Lib.current.addChild(new DisplayObjectContainerZIndex())
}
