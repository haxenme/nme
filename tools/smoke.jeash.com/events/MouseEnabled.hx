package ;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.Lib;

class MouseEnabled extends Sprite
{
	public function new() 
	{
		super();
		
		var bitmapChild:Bitmap = new Bitmap(new BitmapData(200, 200, false, 0xFF0000));
		
		addChild(bitmapChild);
		
		mouseEnabled = false;
		mouseChildren = false;
		
		addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
			Lib.trace("I've been clicked...mouse enabled is : " + mouseEnabled);
			#if js untyped window.phantomTestResult = false; #end
		});
		#if js untyped window.phantomTestResult = true; #end
	}

	static function main () Lib.current.stage.addChild(new MouseEnabled())
}
