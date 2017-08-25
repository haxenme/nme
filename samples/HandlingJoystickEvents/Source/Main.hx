import nme.display.Bitmap;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.JoystickEvent;
import nme.Assets;
import nme.Lib;
import nme.ui.Keyboard;
import haxe.ds.IntMap;


class Main extends Sprite {
    
    
    private var Logo:Sprite;
    
    private var movingDownPad:Bool;
    private var movingLeftPad:Bool;
    private var movingRightPad:Bool;
    private var movingUpPad:Bool;

    private var movingDownAxis:Bool;
    private var movingLeftAxis:Bool;
    private var movingRightAxis:Bool;
    private var movingUpAxis:Bool;

    //These are useful for asigning joysticks to players on a local multiplayer game
    //assigning a connected Joystick device to a userID
    static private inline var MAX_PLAYERS:Int = 4;
    private var userIDstack:Array<Int>; //Stores the available userIDs, from 0 to MAX_PLAYERS-1
    private var userJoysickDevice:IntMap<Int>; //Map usersIDs to Joystick devices ids

    static private inline var PLAYER1:Int = 0;
    static private inline var PLAYER2:Int = 1;
    static private inline var PLAYER3:Int = 2;
    static private inline var PLAYER4:Int = 3;
    static private inline var JOYSTICK_NOT_ASIGNED:Int = -1;
    static private inline var INVALID_ID:Int = -1;

    public function new () {
        
        super ();
        
        Logo = new Sprite ();
        Logo.addChild (new Bitmap (Assets.getBitmapData ("assets/nme.png")));
        Logo.x = 100;
        Logo.y = 100;
        Logo.buttonMode = true;
        addChild (Logo);

        //Init user-joystick stack and map
        userIDstack = [];
        userJoysickDevice = new IntMap<Int>();
        for(userID in 0...MAX_PLAYERS)
        {
          userIDstack.push(userID);
          userJoysickDevice.set(userID,JOYSTICK_NOT_ASIGNED);
        }
        
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

    private function onJoystickButton( e:JoystickEvent, pressed:Bool ):Void
    {
        trace(e);
        //move by player
        if(e.device==userJoysickDevice.get(PLAYER1) || e.device==userJoysickDevice.get(PLAYER2))
        {
          switch(e.id)
          {
              case JoystickEvent.BUTTON_DPAD_UP:
                 movingUpPad = pressed;
              case JoystickEvent.BUTTON_DPAD_DOWN:
                 movingDownPad = pressed;
              case JoystickEvent.BUTTON_DPAD_LEFT:
                 movingLeftPad = pressed;
              case JoystickEvent.BUTTON_DPAD_RIGHT:
                 movingRightPad = pressed;
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
        else
        {
          trace("No button accion for this player");
        }
    }

    private function onJoystickAxisMove( e:JoystickEvent ):Void
    {
        trace(e); 
        //move by player
        if(e.device==userJoysickDevice.get(PLAYER1) || e.device==userJoysickDevice.get(PLAYER2))
        {
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
              //some controllers are not analog
              case JoystickEvent.AXIS_TRIGGERRIGHT:
              //
          }
        }
        else
        {
          trace("No axis action for this player");
        }
    }

    private function onJoystickDeviceAdded( e:JoystickEvent ):Void
    {
       trace(e);
       //check if already added
       for (userID in 0...MAX_PLAYERS)
       {
        var device:Int =  userJoysickDevice.get(userID);
        if(device == e.device)
        {
          trace("added joystick already asigned to user: "+userID+"   "+userJoysickDevice);
          return;
        }
       }
       //assign to user
       var userID = getUserID();
       if(userID != INVALID_ID)
       {
         userJoysickDevice.set(userID,e.device);
         trace("Joystick "+e.device+" assigned to user: "+userID+". Map: "+userJoysickDevice);
       }
    }

    private function onJoystickDeviceRemoved( e:JoystickEvent ):Void
    {
       trace(e);
       for (userID in 0...MAX_PLAYERS)
       {
        var device:Int =  userJoysickDevice.get(userID);
        if(device == e.device)
        {
          releaseUserID(userID);
          userJoysickDevice.set(userID,JOYSTICK_NOT_ASIGNED);
          trace("Joystick "+e.device+" removed from user: "+userID+". Map: "+userJoysickDevice);
          break;
        }
       }
    }

    private function getUserID()
    {
      if(userIDstack.length <= 0)
      {
        trace("Too much joysticks: MAX_PLAYERS ("+ MAX_PLAYERS +") already logged");
        //you could save this id to assign when other joystick disconects
        return INVALID_ID;
      }
      return userIDstack.shift();
    }

    private function releaseUserID( val:Int)
    {
      userIDstack.push( val );
      //keep ids in order
      userIDstack.sort(function(a, b) {
           if(a < b) return -1;
           else if(a > b) return 1;
           else return 0;
      });
    }

    private function this_onEnterFrame (event:Event):Void {
        
        if (movingDownPad || movingDownAxis) {
            
            Logo.y += 5;
            
        }
        
        if (movingLeftPad || movingLeftAxis) {
            
            Logo.x -= 5;
            
        }
        
        if (movingRightPad || movingRightAxis) {
            
            Logo.x += 5;
            
        }
        
        if (movingUpPad || movingUpAxis) {
            
            Logo.y -= 5;
            
        }
        
    }
    
    
}
