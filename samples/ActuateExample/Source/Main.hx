import com.eclecticdesignstudio.motion.Actuate;
import com.eclecticdesignstudio.motion.easing.Quad;
import nme.display.Sprite;
import nme.events.Event;
import nme.Lib;


class Main extends Sprite {
	
	
	public function new () {
		
		super ();
		
		initialize ();
		construct ();
		
	}
	
	
	private function animateCircle (circle:Sprite):Void {
		
		var duration = 1.5 + Math.random () * 4.5;
		var targetX = Math.random () * Lib.current.stage.stageWidth;
		var targetY = Math.random () * Lib.current.stage.stageHeight;
		
		Actuate.tween (circle, duration, { x: targetX, y: targetY }, false).ease (Quad.easeOut).onComplete (animateCircle, [ circle ]);
		
	}
	
	
	private function construct ():Void {
		
		for (i in 0...80) {
			
			var creationDelay = Math.random () * 10;
			Actuate.timer (creationDelay).onComplete (createCircle);
			
		}
		
	}
	
	
	private function createCircle ():Void {
		
		var size = 5 + Math.random () * 35 + 20;
		var circle = new Sprite ();
		
		circle.graphics.beginFill (Std.int (Math.random () * 0xFFFFFF));
		circle.graphics.drawCircle (0, 0, size);
		circle.alpha = 0.2 + Math.random () * 0.6;
		circle.x = Math.random () * Lib.current.stage.stageWidth;
		circle.y = Math.random () * Lib.current.stage.stageHeight;
		
		addChildAt (circle, 0);
		animateCircle (circle);
		
	}
	
	
	private function initialize ():Void {
		
		Lib.current.stage.addEventListener (Event.ACTIVATE, stage_onActivate);
		Lib.current.stage.addEventListener (Event.DEACTIVATE, stage_onDeactivate);
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function stage_onActivate (event:Event):Void {
		
		Actuate.resumeAll ();
		
	}
	
	
	private function stage_onDeactivate (event:Event):Void {
		
		Actuate.pauseAll ();
		
	}
	
	
}