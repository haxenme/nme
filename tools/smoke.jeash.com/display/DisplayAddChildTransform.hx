package;

import flash.display.Sprite;
import flash.events.Event;

/**
 * ...
 * @author Kipp Ashford
 */
class DisplayAddChildTransform extends Sprite {
	
	private var _mcMess:Sprite;

	static function main () flash.Lib.current.addChild(new DisplayAddChildTransform())
	
	public function new () {
		
		super ();
		_mcMess = new Sprite();

		// Add some different colored boxes at different heights to see the result.;
		for ( i in 0...10)
		{
			var mc:Sprite = new Sprite(); 
			mc.graphics.beginFill(Math.floor(0.1 * i * 16777215));
			mc.graphics.drawRect(0,0,50,10 + 0.1 * i * 40);
			mc.x = i * 60;
			mc.y = 200;
			_mcMess.addChild(mc);
		}

		// Add the mess with the boxes to the display, and remove after 2 seconds.
		this.addChild(_mcMess);
		stage.addEventListener(Event.ENTER_FRAME, onDelay);
	}

	private function onDelay(_):Void
	{
		this.removeChild(_mcMess);
		this.addChild(_mcMess);
	}
}
