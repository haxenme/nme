/*
 * Copyright (c) 2006, Lee McColl Sylvester - www.designrealm.co.uk
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
 
package nme;

import nme.display.Graphics;

enum EventType
{
	et_noevent;
	et_active;
	et_keydown;
	et_keyup;
	et_mousemove;
	et_mousebutton_down;
	et_mousebutton_up;
	et_joystickmove;
	et_joystickball;
	et_joystickhat;
	et_joystickbutton;
	et_resize;
	et_quit;
	et_user;
	et_syswm;
}

enum MouseEventType
{
   met_Move;
   met_LeftUp;
   met_LeftDown;
   met_MiddleUp;
   met_MiddleDown;
   met_RightUp;
   met_RightDown;
   met_MouseWheelUp;
   met_MouseWheelDown;
}

typedef MouseEvent =
{
   var type : MouseEventType;
   var x : Int;
   var y : Int;
   var shift : Bool;
   var ctrl : Bool;
   var alt : Bool;
   var leftIsDown : Bool;
   var middleIsDown : Bool;
   var rightIsDown : Bool;
}

typedef KeyEvent =
{
   var isDown : Bool;
   // See nme.KeyCode ...
   var code : Int;
   var shift : Bool;
   var ctrl : Bool;
   var alt : Bool;
}


typedef MouseEventCallback = MouseEvent -> Void;
typedef MouseEventCallbackList = Array<MouseEventCallback>;

typedef KeyEventCallback = KeyEvent -> Void;
typedef KeyEventCallbackList = Array<KeyEventCallback>;

typedef UpdateCallback = Float -> Void;
typedef UpdateCallbackList = Array<UpdateCallback>;

typedef RenderCallback = Void -> Void;
typedef RenderCallbackList = Array<RenderCallback>;

class Manager
{
	static var __scr : Void;
	static var __evt : Dynamic;

	// Set this to something else if yo do not want it...
	static var closeKey = 27;
	static var pauseUpdates = KeyCode.F11;
	static var toggleQuality = KeyCode.F12;

	static var FULLSCREEN = 0x0001;
	static var OPENGL     = 0x0002;
	static var RESIZABLE  = 0x0004;

	static public var graphics(default,null):Graphics;
	static public var draw_quality(get_draw_quality,set_draw_quality):Int;

	public var mainLoopRunning:Bool;
	public var mouseEventCallbacks:MouseEventCallbackList;
	public var mouseClickCallbacks:MouseEventCallbackList;
	public var keyEventCallbacks:KeyEventCallbackList;
	public var updateCallbacks:UpdateCallbackList;
	public var renderCallbacks:RenderCallbackList;

	public var mPaused:Bool;

	public var tryQuitFunction: Void->Bool;

	private var timerStack : List < Timer > ;
	private var mT0 : Float;
	private var mFrameCount : Int;

	public function new( width : Int, height : Int, title : String, fullscreen : Bool, icon : String, ?opengl:Null<Bool>, ?resizable:Bool )
	{
		var flags = 0;
		if ( fullscreen!=null && fullscreen)
		   flags += FULLSCREEN;

		if ( opengl!=null && opengl)
		   flags += OPENGL;

      if ( resizable!=null && resizable)
         flags += RESIZABLE;

		if ( width < 100 || height < 20 ) return;
		__scr = nme_screen_init( width, height, untyped title.__s, flags, untyped icon.__s );
                graphics = new Graphics(__scr);
		mainLoopRunning = false;
		mouseEventCallbacks = new MouseEventCallbackList();
		mouseClickCallbacks = new MouseEventCallbackList();
		keyEventCallbacks = new KeyEventCallbackList();
		updateCallbacks = new UpdateCallbackList();
		renderCallbacks = new RenderCallbackList();
		tryQuitFunction = null;
		mPaused = false;
      mT0 = haxe.Timer.stamp();
      mFrameCount = 0;
	}

   public function OnResize(inW:Int, inH:Int)
   {
      __scr = nme_resize_surface(inW,inH);
      graphics.SetSurface(__scr);
   }



   // This function is optional - you can choose to do your own main loop, eg
   // samples/2-Blox-Game.  You can also use extend the "GameBase" class
   // and override the functions if you like.
   public function mainLoop()
   {
      mainLoopRunning = true;
      var left = false;
      var last_update = 0.0;

      while(mainLoopRunning)
      {
         var type:nme.EventType;
         do
         {
            type = nextEvent();
            switch type
            {
               case et_quit:
                  tryQuit();
               case et_keydown:
                  if (lastKey() == closeKey)
                     tryQuit();
                  else
                  {
                     fireKeyEvent(true);
                  }
               case et_keyup:
                  fireKeyEvent(false);

               case et_mousebutton_down:
                  switch(Reflect.field( __evt, "button" ))
                  {
                     case 1 : fireMouseEvent( met_LeftDown );
                     case 2 : fireMouseEvent( met_MiddleDown );
                     case 3 : fireMouseEvent( met_RightDown );
                     case 4 : fireMouseEvent( met_MouseWheelUp );
                     case 5 : fireMouseEvent( met_MouseWheelDown );
                  }
               case et_mousebutton_up:
                  switch(Reflect.field( __evt, "button" ))
                  {
                     case 1 : fireMouseEvent( met_LeftUp );
                     case 2 : fireMouseEvent( met_MiddleUp );
                     case 3 : fireMouseEvent( met_RightUp );
                  }

               case et_mousemove:
                  fireMouseEvent( met_Move );

               case et_resize:
                  // trace( __evt.width, __evt.height );

               default:
            }
         } while(type!=et_noevent && mainLoopRunning);

         var t = haxe.Timer.stamp();
         var dt = t - last_update;
         if (last_update==0)
            dt = 0;
         last_update = t;
         if (!mPaused)
         {
            for(f in updateCallbacks)
               f(dt);
         }

         for(f in renderCallbacks)
            f( );

		nme.Timer.check();

         flip();
      }

		nme_screen_close();
	}

   public function ResetFPS()
   {
      mT0 = haxe.Timer.stamp();
      mFrameCount = 0;
   }
   public function RenderFPS()
   {
      var t =  haxe.Timer.stamp() - mT0;
      {
         mFrameCount++;
         graphics.lineStyle(0x000000,1);
         var fps = mFrameCount/t;
         fps = Math.round( fps*100 ) * 0.01;
         var text = Std.string(fps);
         Manager.graphics.moveTo(10,10);
         Manager.graphics.text(text,12,null,0xffffff);
      }
   }


	public function tryQuit()
	{
	  if (tryQuitFunction==null || tryQuitFunction())
		 mainLoopRunning = false;
	}

   static var CURSOR_NONE = 0;
   static var CURSOR_NORMAL = 1;
   static var CURSOR_TEXT = 2;
	public static function SetCursor(inCursor:Int)
   {
      nme_set_cursor(inCursor);
   }

   static public function GetMouse() : nme.geom.Point
   {
      var m:Dynamic = nme_get_mouse_position();
      return new nme.geom.Point( m.x, m.y );
   }

	public static function mouseEvent(inType:MouseEventType)
        {
           return 
	   {
		 type : inType,
		 x : SmouseX(),
		 y : SmouseY(),
		 shift : false,
		 ctrl : false,
		 alt : false,
		 leftIsDown : mouseButtonState()!=0,
		 middleIsDown : false,
		 rightIsDown : false
	   };
        }

	function fireMouseEvent(inType:MouseEventType)
	{
	  // TODO: fill in shift etc.
	  var event: MouseEvent = mouseEvent(inType);

	  for(e in mouseEventCallbacks)
		 e(event);

	  if (inType==met_LeftDown)
		 for(e in mouseClickCallbacks)
			e(event);
	}

	function fireKeyEvent(inIsDown:Bool)
	{
	  // TODO: fill in shift etc.
	  var event: KeyEvent =
	  {
		 isDown : inIsDown,
		 code : lastKey(),
		 shift : lastKeyShift(),
		 ctrl : lastKeyCtrl(),
		 alt : lastKeyAlt()
	  };

	  if (inIsDown && event.code==pauseUpdates)
		 mPaused = !mPaused;
	  else if (inIsDown && event.code==toggleQuality)
		 nme_set_draw_quality( (nme_get_draw_quality()+1) & 0x01 );

	  for(e in keyEventCallbacks)
		 e(event);
	}


	public function addMouseCallback(inCallback:MouseEventCallback)
	{
	  mouseEventCallbacks.push(inCallback);
	}

	public function addClickCallback(inCallback:MouseEventCallback)
	{
	  mouseClickCallbacks.push(inCallback);
	}

	public function addKeyCallback(inCallback:KeyEventCallback)
	{
	  keyEventCallbacks.push(inCallback);
	}

	public function addRenderCallback(inCallback:RenderCallback)
	{
	  renderCallbacks.push(inCallback);
	}

	public function addUpdateCallback(inCallback:UpdateCallback)
	{
	  updateCallbacks.push(inCallback);
	}

	public function close()
	{
	  if (mainLoopRunning)
		 mainLoopRunning = false;
	  else
		   nme_screen_close();
	}

	public function delay( period : Int )
	{
		if ( period < 0 ) return;
		nme_delay( period );
	}

	static public function getScreen() : Void
	{
		return __scr;
	}

	public function clear( color : Int )
	{
		nme_surface_clear( __scr, color );
	}

	public function flip()
	{
				graphics.flush();
		nme_flipbuffer( __scr );
	}


	public function events()
	{
		__evt = nme_event();
	}

	public function nextEvent()
	{
		__evt = nme_event();
				return getEventType();
	}

	public function getNextEvent() : Dynamic
	{
		__evt = nme_event();
		return __evt;
	}


	public function getEventType() : EventType
	{
		var returnType : EventType = et_noevent;
		switch Reflect.field( __evt, "type" )
		{
			case -1:
				returnType = et_noevent;
			case 0:
				returnType = et_active;
			case 1:
				returnType = et_keydown;
			case 2:
				returnType = et_keyup;
			case 3:
				returnType = et_mousemove;
			case 4:
				returnType = et_mousebutton_down;
			case 5:
				returnType = et_mousebutton_up;
			case 6:
				returnType = et_joystickmove;
			case 7:
				returnType = et_joystickball;
			case 8:
				returnType = et_joystickhat;
			case 9:
				returnType = et_joystickbutton;
			case 10:
				returnType = et_resize;
			case 11:
				returnType = et_quit;
			case 12:
				returnType = et_user;
			case 13:
				returnType = et_syswm;
		}
		return returnType;
	}

	public function clickRect( x : Int, y : Int, rect : Rect )
	{
		if ( ( x < rect.x ) || ( x > rect.x + rect.w ) || ( y < rect.y ) || ( y > rect.y + rect.h ) )
			return false;
		return true;
	}

	public function lastKey() : Int
	{
		return Reflect.field( __evt, "key" );
	}
	public function lastChar() : Int
	{
		return Reflect.field( __evt, "char" );
	}
	public function lastKeyShift() : Bool
	{
		return Reflect.field( __evt, "shift" );
	}
	public function lastKeyCtrl() : Bool
	{
		return Reflect.field( __evt, "ctrl" );
	}
	public function lastKeyAlt() : Bool
	{
		return Reflect.field( __evt, "alt" );
	}


	public function mouseButton() : Int
	{
		return Reflect.field( __evt, "button" );
	}

	public static function mouseButtonState() : Int
	{
		return Reflect.field( __evt, "state" );
	}

        // Static versions
	public static function SmouseX() : Int
	  { return Reflect.field( __evt, "x" ); }

	public static function SmouseY() : Int
	  { return Reflect.field( __evt, "y" ); }


        // Non static - same function
	public function mouseX() : Int
	{
		return Reflect.field( Manager.__evt, "x" );
	}

	public function mouseY() : Int
	{
		return Reflect.field( Manager.__evt, "y" );
	}

	public static function mousePoint() {return new nme.geom.Point(SmouseX(),SmouseY());}

	public function mouseMoveX() : Int
	{
		return Reflect.field( __evt, "xrel" );
	}

	public function mouseMoveY() : Int
	{
		return Reflect.field( __evt, "yrel" );
	}

	static function set_draw_quality(inQuality:Int) : Int
	{
	   return nme_set_draw_quality(inQuality);
	}

	static function get_draw_quality() : Int
	{
	   return nme_get_draw_quality();
	}
   public static function getClipboardString() : String
   {
      return neko.Lib.nekoToHaxe(  nme_get_clipboard() );
   }
   public static function setClipboardString(inString:String)
   {
      nme_set_clipboard(untyped inString.__s);
   }

	static var nme_surface_clear = neko.Lib.load("nme","nme_surface_clear",2);
	static var nme_screen_init = neko.Lib.load("nme","nme_screen_init",5);
	static var nme_resize_surface = neko.Lib.load("nme","nme_resize_surface",2);
	static var nme_screen_close = neko.Lib.load("nme","nme_screen_close",0);
	static var nme_flipbuffer = neko.Lib.load("nme","nme_flipbuffer",1);
	static var nme_delay = neko.Lib.load("nme","nme_delay",1);
	static var nme_event = neko.Lib.load("nme","nme_event",0);
	static var nme_set_draw_quality = neko.Lib.load("nme","nme_set_draw_quality",1);
	static var nme_get_draw_quality = neko.Lib.load("nme","nme_get_draw_quality",0);
	static var nme_set_cursor = neko.Lib.load("nme","nme_set_cursor",1);
	static var nme_get_mouse_position = neko.Lib.load("nme","nme_get_mouse_position",0);
	static var nme_set_clipboard = neko.Lib.load("nme","nme_set_clipboard",1);
	static var nme_get_clipboard = neko.Lib.load("nme","nme_get_clipboard",0);
}
