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

class Main extends Sprite {
    
    
    private var Logo:Sprite;

    static public inline var MAX_USERS:Int = 4;

    private var userHatPosition:Array<Array<Int>>; //records x,y directions, either -1, 0 or 1
    private var userAxisPosition:Array<Array<Int>>;
    private var userDisplays:Array<GamePadDisplay>;

    static private inline var _X:Int = 0;
    static private inline var _Y:Int = 1;

    public function new () {
        
        super ();
        
        Logo = new Sprite ();
        Logo.addChild (new Bitmap (Assets.getBitmapData ("assets/nme.png")));
        Logo.x = 100;
        Logo.y = 100;
        Logo.buttonMode = true;
        addChild (Logo);

        userDisplays = new Array<GamePadDisplay>();

        userHatPosition = new Array<Array<Int>>();
        userAxisPosition = new Array<Array<Int>>();

        for(userID in 0...MAX_USERS)
        {
          userHatPosition[userID] = new Array<Int>();
          userAxisPosition[userID] = new Array<Int>();

          userDisplays[userID] = new GamePadDisplay();
          addChild(userDisplays[userID]);

          userDisplays[userID].x = ( userID%2 ==0 )? 50 : 450;
          userDisplays[userID].y = ( userID<2 )? 50 : 350;
        }
        
        Lib.current.stage.addEventListener (Event.ENTER_FRAME, this_onEnterFrame);

        //These events return unmapped (raw) values from all input devices 
        //including joysticks and unsupported/supported gamepads 
        //Lib.current.stage.addEventListener (JoystickEvent.BUTTON_DOWN, onJoystickButtonDown);
        //Lib.current.stage.addEventListener (JoystickEvent.BUTTON_UP, onJoystickButtonUp);
        //Lib.current.stage.addEventListener (JoystickEvent.AXIS_MOVE, onJoystickAxisMove);
        //Lib.current.stage.addEventListener (JoystickEvent.BALL_MOVE, onJoystickAxisMove);

        //These event return mapped values of suppoorted gamepads 
        //Check id values with GamepadAxis and GamedButton 
        Lib.current.stage.addEventListener (JoystickEvent.GAMECONTROLLER_BUTTON_DOWN, onControllerButtonDown);
        Lib.current.stage.addEventListener (JoystickEvent.GAMECONTROLLER_BUTTON_UP, onControllerButtonUp);
        Lib.current.stage.addEventListener (JoystickEvent.GAMECONTROLLER_AXIS_MOVE, onControllerAxisMove);

        //These events are for both joysticks and gamepad devices
        Lib.current.stage.addEventListener (JoystickEvent.HAT_MOVE, onJoystickHatMove);
        Lib.current.stage.addEventListener (JoystickEvent.DEVICE_ADDED, onJoystickDeviceAdded);
        Lib.current.stage.addEventListener (JoystickEvent.DEVICE_REMOVED, onJoystickDeviceRemoved);
    }



    private function onControllerButtonUp( e:JoystickEvent ):Void
    {
       //trace(e);
       onControllerButton(e, false);
    }

    private function onControllerButtonDown( e:JoystickEvent ):Void
    {
       //trace(e);
       onControllerButton(e, true);
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
              userDisplays[player].setColor( 17, (e.y > 0.5 ? red : e.x < -0.5 ? blue : gray));
            case GamepadAxis.RIGHT:
              userDisplays[player].setColor( 18, (e.x > 0.5 ? red : e.x < -0.5 ? blue : gray));
              userDisplays[player].setColor( 19, (e.x > 0.5 ? red : e.y < -0.5 ? blue : gray));
            case GamepadAxis.TRIGGER:
              //note: triggers have value range 0 (not pressed) to 1 (pressed)
              //some controllers are not analog
              userDisplays[player].setColor( 20, (e.x > 0.5 ? red : gray));
              userDisplays[player].setColor( 21, (e.x > 0.5 ? red : gray)); 
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

    private function this_onEnterFrame (event:Event):Void
    {
      
       var player = 0;

       var movingUp:Bool    = ( (userHatPosition[player])[_Y] > 0);
       var movingDown:Bool  = ( (userHatPosition[player])[_Y] < 0);
       var movingLeft:Bool  = ( (userHatPosition[player])[_X] < 0); 
       var movingRight:Bool = ( (userHatPosition[player])[_X] > 0);

       movingUp    = movingUp    || ( (userAxisPosition[player])[_Y] > 0);
       movingDown  = movingDown  || ( (userAxisPosition[player])[_Y] < 0);
       movingLeft  = movingLeft  || ( (userAxisPosition[player])[_X] < 0); 
       movingRight = movingRight || ( (userAxisPosition[player])[_X] > 0);

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
