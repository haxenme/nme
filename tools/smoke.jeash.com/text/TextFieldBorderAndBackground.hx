package;

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.text.Font;
import flash.Lib;

class TextFieldBorderAndBackground extends Sprite {
	static function main () Lib.current.addChild(new TextFieldBorderAndBackground())

	private var holder:Sprite;
	private var gridHolder:Sprite;

	public function new() {
		super();

		holder=new Sprite();
		addChild(holder);

		gridHolder=new Sprite();
		addChild(gridHolder);

		vGrid(50);
		vGrid(250);

		hGrid(50);
		hGrid(100);
		hGrid(150);
		hGrid(200);

		makeTextField(50,0,false,false,".text",false);
		makeTextField(300,0,false,false,".htmlText",false);


		makeTextField(50,50,false,false,"I am just plain",false);
		makeTextField(50,100,true,false,"I have a border",false);
		makeTextField(50,150,false,true,"I have a background",false);
		makeTextField(50,200,true,true,"I have border and background",false);

		makeTextField(300,50,false,false,"I am just <b>plain</b>",true);
		makeTextField(300,100,true,false,"I have a <b>border</b>",true);
		makeTextField(300,150,false,true,"I have a <b>background</b>",true);
		makeTextField(300,200,true,true,"I have <b>border<b> and <b>background</b>",true);
	}

	private function vGrid(xPos:Int):Void {
		gridHolder.graphics.lineStyle(1,0xff8000,.25);
		gridHolder.graphics.moveTo(xPos,25);
		gridHolder.graphics.lineTo(xPos,260);
	}

	private function hGrid(yPos:Int):Void {
		gridHolder.graphics.lineStyle(1,0xff8000,.25);
		gridHolder.graphics.moveTo(25,yPos);
		gridHolder.graphics.lineTo(275,yPos);
	}

	private function makeTextField(xPos:Int, yPos:Int, border:Bool, background:Bool, text:String, html:Bool):Void {
		var t:TextField=new TextField();
		t.background=background;
		t.backgroundColor=0xc0c0ff;
		t.border=border;
		t.borderColor=0x0000ff;
		t.height=40;
		t.x=xPos;
		t.y=yPos;
		t.width=200;
		var tf:TextFormat=new TextFormat();
		t.embedFonts=true;
		tf.align=TextFormatAlign.CENTER;

		#if flash
			tf.font=new HobbyOfNight().fontName;
		#else
			tf.font="HobbyOfNight";
		#end

		tf.size=12;
		t.defaultTextFormat=tf;

		if (html)
			t.htmlText=text;

		else
			t.text=text;

		t.setTextFormat(tf);
		holder.addChild(t);
	}
}