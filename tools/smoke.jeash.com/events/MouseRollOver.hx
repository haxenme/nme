import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.Lib;

class MouseRollOver {
	static function main () new MouseRollOver()

	public function new () {
		var s = new Sprite();

		s.graphics.beginFill(0xAACCFF);
		s.graphics.drawCircle(100, 100, 20);
		
		Lib.current.addChild(s);

		s.addEventListener(MouseEvent.MOUSE_OVER, rollOver);
	}

	function rollOver (e) {
		trace("I am rolled over");
		#if js untyped window.phantomTestResult = true; #end
	}
}
