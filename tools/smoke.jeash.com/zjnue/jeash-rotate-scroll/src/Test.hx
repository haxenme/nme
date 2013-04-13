package;

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.geom.Rectangle;

import component.ImgPanel;

class Test extends Sprite {

	var imgPanel : ImgPanel;
	
	public static function main() {
		flash.Lib.current.addChild( new Test() );
	}
	
	public function new() {
		super();
		
		init();
	}
	
	function init() {
	
		// graphics
		var gfx = graphics;
		gfx.beginFill( 0xff0000, 1.0 );
		gfx.drawRect( 0, 0, 940, 640 );
		gfx.endFill();
		
		#if js
		//flash.text.Font.jeashOfResource( "Arial" );
		//var fmt = new TextFormat( "Arial" );
		#end
		
		var s = new Sprite();
		gfx = s.graphics;
		gfx.beginFill( 0x0000ff, 1.0 );
		gfx.drawRect( 0, 0, 140, 22 );
		gfx.endFill();
		addChild(s);
		
		/*
		// text
		var t = new TextField();
		
		#if js
		t.defaultTextFormat = fmt;
		#end
		
		t.width = 140;
		t.height = 22;
		t.border = true;
		t.text = "huuuu";
		
		s.addChild(t);
		*/
		
		s.x = s.y = 100;
		
		s.rotation = 30; // works
		//s.rotation = 90; // fails - textfield appears at 0,0
		
		addChild( imgPanel = new ImgPanel( new Rectangle(0,536,940,104) ) );
	}

}
