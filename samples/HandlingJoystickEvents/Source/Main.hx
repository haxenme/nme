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
    private var userAxisPosition:Array<Array<Int>>; //records x,y directions, either -1, 0 or 1

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

        GamePadDisplay.userDisplay = new Array<Sprite>();
        GamePadDisplay.userDisplayButton = new Array<Array<Sprite>>();
        GamePadDisplay.red = new ColorTransform(1,0,0);
        GamePadDisplay.gray = new ColorTransform(0.8,0.8,0.8);
        GamePadDisplay.blue = new ColorTransform(0,0,1);
        GamePadDisplay.green = new ColorTransform(0,1,0);
        GamePadDisplay.orange = new ColorTransform(1,0.5,0.3);

        userHatPosition = new Array<Array<Int>>();
        userAxisPosition = new Array<Array<Int>>();

        for(userID in 0...MAX_USERS)
        {
          userHatPosition[userID] = new Array<Int>();
          userAxisPosition[userID] = new Array<Int>();

          GamePadDisplay.userDisplay[userID] = new Sprite();
          addChild(GamePadDisplay.userDisplay[userID]);

          GamePadDisplay.userDisplay[userID].x = ( userID%2 ==0 )? 50 : 450;
          GamePadDisplay.userDisplay[userID].y = ( userID<2 )? 50 : 350;

          GamePadDisplay.userDisplayButton[userID] = new Array<Sprite>();

          GamePadDisplay.setGUI(userID);
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
          GamePadDisplay.setColor(player, buttonId, pressed? GamePadDisplay.red : GamePadDisplay.gray);
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

          GamePadDisplay.setColor(player, GamepadButton.DPAD_UP   , e.y>0? orange : gray);
          GamePadDisplay.setColor(player, GamepadButton.DPAD_DOWN , e.y<0? orange : gray);
          GamePadDisplay.setColor(player, GamepadButton.DPAD_LEFT , e.x<0? orange : gray);
          GamePadDisplay.setColor(player, GamepadButton.DPAD_RIGHT, e.x>0? orange : gray);
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
              GamePadDisplay.setColor(player, 16, (e.x > 0.5 ? red : e.x < -0.5 ? blue : gray));
              (userAxisPosition[player])[_Y] = (e.y > 0.5 ? -1 : e.y < -0.5 ? 1 : 0);
              GamePadDisplay.setColor(player, 17, (e.y > 0.5 ? red : e.x < -0.5 ? blue : gray));
            case GamepadAxis.RIGHT:
              GamePadDisplay.setColor(player, 18, (e.x > 0.5 ? red : e.x < -0.5 ? blue : gray));
              GamePadDisplay.setColor(player, 19, (e.x > 0.5 ? red : e.y < -0.5 ? blue : gray));
            case GamepadAxis.TRIGGER:
              //note: triggers have value range 0 (not pressed) to 1 (pressed)
              //some controllers are not analog
              GamePadDisplay.setColor(player, 20, (e.x > 0.5 ? red : gray));
              GamePadDisplay.setColor(player, 21, (e.x > 0.5 ? red : gray)); 
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
         GamePadDisplay.setColor(player, 15, e.isGamePad ? GamePadDisplay.green : GamePadDisplay.orange);
    }

    private function onJoystickDeviceRemoved( e:JoystickEvent ):Void
    {
       //trace(e);
       var  player = e.user;
       if(player < MAX_USERS)
         GamePadDisplay.setColor(player, 15, GamePadDisplay.gray);
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


class GamePadDisplay extends Sprite {

    static public var userDisplay:Array<Sprite>;
    static public var userDisplayButton:Array<Array<Sprite>>;
    static public var red:ColorTransform;
    static public var gray:ColorTransform;
    static public var blue:ColorTransform;
    static public var green:ColorTransform;
    static public var orange:ColorTransform;

    static public function setGUI( userID:Int ):Void
    {
        createCircle(userID,GamepadButton.A, 7, 4);
        createCircle(userID,GamepadButton.B, 8, 3);
        createCircle(userID,GamepadButton.X, 6, 3);
        createCircle(userID,GamepadButton.Y, 7, 2);

        createCircle(userID,GamepadButton.BACK, 3, 5, 0.6, 0.6);
        createCircle(userID,GamepadButton.GUIDE, 4, 3, 0.6, 0.6);
        createCircle(userID,GamepadButton.START, 5, 5, 0.6, 0.6);

        createCircle(userID, GamepadButton.LEFT_STICK, 1, 6);
        createCircle(userID, GamepadButton.RIGHT_STICK, 7, 6);

        createCircle(userID, GamepadButton.LEFT_SHOULDER, 0, 1, 1.0, 0.6);
        createCircle(userID, GamepadButton.RIGHT_SHOULDER, 8, 1, 1.0, 0.6);

        createCircle(userID, GamepadButton.DPAD_UP, 1, 2);
        createCircle(userID, GamepadButton.DPAD_DOWN, 1, 4);
        createCircle(userID, GamepadButton.DPAD_LEFT, 0, 3);
        createCircle(userID, GamepadButton.DPAD_RIGHT, 2, 3);

        //this circle indicates if user has supported gamepad with green
        //or a joystick/unsupported gamepad with orange
        createCircle(userID, 15, 4, 0, 2.0);

        //these are for indicating the Axis
        createCircle(userID, 16, 1, 7, 1.0, 0.6);
        createCircle(userID, 17, 1, 7, 0.6);
        createCircle(userID, 18, 7, 7, 1.0, 0.6);
        createCircle(userID, 19, 7, 7, 0.6);
        createCircle(userID, 20, 0, 0, 1.0, 0.6);
        createCircle(userID, 21, 8, 0, 1.0, 0.6);
    }

    static public function createCircle(userID:Int, buttonId:Int, inX:Int, inY:Int, scaleX:Float=1.0, scaleY:Float=1.0):Void
    {
        //add display
        var circleColor:UInt = 0xFFFFFF;
        var radius:Float = 20;
        var circle:nme.display.Shape = new nme.display.Shape();
        circle.graphics.beginFill(circleColor);
        circle.graphics.drawCircle(radius, radius, radius);
        circle.graphics.endFill();
        circle.x = -radius/2;
        circle.y = -radius/2;
        //circle.transform.colorTransform = gray;

        var container = new Sprite();
        container.x = inX*radius*1.5;
        container.y = inY*radius*1.5;
        container.scaleX = scaleX;
        container.scaleY = scaleY;
        userDisplay[userID].addChild(container);
        container.addChild(circle);
        (userDisplayButton[userID])[buttonId] = container;
        setColor(userID, buttonId, gray);
    }

    static public function setColor(userID:Int, buttonId:Int, transform:ColorTransform):Void
    {
      (GamePadDisplay.userDisplayButton[userID])[buttonId].transform.colorTransform  = transform;
    }
  }
