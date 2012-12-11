import flash.events.KeyboardEvent;
import flash.Lib;

class KeyCodeTest {
	static function main () new KeyCodeTest()
	public function new () {
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPress);
	}

	function keyPress(e: KeyboardEvent) {
		var res : Array<Int> = #if js untyped window.phantomTestResult #else null #end;
		if (res == null) res = [];
		res.push(e.keyCode);
		#if js untyped window.phantomTestResult = res; #end
		Lib.trace(res); 
	}
}
