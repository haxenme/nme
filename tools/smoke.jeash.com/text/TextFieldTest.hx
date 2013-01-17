import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.text.Font;
import flash.Lib;

class TextFieldTest extends Sprite {
	public function new() {
		super();

		graphics.beginFill(0xff0000);
		graphics.drawRect(0,0,200,20);
		graphics.drawRect(0,40,200,20);
		graphics.endFill();

		var t:TextField;
		var tf:TextFormat;

		t=new TextField();
		t.width=200;
		tf=new TextFormat();
		tf.align=TextFormatAlign.CENTER;
		t.defaultTextFormat=tf;
		t.text="Hello Center World";
		addChild(t);

		t=new TextField();
		t.width=200;
		t.y=40;
		tf=new TextFormat();
		tf.align=TextFormatAlign.RIGHT;
		t.defaultTextFormat=tf;
		t.text="Hello Right World";
		addChild(t);
	}

	static function main () Lib.current.addChild(new TextFieldTest())
}