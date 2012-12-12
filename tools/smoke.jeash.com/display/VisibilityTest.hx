package;

import flash.display.Sprite;
import flash.Lib;

/**
 * ...
 * @author kipp
 */
class VisibilityTest extends Sprite {
	
	private var _mcContainer:Sprite;
	private var _mcNested:Sprite;
	
	public function new () {
		
		super ();
		
		_mcContainer = new Sprite();
		_mcNested = new Sprite();	

		var colors = [0xFFCC00, 0xCCFF00, 0x00CCFF, 0xFF00CC, 0xCC00FF, 0x00FFCC];
		for(i in 0...5)
		{
			var s:Sprite = new Sprite();
			s.graphics.beginFill(Math.round(colors[i]));
			s.graphics.drawRect(i*50,0,50,50);
			_mcNested.addChild(s);
			s.visible = i % 2 == 0; // Make every other sprite visible
		}
		
		
		_mcContainer.visible = false;
		
		_mcContainer.visible = true;
		
		addChild(_mcContainer);
		_mcContainer.addChild(_mcNested);

	}

	static function main () Lib.current.stage.addChild(new VisibilityTest())

}
