import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.Shape;
import nme.events.Event;
import nme.events.JoystickEvent;
import nme.Assets;
import nme.Lib;
import nme.ui.Keyboard;
import haxe.ds.IntMap;
import nme.geom.ColorTransform;

class Main extends Sprite {
    
    
    private var Logo:Sprite;

    static private inline var MAX_USERS:Int = 4;

    private var userHatPosition:Array<Array<Int>>; //records x,y directions, either -1, 0 or 1
    private var userAxisPosition:Array<Array<Int>>; //records x,y directions, either -1, 0 or 1

    private var userDisplay:Array<Sprite>;
    private var userDisplayButton:Array<Array<Sprite>>;
    private var red:ColorTransform;
    private var gray:ColorTransform;
    private var blue:ColorTransform;
    private var green:ColorTransform;
    private var orange:ColorTransform;


    static private inline var PLAYER1:Int = 0;
    static private inline var PLAYER2:Int = 1;
    static private inline var PLAYER3:Int = 2;
    static private inline var PLAYER4:Int = 3;
    static private inline var JOYSTICK_NOT_ASIGNED:Int = -1;
    static private inline var INVALID_ID:Int = -1;
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

        userDisplay = new Array<Sprite>();
        userDisplayButton = new Array<Array<Sprite>>();
        red = new ColorTransform(1,0,0);
        gray = new ColorTransform(0.8,0.8,0.8);
        blue = new ColorTransform(0,0,1);
        green = new ColorTransform(0,1,0);
        orange = new ColorTransform(1,0.5,0.3);

        userHatPosition = new Array<Array<Int>>();
        userAxisPosition = new Array<Array<Int>>();

        for(userID in 0...MAX_USERS)
        {
          userHatPosition[userID] = new Array<Int>();
          userAxisPosition[userID] = new Array<Int>();

          userDisplay[userID] = new Sprite();
          addChild(userDisplay[userID]);

          userDisplay[userID].x = (userID%2==0)?50:450;
          userDisplay[userID].y = (userID<2)?50:350;

          userDisplayButton[userID] = new Array<Sprite>();

          createCircle(userID,JoystickEvent.BUTTON_A, 7, 4);
          createCircle(userID,JoystickEvent.BUTTON_B, 8, 3);
          createCircle(userID,JoystickEvent.BUTTON_X, 6, 3);
          createCircle(userID,JoystickEvent.BUTTON_Y, 7, 2);

          createCircle(userID,JoystickEvent.BUTTON_BACK, 3, 5);
          (userDisplayButton[userID])[JoystickEvent.BUTTON_BACK].scaleX = 0.6;
          (userDisplayButton[userID])[JoystickEvent.BUTTON_BACK].scaleY = 0.6;
          createCircle(userID,JoystickEvent.BUTTON_GUIDE, 4, 3);
          (userDisplayButton[userID])[JoystickEvent.BUTTON_GUIDE].scaleX = 0.6;
          (userDisplayButton[userID])[JoystickEvent.BUTTON_GUIDE].scaleY = 0.6;
          createCircle(userID,JoystickEvent.BUTTON_START, 5, 5);
          (userDisplayButton[userID])[JoystickEvent.BUTTON_START].scaleX = 0.6;
          (userDisplayButton[userID])[JoystickEvent.BUTTON_START].scaleY = 0.6;

          createCircle(userID,JoystickEvent.BUTTON_LEFTSTICK, 1, 6);
          createCircle(userID,JoystickEvent.BUTTON_RIGHTSTICK, 7, 6);

          createCircle(userID,JoystickEvent.BUTTON_LEFTSHOULDER, 0, 1);
          (userDisplayButton[userID])[JoystickEvent.BUTTON_LEFTSHOULDER].scaleY = 0.6;
          createCircle(userID,JoystickEvent.BUTTON_RIGHTSHOULDER, 8, 1);
          (userDisplayButton[userID])[JoystickEvent.BUTTON_RIGHTSHOULDER].scaleY = 0.6;

          createCircle(userID, 11/*JoystickEvent.BUTTON_DPAD_UP*/, 1, 2);
          createCircle(userID, 12 /*JoystickEvent.BUTTON_DPAD_DOWN*/, 1, 4);
          createCircle(userID, 13 /*JoystickEvent.BUTTON_DPAD_LEFT*/, 0, 3);
          createCircle(userID, 14 /*JoystickEvent.BUTTON_DPAD_RIGHT*/, 2, 3);

          //this circle indicates if user has joystick with green
          createCircle(userID,15, 4, 0);
          (userDisplayButton[userID])[15].scaleX = 2.0;

          //these are for indicating the Axis
          createCircle(userID,16, 1, 7);
          (userDisplayButton[userID])[16].scaleY = 0.6;
          createCircle(userID,17, 1, 7);
          (userDisplayButton[userID])[17].scaleX = 0.6;

          createCircle(userID,18, 7, 7);
          (userDisplayButton[userID])[18].scaleY = 0.6;
          createCircle(userID,19, 7, 7);
          (userDisplayButton[userID])[19].scaleX = 0.6;

          createCircle(userID,20, 0, 0);
          (userDisplayButton[userID])[20].scaleY = 0.6;
          createCircle(userID,21, 8, 0);
          (userDisplayButton[userID])[21].scaleY = 0.6;

        }
        
        Lib.current.stage.addEventListener (Event.ENTER_FRAME, this_onEnterFrame);

        Lib.current.stage.addEventListener (JoystickEvent.BUTTON_DOWN, onJoystickButtonDown);
        Lib.current.stage.addEventListener (JoystickEvent.BUTTON_UP, onJoystickButtonUp);
        Lib.current.stage.addEventListener (JoystickEvent.AXIS_MOVE, onJoystickAxisMove);
        Lib.current.stage.addEventListener (JoystickEvent.HAT_MOVE, onJoystickHatMove);
        Lib.current.stage.addEventListener (JoystickEvent.DEVICE_ADDED, onJoystickDeviceAdded);
        Lib.current.stage.addEventListener (JoystickEvent.DEVICE_REMOVED, onJoystickDeviceRemoved);
        
    }

    private function createCircle(userID:Int, buttonId:Int, inX:Int, inY:Int):Void
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
        circle.transform.colorTransform = gray;

        var container = new Sprite();
        container.x = inX*radius*1.5;
        container.y = inY*radius*1.5;
        userDisplay[userID].addChild(container);
        container.addChild(circle);
        (userDisplayButton[userID])[buttonId] = container;
    }

    private function onJoystickButtonUp( e:JoystickEvent ):Void
    {
       //trace(e);
       onJoystickButton(e, false);
    }

    private function onJoystickButtonDown( e:JoystickEvent ):Void
    {
       //trace(e);
       onJoystickButton(e, true);
    }

    private function onJoystickButton( e:JoystickEvent, pressed:Bool ):Void
    {
        //trace(e);

        var player = e.user;
        if(player<MAX_USERS)
        {
          //color button
          //if(e.id!=JoystickEvent.BUTTON_GUIDE)
          (userDisplayButton[player])[e.id].transform.colorTransform = pressed? red : gray; 
          switch(e.id)
          {
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
          trace("No player for this joystick");
        }
    }

    private function onJoystickHatMove( e:JoystickEvent ):Void
    {
        //trace(e); 
        var player = e.user;
        if(player<MAX_USERS)
        {
          (userHatPosition[player])[_X] = Std.int(e.x);
          (userHatPosition[player])[_Y] = Std.int(e.y);

          (userDisplayButton[player])[11/*UP*/].transform.colorTransform = e.y>0? orange : gray; 
          (userDisplayButton[player])[12 /*DOWN*/].transform.colorTransform = e.y<0? orange : gray; 
          (userDisplayButton[player])[13 /*LEFT*/].transform.colorTransform = e.x<0? orange : gray; 
          (userDisplayButton[player])[14 /*RIGHT*/].transform.colorTransform = e.x>0? orange : gray; 
        }
    }

    private function onJoystickAxisMove( e:JoystickEvent ):Void
    {
        //trace(e); 

        var player = e.user;
        if(player<MAX_USERS)
        {
          switch(e.id)
          {
              case JoystickEvent.AXIS_LEFTX:
                (userAxisPosition[player])[_X] = (e.value > 0.5 ? 1 : e.value < -0.5 ? -1 : 0);
                (userDisplayButton[player])[16].transform.colorTransform  = (e.value > 0.5 ? red : e.value < -0.5 ? blue : gray);
              case JoystickEvent.AXIS_LEFTY:
                (userAxisPosition[player])[_Y] = (e.value > 0.5 ? -1 : e.value < -0.5 ? 1 : 0);
                (userDisplayButton[player])[17].transform.colorTransform  = (e.value > 0.5 ? red : e.value < -0.5 ? blue : gray);
              case JoystickEvent.AXIS_RIGHTX:
                 (userDisplayButton[player])[18].transform.colorTransform  = (e.value > 0.5 ? red : e.value < -0.5 ? blue : gray);
              case JoystickEvent.AXIS_RIGHTY:
                 (userDisplayButton[player])[19].transform.colorTransform  = (e.value > 0.5 ? red : e.value < -0.5 ? blue : gray);
              case JoystickEvent.AXIS_TRIGGERLEFT:
              //note: triggers have value range 0 (not pressed) to 1 (pressed)
              //some controllers are not analog
                (userDisplayButton[player])[20].transform.colorTransform  = e.value > 0.5 ? red : gray; 
              case JoystickEvent.AXIS_TRIGGERRIGHT:
                (userDisplayButton[player])[21].transform.colorTransform  = e.value > 0.5 ? red : gray; 
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
       //check if already added
       var  player = e.user;
       if(player >= MAX_USERS)
       {
         trace("too many game controllers added");
         return;
       }
       //assign to user
       (userDisplayButton[player])[15].transform.colorTransform = green; 
    }

    private function onJoystickDeviceRemoved( e:JoystickEvent ):Void
    {
       //trace(e);
       (userDisplayButton[e.user])[15].transform.colorTransform = gray;
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
