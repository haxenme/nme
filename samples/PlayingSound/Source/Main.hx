import com.eclecticdesignstudio.motion.Actuate;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.media.SoundChannel;
import nme.Assets;
import nme.Lib;


class Main extends Sprite {
	
	
	private var Fill:Sprite;
	
	private var channel:SoundChannel;
	private var position:Float;
	
	
	public function new () {
		
		super ();
		
		Fill = new Sprite ();
		Fill.graphics.beginFill (0x3CB878);
		Fill.graphics.drawRect (0, 0, Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
		Fill.alpha = 0.1;
		Fill.buttonMode = true;
		Fill.addEventListener (MouseEvent.MOUSE_DOWN, this_onMouseDown);
		addChild (Fill);
		
		play ();
		
	}
	
	
	private function pause ():Void {
		
		if (channel != null) {
			
			position = channel.position;
			channel.removeEventListener (Event.SOUND_COMPLETE, channel_onSoundComplete);
			channel.stop ();
			channel = null;
			
		}
		
		Actuate.tween (Fill, 3, { alpha: 0.1 } );
		
	}
	
	
	private function play ():Void {
		
		var sound = Assets.getSound ("assets/stars.mp3");
		
		channel = sound.play (position);
		channel.addEventListener (Event.SOUND_COMPLETE, channel_onSoundComplete);
		
		Actuate.tween (Fill, 3, { alpha: 1 } );
		
	}
	
	
	private function channel_onSoundComplete (event:Event):Void {
		
		pause ();
		
		position = 0;
		
	}
	
	
	private function this_onMouseDown (event:MouseEvent):Void {
		
		if (channel == null) {
			
			play ();
			
		} else {
			
			pause ();
			
		}
		
	}
	
	
}