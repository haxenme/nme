import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.KeyboardEvent;
import nme.Assets;
import nme.Lib;
import nme.ui.Keyboard;


class Main extends Sprite {
	
	
	private var Logo:Sprite;
	
	private var movingDown:Bool;
	private var movingLeft:Bool;
	private var movingRight:Bool;
	private var movingUp:Bool;
	
	
	public function new () {
		
		super ();
		
		Logo = new Sprite ();
		Logo.addChild (new Bitmap (Assets.getBitmapData ("assets/nme.png")));
		Logo.x = 100;
		Logo.y = 100;
		Logo.buttonMode = true;
		addChild (Logo);
		
		Lib.current.stage.addEventListener (KeyboardEvent.KEY_DOWN, stage_onKeyDown);
		Lib.current.stage.addEventListener (KeyboardEvent.KEY_UP, stage_onKeyUp);
		Lib.current.stage.addEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		
	}
	
	
	private function stage_onKeyDown (event:KeyboardEvent):Void {
		
		switch (event.keyCode) {
			
			case Keyboard.DOWN: movingDown = true;
			case Keyboard.LEFT: movingLeft = true;
			case Keyboard.RIGHT: movingRight = true;
			case Keyboard.UP: movingUp = true;
			
		}
		
	}
	
	
	private function stage_onKeyUp (event:KeyboardEvent):Void {
		
		switch (event.keyCode) {
			
			case Keyboard.DOWN: movingDown = false;
			case Keyboard.LEFT: movingLeft = false;
			case Keyboard.RIGHT: movingRight = false;
			case Keyboard.UP: movingUp = false;
			
		}
		
	}
	
	
	private function this_onEnterFrame (event:Event):Void {
		
		if (movingDown) {
			
			Logo.y += 5;
			
		}
		
		if (movingLeft) {
			
			Logo.x -= 5;
			
		}
		
		if (movingRight) {
			
			Logo.x += 5;
			
		}
		
		if (movingUp) {
			
			Logo.y -= 5;
			
		}
		
	}
	
	
}