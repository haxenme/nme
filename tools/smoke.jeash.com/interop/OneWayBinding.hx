import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.Lib;


class OneWayBinding {
	static function main () new OneWayBinding()

	public function new () {
		var s = new Sprite();

		Lib.current.addChild(s);

		s.stage.addEventListener("smite", click);
		s.stage.addEventListener("sprint", mouseOut);
	}

	function click (e) {
		trace("I am clicked by event: (" + e.domEvent.x + ", " + e.domEvent.y + ")");
		#if js untyped window.phantomTestResult = "click: (" + e.domEvent.x + ", " + e.domEvent.y + ")"; #end
	}

	function mouseOut (e) {
		trace("I am moused by event: (" + e.domEvent.x + ", " + e.domEvent.y + ")");
	}
}
