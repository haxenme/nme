import com.eclecticdesignstudio.motion.Actuate;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.MouseEvent;
import nme.Assets;


class Main extends Sprite {
	
	
	private var Logo:Sprite;
	private var Destination:Sprite;
	
	private var cacheOffsetX:Float;
	private var cacheOffsetY:Float;
	
	
	public function new () {
		
		super ();
		
		Logo = new Sprite ();
		Logo.addChild (new Bitmap (Assets.getBitmapData ("assets/nme.png")));
		Logo.x = 100;
		Logo.y = 100;
		Logo.buttonMode = true;
		
		Destination = new Sprite ();
		Destination.graphics.beginFill (0xF5F5F5);
		Destination.graphics.lineStyle (1, 0xCCCCCC);
		Destination.graphics.drawRect (0, 0, Logo.width + 10, Logo.height + 10);
		Destination.x = 300;
		Destination.y = 95;
		
		addChild (Destination);
		addChild (Logo);
		
		Logo.addEventListener (MouseEvent.MOUSE_DOWN, Logo_onMouseDown);
		
	}
	
	
	private function Logo_onMouseDown (event:MouseEvent):Void {
		
		cacheOffsetX = Logo.x - event.stageX;
		cacheOffsetY = Logo.y - event.stageY;
		
		stage.addEventListener (MouseEvent.MOUSE_MOVE, stage_onMouseMove);
		stage.addEventListener (MouseEvent.MOUSE_UP, stage_onMouseUp);
		
	}
	
	
	private function stage_onMouseMove (event:MouseEvent):Void {
		
		Logo.x = event.stageX + cacheOffsetX;
		Logo.y = event.stageY + cacheOffsetY;
		
	}
	
	
	private function stage_onMouseUp (event:MouseEvent):Void {
		
		if (Destination.hitTestPoint (event.stageX, event.stageY)) {
			
			Actuate.tween (Logo, 1, { x: Destination.x + 5, y: Destination.y + 5 } );
			
		}
		
		stage.removeEventListener (MouseEvent.MOUSE_MOVE, stage_onMouseMove);
		stage.removeEventListener (MouseEvent.MOUSE_UP, stage_onMouseUp);
		
	}
	
	
}