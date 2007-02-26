package neko.nme;

enum EventType
{
	et_noevent;
	et_active;
	et_keydown;
	et_keyup;
	et_mousemove;
	et_mousebutton;
	et_joystickmove;
	et_joystickball;
	et_joystickhat;
	et_joystickbutton;
	et_resize;
	et_quit;
	et_user;
	et_syswm;
}

class Manager
{
	static var __scr : Void;
	static var __evt : Void;

	public function new( width : Int, height : Int, title : String, fullscreen : Bool, icon : String )
	{
		if ( width < 100 || height < 20 ) return;
		__scr = nme_screen_init( width, height, untyped title.__s, fullscreen, untyped icon.__s );
	}
	
	public function close()
	{
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
		nme_flipbuffer( __scr );
	}
	
	public function events()
	{
		__evt = nme_event();
	}
	
	public function getEventType() : EventType
	{
		var returnType : EventType;
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
				returnType = et_mousebutton;
			case 5:
				returnType = et_joystickmove;
			case 6:
				returnType = et_joystickball;
			case 7:
				returnType = et_joystickhat;
			case 8:
				returnType = et_joystickbutton;
			case 9:
				returnType = et_resize;
			case 10:
				returnType = et_quit;
			case 11:
				returnType = et_user;
			case 12:
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
	
	public function mouseButton() : Int
	{
		return Reflect.field( __evt, "button" );
	}
	
	public function mouseButtonState() : Int
	{
		return Reflect.field( __evt, "state" );
	}
	
	public function mouseX() : Int
	{
		return Reflect.field( __evt, "x" );
	}
	
	public function mouseY() : Int
	{
		return Reflect.field( __evt, "y" );
	}
	
	public function mouseMoveX() : Int
	{
		return Reflect.field( __evt, "xrel" );
	}
	
	public function mouseMoveY() : Int
	{
		return Reflect.field( __evt, "yrel" );
	}
	
	static var nme_surface_clear = neko.Lib.load("nme","nme_surface_clear",2);
	static var nme_screen_init = neko.Lib.load("nme","nme_screen_init",5);
	static var nme_screen_close = neko.Lib.load("nme","nme_screen_close",0);
	static var nme_flipbuffer = neko.Lib.load("nme","nme_flipbuffer",1);
	static var nme_delay = neko.Lib.load("nme","nme_delay",1);
	static var nme_event = neko.Lib.load("nme","nme_event",0);
}