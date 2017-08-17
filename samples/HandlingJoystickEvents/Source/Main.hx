import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.JoystickEvent;
import nme.Assets;
import nme.Lib;
import nme.ui.Keyboard;


class Main extends Sprite {
	
	
	private var Logo:Sprite;
	
	private var movingDown:Bool;
	private var movingLeft:Bool;
	private var movingRight:Bool;
	private var movingUp:Bool;
	
    private var movingDownAxis:Bool;
    private var movingLeftAxis:Bool;
    private var movingRightAxis:Bool;
    private var movingUpAxis:Bool;
	
	public function new () {
		
		super ();
		
		Logo = new Sprite ();
		Logo.addChild (new Bitmap (Assets.getBitmapData ("assets/nme.png")));
		Logo.x = 100;
		Logo.y = 100;
		Logo.buttonMode = true;
		addChild (Logo);
		
		Lib.current.stage.addEventListener (Event.ENTER_FRAME, this_onEnterFrame);

		Lib.current.stage.addEventListener (JoystickEvent.BUTTON_DOWN, onJoystickButtonDown);
		Lib.current.stage.addEventListener (JoystickEvent.BUTTON_UP, onJoystickButtonUp);
		Lib.current.stage.addEventListener (JoystickEvent.AXIS_MOVE, onJoystickAxisMove);
		Lib.current.stage.addEventListener (JoystickEvent.DEVICE_ADDED, onJoystickDeviceAdded);
		Lib.current.stage.addEventListener (JoystickEvent.DEVICE_REMOVED, onJoystickDeviceRemoved);
		
	}
	

private function onJoystickButtonUp( e:JoystickEvent ):Void
{
   trace(e);
   onJoystickButton(e, false);
}

private function onJoystickButtonDown( e:JoystickEvent ):Void
{
   trace(e);
   onJoystickButton(e, true);
}

private function onJoystickAxisMove( e:JoystickEvent ):Void
{
    trace(e);    
    switch(e.id)
    {
        case JoystickEvent.AXIS_LEFTX:
            movingRightAxis = (e.value > 0.5);
            movingLeftAxis = (e.value < -0.5);
        case JoystickEvent.AXIS_LEFTY:
            movingDownAxis = (e.value > 0.5);
            movingUpAxis = (e.value < -0.5);
        case JoystickEvent.AXIS_RIGHTX:
        //
        case JoystickEvent.AXIS_RIGHTY:
        //
        case JoystickEvent.AXIS_TRIGGERLEFT:
        //note: triggers have value range 0 (not pressed) to 1 (pressed)
        case JoystickEvent.AXIS_TRIGGERRIGHT:
        //
    }
}

private function onJoystickDeviceAdded( e:JoystickEvent ):Void
{
   trace(e);
}

private function onJoystickDeviceRemoved( e:JoystickEvent ):Void
{
   trace(e);
}

private function onJoystickButton( e:JoystickEvent, pressed:Bool ):Void
{
    switch(e.id)
    {
        case JoystickEvent.BUTTON_DPAD_UP:
           movingUp = pressed;
        case JoystickEvent.BUTTON_DPAD_DOWN:
           movingDown = pressed;
        case JoystickEvent.BUTTON_DPAD_LEFT:
           movingLeft = pressed;
        case JoystickEvent.BUTTON_DPAD_RIGHT:
           movingRight = pressed;
        case JoystickEvent.BUTTON_A:
           //
        case JoystickEvent.BUTTON_B:
           //
        case JoystickEvent.BUTTON_X:
           //
        case JoystickEvent.BUTTON_Y:
           //
        case JoystickEvent.BUTTON_BACK:
           //
        case JoystickEvent.BUTTON_GUIDE:
           //
        case JoystickEvent.BUTTON_START:
           //
        case JoystickEvent.BUTTON_LEFTSTICK:
           //
        case JoystickEvent.BUTTON_RIGHTSTICK:
           //
        case JoystickEvent.BUTTON_LEFTSHOULDER:
           //
        case JoystickEvent.BUTTON_RIGHTSHOULDER:
           //
    }
}


	private function this_onEnterFrame (event:Event):Void {
		
        if (movingDown || movingDownAxis) {
			
			Logo.y += 5;
			
		}
		
        if (movingLeft || movingLeftAxis) {
			
			Logo.x -= 5;
			
		}
		
        if (movingRight || movingRightAxis) {
			
			Logo.x += 5;
			
		}
		
        if (movingUp || movingUpAxis) {
			
			Logo.y -= 5;
			
		}
		
	}
	
	
}
