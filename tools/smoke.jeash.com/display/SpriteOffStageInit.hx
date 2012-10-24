import flash.display.Sprite;
import flash.Lib;

class SpriteOffStageInit extends Sprite {
	static function main () {
		Lib.current.stage.addChild(new SpriteOffStageInit());
	}

	public function new () {
		super();
		stage.stageWidth;
		Lib.trace("started");
		#if js untyped window.phantomTestResult = true; #end
	}
}
