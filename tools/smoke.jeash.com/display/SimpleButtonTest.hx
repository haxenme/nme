import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.Lib;

class SimpleButtonTest extends Sprite {
	public function new() {
		super();

		var button:CustomSimpleButton = new CustomSimpleButton();
		addChild(button);
	}
	static function main () Lib.current.addChild(new SimpleButtonTest())
}

class CustomSimpleButton extends SimpleButton {
	var upColor:Int;
	var overColor:Int;
	var downColor:Int;
	var size:Int;

	public function new() {
		upColor   = 0xFFCC00;
		overColor = 0xCCFF00;
		downColor = 0x00CCFF;
		size      = 80;

		super();

		downState      = new ButtonDisplayState(downColor, size);
		overState      = new ButtonDisplayState(overColor, size);
		upState        = new ButtonDisplayState(upColor, size);
		hitTestState   = new ButtonDisplayState(upColor, size * 2);
		hitTestState.x = -(size / 4);
		hitTestState.y = hitTestState.x;
		useHandCursor  = true;
	}
}

class ButtonDisplayState extends Shape {
	var bgColor:Int;
	var size:Int;

	public function new(bgColor:Int, size:Int) {
		this.bgColor = bgColor;
		this.size    = size;

		super();

		draw();
	}

	function draw() {
		graphics.beginFill(bgColor);
		graphics.drawRect(0, 0, size, size);
		graphics.endFill();
	}
}

