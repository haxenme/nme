import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.Shape;
import nme.events.Event;
import nme.events.JoystickEvent;
import nme.Assets;
import nme.Lib;
import nme.ui.Keyboard;
import nme.ui.GamepadButton;
import nme.ui.GamepadAxis;
import haxe.ds.IntMap;
import nme.geom.ColorTransform;

#if NME_GAMEINPUT_API
import nme.events.GameInputEvent;
import nme.ui.GameInput;
import nme.ui.GameInputDevice;
import nme.ui.GameInputControl;
#end

class Main extends Sprite {
        
    private var Logo:Sprite;

    static public inline var MAX_USERS:Int = 4;
    private var userDisplays:Array<GamePadDisplay>;
    static private inline var _X:Int = 0;
    static private inline var _Y:Int = 1;

#if NME_JOYSTICK_API
    private var userHatPosition:Array<Array<Int>>; //records x,y directions, either -1, 0 or 1
    private var userAxisPosition:Array<Array<Int>>;
#end

#if NME_GAMEINPUT_API
    private var gameInput:GameInput = new GameInput();
    private var movingUpControl:GameInputControl;
    private var movingDownControl:GameInputControl;
    private var movingLeftControl:GameInputControl;
    private var movingRightControl:GameInputControl;
    private var movingAxis0Control:GameInputControl;
    private var movingAxis1Control:GameInputControl;
#end

    public function new () {
        
        super ();
        
        userDisplays = new Array<GamePadDisplay>();

#if NME_JOYSTICK_API
        userHatPosition = new Array<Array<Int>>();
        userAxisPosition = new Array<Array<Int>>();
#end

        for(userID in 0...MAX_USERS)
        {

#if NME_JOYSTICK_API
          userHatPosition[userID] = new Array<Int>();
          userAxisPosition[userID] = new Array<Int>();
#end

          userDisplays[userID] = new GamePadDisplay();
          addChild(userDisplays[userID]);
          userDisplays[userID].x = ( userID%2 ==0 )? 50 : 450;
          userDisplays[userID].y = ( userID<2 )? 50 : 350;
        }

        Logo = new Sprite ();
        Logo.addChild (new Bitmap (Assets.getBitmapData ("assets/nme.png")));
        Logo.x = 375;
        Logo.y = 275;
        Logo.buttonMode = true;
        addChild (Logo);
        
        Lib.current.stage.addEventListener (Event.ENTER_FRAME, this_onEnterFrame);

#if NME_JOYSTICK_API
        //These events return unmapped (raw) values from joysticks and unsupported/supported gamepads
        //and mapped values of suppoorted gamepads that match values in GamepadAxis and GamedButton
        //(check "isGamePad" in event) 
        Lib.current.stage.addEventListener (JoystickEvent.BUTTON_DOWN, onJoystickButtonDown);
        Lib.current.stage.addEventListener (JoystickEvent.BUTTON_UP, onJoystickButtonUp);
        Lib.current.stage.addEventListener (JoystickEvent.AXIS_MOVE, onJoystickAxisMove);
        //Lib.current.stage.addEventListener (JoystickEvent.BALL_MOVE, onJoystickAxisMove); //not used

        //These events are for both joysticks and gamepad devices
        Lib.current.stage.addEventListener (JoystickEvent.HAT_MOVE, onJoystickHatMove);
        Lib.current.stage.addEventListener (JoystickEvent.DEVICE_ADDED, onJoystickDeviceAdded);
        Lib.current.stage.addEventListener (JoystickEvent.DEVICE_REMOVED, onJoystickDeviceRemoved);
#end

#if NME_GAMEINPUT_API
        gameInput.addEventListener (GameInputEvent.DEVICE_ADDED, gameInput_onDeviceAdded);
        gameInput.addEventListener (GameInputEvent.DEVICE_REMOVED, gameInput_onDeviceRemoved);
        for (i in 0...GameInput.numDevices)
           addGamepad(GameInput.getDeviceAt(i));
#end
    }

#if NME_GAMEINPUT_API
    private function addGamepad(device:GameInputDevice)
    {
       if(device==null)
        return;

       device.enabled = true;
    
       var player:Int=findGamepadIndex(device);
       if(player<0 || player>=MAX_USERS)
        return;

       //userDisplays[player].setColor( 15, event.isGamePad ? GamePadDisplay.green : GamePadDisplay.orange);
       userDisplays[player].setColor( 15, GamePadDisplay.green);

       if(player==0)
          setControls(device);
    }

    private function findGamepadIndex(device:GameInputDevice):Int
    {
       if (device == null)
          return - 1;
    
       for (i in 0...GameInput.numDevices)
          if (GameInput.getDeviceAt(i) == device)
             return i;

       return -1;
    }

    private function gameInput_onDeviceAdded (event:GameInputEvent):Void
    {
       addGamepad(event.device);
    }
  
  
    private function gameInput_onDeviceRemoved (event:GameInputEvent):Void {
    
       var device = event.device;
       device.enabled = false;

       if(device == GameInput.getDeviceAt(0))
       {
          movingUpControl    = null;
          movingDownControl  = null;
          movingLeftControl  = null;
          movingRightControl = null;
       }    
       device = GameInput.getDeviceAt(0);
       if(null != device)
          setControls(device);
 
       userDisplays[3].setColor( 15, GamePadDisplay.gray);
    }
  

    public function setControls(device:GameInputDevice)
    {
    #if 0
          movingUpControl = device.getControlAt(6+GamepadButton.DPAD_UP);
          movingDownControl = device.getControlAt(6+GamepadButton.DPAD_DOWN);
          movingLeftControl = device.getControlAt(6+GamepadButton.DPAD_LEFT);
          movingRightControl = device.getControlAt(6+GamepadButton.DPAD_RIGHT);
    #else
          for(i in 0...device.numControls)
          {
             var control = device.getControlAt(i);
             var temp = control.id.split("_");
             if(temp[0]=="BUTTON")
             {
                var intId = Std.parseInt(temp[1]);
                switch(intId)
                {
                  case GamepadButton.DPAD_UP:    movingUpControl    = control;
                  case GamepadButton.DPAD_DOWN:  movingDownControl  = control;
                  case GamepadButton.DPAD_LEFT:  movingLeftControl  = control;
                  case GamepadButton.DPAD_RIGHT: movingRightControl = control;
                }
             }
             else if(temp[0]=="AXIS")
             {
                var intId = Std.parseInt(temp[1]);
                switch(intId)
                {
                  case 0:  movingAxis0Control    = control;
                  case 1:  movingAxis1Control    = control;
                }
             }
          }
    #end
    }
#end


#if NME_JOYSTICK_API
    private function onJoystickButtonUp( e:JoystickEvent ):Void
    {
       //trace(e);
       //if(e.isGamePad)
         onControllerButton(e, false);
    }

    private function onJoystickButtonDown( e:JoystickEvent ):Void
    {
       //trace(e);
       //if(e.isGamePad)
         onControllerButton(e, true);
    }

    private function onJoystickAxisMove( e:JoystickEvent ):Void
    {
       //if(e.isGamePad)
         onControllerAxisMove(e);
    }

    private function onControllerButton( e:JoystickEvent, pressed:Bool ):Void
    {
        //trace(e);
        var player = e.user;
        var buttonId = e.id;
        if(player<MAX_USERS)
        {
          switch(buttonId)
          {
              case GamepadButton.A:
                 //
              case GamepadButton.B:
                 //
              case GamepadButton.X:
                 //
              case GamepadButton.Y:
                 //
              case GamepadButton.BACK:
                 //
              case GamepadButton.GUIDE:
                 //
              case GamepadButton.START:
                 //
              case GamepadButton.LEFT_STICK:
                 //
              case GamepadButton.RIGHT_STICK:
                 //
              case GamepadButton.LEFT_SHOULDER:
                 //
              case GamepadButton.RIGHT_SHOULDER:
                 //
          }
          
          userDisplays[player].setColor(buttonId, pressed? GamePadDisplay.red : GamePadDisplay.gray);
        }
    }

    //Receives hat pairs. Check "x" and "y" values
    private function onJoystickHatMove( e:JoystickEvent ):Void
    {
        //trace(e); 
        var player = e.user;
        if(player<MAX_USERS)
        {
          (userHatPosition[player])[_X] = Std.int(e.x);
          (userHatPosition[player])[_Y] = Std.int(e.y);

          var orange = GamePadDisplay.orange;
          var gray = GamePadDisplay.gray;

          userDisplays[player].setColor( GamepadButton.DPAD_UP   , e.y>0? orange : gray);
          userDisplays[player].setColor( GamepadButton.DPAD_DOWN , e.y<0? orange : gray);
          userDisplays[player].setColor( GamepadButton.DPAD_LEFT , e.x<0? orange : gray);
          userDisplays[player].setColor( GamepadButton.DPAD_RIGHT, e.x>0? orange : gray);
        }
    }

    //Receives axis in pairs. Check "x" and "y" values with "id"
    private function onControllerAxisMove( e:JoystickEvent ):Void
    {
        //trace(e); 
        var red = GamePadDisplay.red;
        var blue = GamePadDisplay.blue;
        var gray = GamePadDisplay.gray;

        var player = e.user;
        if(player<MAX_USERS)
        {
          switch(e.id)
          {
            case GamepadAxis.LEFT:
              (userAxisPosition[player])[_X] = (e.x > 0.5 ? 1 : e.x < -0.5 ? -1 : 0);
              userDisplays[player].setColor( 16, (e.x > 0.5 ? red : e.x < -0.5 ? blue : gray));
              (userAxisPosition[player])[_Y] = (e.y > 0.5 ? -1 : e.y < -0.5 ? 1 : 0);
              userDisplays[player].setColor( 17, (e.y > 0.5 ? red : e.y < -0.5 ? blue : gray));
            case GamepadAxis.RIGHT:
              userDisplays[player].setColor( 18, (e.x > 0.5 ? red : e.x < -0.5 ? blue : gray));
              userDisplays[player].setColor( 19, (e.y > 0.5 ? red : e.y < -0.5 ? blue : gray));
            case GamepadAxis.TRIGGER:
              //note: triggers have value range 0 (not pressed) to 1 (pressed)
              //some controllers are not analog
              userDisplays[player].setColor( 20, (e.x > 0.5 ? red : gray));
              userDisplays[player].setColor( 21, (e.y > 0.5 ? red : gray)); 
          }
        }
        else
        {
          trace("No player for this joystick");
        }
    }

    private function onJoystickDeviceAdded( e:JoystickEvent ):Void
    {
       //trace(e);
       var  player = e.user;
       if(player < MAX_USERS)
         userDisplays[player].setColor( 15, e.isGamePad ? GamePadDisplay.green : GamePadDisplay.orange);
    }

    private function onJoystickDeviceRemoved( e:JoystickEvent ):Void
    {
       //trace(e);
       var  player = e.user;
       if(player < MAX_USERS)
         userDisplays[player].setColor( 15, GamePadDisplay.gray);
    }
#end

    private function this_onEnterFrame (event:Event):Void
    {
      
       var player = 0;
       var movingUp:Bool    = false;
       var movingDown:Bool  = false;
       var movingLeft:Bool  = false; 
       var movingRight:Bool = false;

#if NME_JOYSTICK_API
       movingUp    = ((userHatPosition[player])[_Y] > 0)  || ( (userAxisPosition[player])[_Y] > 0);
       movingDown  = ((userHatPosition[player])[_Y] < 0)  || ( (userAxisPosition[player])[_Y] < 0);
       movingLeft  = ((userHatPosition[player])[_X] < 0)  || ( (userAxisPosition[player])[_X] < 0); 
       movingRight = ((userHatPosition[player])[_X] > 0)  || ( (userAxisPosition[player])[_X] > 0);
#end

#if NME_GAMEINPUT_API
       //GameInput API
       movingUp    = movingUp    || ( movingUpControl    !=null && movingUpControl.value    > 0);
       movingDown  = movingDown  || ( movingDownControl  !=null && movingDownControl.value  > 0);
       movingLeft  = movingLeft  || ( movingLeftControl  !=null && movingLeftControl.value  > 0);
       movingRight = movingRight || ( movingRightControl !=null && movingRightControl.value > 0);

       movingUp    = movingUp    || ( movingAxis1Control !=null && movingAxis1Control.value < -0.5);
       movingDown  = movingDown  || ( movingAxis1Control !=null && movingAxis1Control.value > 0.5);
       movingLeft  = movingLeft  || ( movingAxis0Control !=null && movingAxis0Control.value < -0.5);
       movingRight = movingRight || ( movingAxis0Control !=null && movingAxis0Control.value > 0.5);
#end

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


class GamePadDisplay extends Sprite 
{

    public var userDisplayButton:Array<Sprite>;
    public var bg:Sprite;
    static public var red:ColorTransform = new ColorTransform(1,0,0);
    static public var gray:ColorTransform = new ColorTransform(0.3,0.3,0.3);
    static public var blue:ColorTransform = new ColorTransform(0,0,1);
    static public var green:ColorTransform = new ColorTransform(0,1,0);
    static public var orange:ColorTransform = new ColorTransform(1,0.5,0.3);

    public function new()
    {
        super();
        userDisplayButton = new Array<Sprite>();
        bg = new Sprite();
        bg.addChild (new Bitmap (Assets.getBitmapData ("assets/sdlcontroller.png")));
        addChild(bg);
        setGUI();
    }

    public function setGUI():Void
    {
        createCircle(GamepadButton.A, 286, 131);
        createCircle(GamepadButton.B, 318, 107);
        createCircle(GamepadButton.X, 257, 109);
        createCircle(GamepadButton.Y, 288, 85);

        createCircle(GamepadButton.BACK, 139, 110, 0.6, 0.6);
        createCircle(GamepadButton.GUIDE, 178, 110, 0.6, 0.6);
        createCircle(GamepadButton.START, 218, 110, 0.6, 0.6);

        createCircle(GamepadButton.LEFT_STICK, 66, 125);
        createCircle(GamepadButton.RIGHT_STICK, 230, 180);
        createCircle(GamepadButton.LEFT_SHOULDER, 64, 35, 1.0, 0.6);
        createCircle(GamepadButton.RIGHT_SHOULDER, 298, 35, 1.0, 0.6);

        createCircle(GamepadButton.DPAD_UP, 118, 137);
        createCircle(GamepadButton.DPAD_DOWN, 118, 191);
        createCircle(GamepadButton.DPAD_LEFT, 90, 165);
        createCircle(GamepadButton.DPAD_RIGHT, 151, 165);

        //this circle indicates if user has supported gamepad with green
        //or a joystick/unsupported gamepad with orange
        createCircle(15, 173, 52, 2.0);

        //these are for indicating the Axis
        createCircle(16, 54, 98, 2.0, 0.6);
        createCircle(17, 64, 88, 0.6, 2.0);
        createCircle(18, 223, 156, 2.0, 0.6);
        createCircle(19, 233, 146, 0.6, 2.0);
        createCircle(20, 79, 2, 1.0, 0.6);
        createCircle(21, 274, 2, 1.0, 0.6);
    }

    public function createCircle(buttonId:Int, inX:Int, inY:Int, scaleX:Float=1.0, scaleY:Float=1.0):Void
    {
        //add display
        var circleColor:UInt = 0xFFFFFF;
        var radius:Float = 12;
        var circle:nme.display.Shape = new nme.display.Shape();
        circle.graphics.beginFill(circleColor);
        circle.graphics.drawCircle(radius, radius, radius);
        circle.graphics.endFill();
        circle.x = -radius/2;
        circle.y = -radius/2;
        //circle.transform.colorTransform = gray;

        var container = new Sprite();
        container.x = inX;
        container.y = inY;
        container.scaleX = scaleX;
        container.scaleY = scaleY;
        addChild(container);
        container.addChild(circle);
        userDisplayButton[buttonId] = container;
        setColor(buttonId, gray);
    }

    public function setColor(buttonId:Int, transform:ColorTransform):Void
    {
      userDisplayButton[buttonId].transform.colorTransform  = transform;
    }
  }
