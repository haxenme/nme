package;

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.text.Font;
import flash.Lib;

import haxe.Resource;

class DoubleCenteredTextField extends Sprite {

	static function main () Lib.current.addChild(new DoubleCenteredTextField())

	private var fontName:String;

	public function new() {
		super();

		fontName="HobbyOfNight";

		#if flash
			fontName=new HobbyOfNight().fontName;
		#end

		hTest();
		vTest();
	}

	private function vTest():Void {
		var holder:Sprite=new Sprite();
		holder.graphics.beginFill(0xff0000);
		holder.graphics.drawRect(0,0,200,40);
		holder.graphics.endFill();
		holder.x=200;
		holder.y=50;
		addChild(holder);

		var t:TextField=new TextField();
		addChild(t);

		t.width=200;
		t.embedFonts=true;
		var tf:TextFormat=new TextFormat();
		tf.align=TextFormatAlign.CENTER;
		tf.font=fontName;
		tf.size=16;
		t.defaultTextFormat=tf;
		t.text="Center Me...";

		t.y=holder.y;
		t.x=holder.x+holder.width/2-t.width/2;
	}

	private function hTest():Void {
		var holder:Sprite=new Sprite();
		holder.graphics.beginFill(0xff8080);
		holder.graphics.drawRect(0,0,200,80);
		holder.graphics.endFill();
		holder.x=200;
		holder.y=100;
		addChild(holder);

		var t:TextField=new TextField();
		addChild(t);

		t.width=200;
		t.height=80;
		t.embedFonts=true;
		var tf:TextFormat=new TextFormat();
		tf.align=TextFormatAlign.CENTER;
		tf.font=fontName;
		tf.size=12;
		t.defaultTextFormat=tf;
		t.text="I should be at the top of the box...";

		t.y=holder.y+holder.height/2-t.height/2;
		t.x=holder.x+holder.width/2-t.width/2;
	}
}