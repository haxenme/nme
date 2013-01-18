package;

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.text.Font;
import flash.Lib;

import haxe.Resource;

class BasicTextField extends Sprite {
	static function main () Lib.current.addChild(new BasicTextField())

	public function new() {
		super();

		var fieldDatas:Array<Dynamic>=[
			{y:0, text: "Left", align:TextFormatAlign.LEFT},
			{y:50, text: "Center", align:TextFormatAlign.CENTER},
			{y:100, text: "Right", align:TextFormatAlign.RIGHT},
		];

		for (fieldData in fieldDatas) {
			var t:TextField;
			var tf:TextFormat;

			graphics.beginFill(0x00ff00);
			graphics.drawRect(0,fieldData.y,200,40);
			graphics.endFill();

			t=new TextField();
			t.y=fieldData.y;
			t.width=200;
			tf=new TextFormat();
			t.embedFonts=true;
			tf.align=fieldData.align;

			#if flash
				tf.font=new BasicTextFieldFont().fontName;
			#else
				tf.font="BasicTextFieldFont";
			#end

			tf.size=30;
			t.defaultTextFormat=tf;
			t.text=fieldData.text;
			t.setTextFormat(tf);
			addChild(t);
		}
	}
}
