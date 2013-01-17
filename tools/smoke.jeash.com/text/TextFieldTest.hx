import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.text.Font;
import flash.Lib;

import haxe.Resource;

/*#if flash
@:font("hobbyofnight.ttf") class HobbyOfNight extends Font {}
#end*/

class TextFieldTest extends Sprite {
	public function new() {
		super();

		var fieldDatas:Array<Dynamic>=[
			{y:0, text: "Left", align:TextFormatAlign.LEFT},
			{y:40, text: "Center", align:TextFormatAlign.CENTER},
			{y:80, text: "Right", align:TextFormatAlign.RIGHT},
		];

		for (fieldData in fieldDatas) {
			var t:TextField;
			var tf:TextFormat;

			graphics.beginFill(0xff0000);
			graphics.drawRect(0,fieldData.y,200,30);
			graphics.endFill();

			t=new TextField();
			t.y=fieldData.y;
			t.width=200;
			tf=new TextFormat();
			t.embedFonts=true;
			tf.align=fieldData.align;

			#if flash
				tf.font=new HobbyOfNight().fontName;
			#else
				tf.font="HobbyOfNight";
			#end

			tf.size=30;
			t.defaultTextFormat=tf;
			t.text=fieldData.text;
			t.setTextFormat(tf);
			addChild(t);
		}
	}

	static function main () Lib.current.addChild(new TextFieldTest())
}