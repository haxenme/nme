package neash.display;
#if (cpp || neko)


import neash.Loader;


class SimpleButton extends InteractiveObject
{
	
	public var downState(default, nmeSetDownState):DisplayObject;
	public var enabled(nmeGetEnabled, nmeSetEnabled):Bool;
	public var hitTestState(default, nmeSetHitTestState):DisplayObject;
	public var overState(default, nmeSetOverState):DisplayObject;
	// var soundTransform : SoundTransform;
	// var trackAsMenu : Bool;
	public var upState(default, nmeSetUpState):DisplayObject;
	public var useHandCursor(nmeGetHandCursor, nmeSetHandCursor):Bool;
	
	
	public function new(?upState:DisplayObject, ?overState:DisplayObject, ?downState:DisplayObject, ?hitTestState:DisplayObject)
	{
		super(nme_simple_button_create(), "SimpleButton");
		nmeSetUpState(upState);
		nmeSetOverState(overState);
		nmeSetDownState(downState);
		nmeSetHitTestState(hitTestState);
	}
	
	
	
	// Getters & Setters
	
	
	
	/** @private */ public function nmeSetDownState(inState:DisplayObject)
	{
		downState = inState;
		nme_simple_button_set_state(nmeHandle, 1, inState == null ? null : inState.nmeHandle);
		return inState;
	}
	
	
	/** @private */ public function nmeGetEnabled():Bool { return nme_simple_button_get_enabled(nmeHandle); }
	/** @private */ public function nmeSetEnabled(inVal):Bool
	{
		nme_simple_button_set_enabled(nmeHandle, inVal);
		return inVal;
	}
	
	
	/** @private */ public function nmeGetHandCursor():Bool { return nme_simple_button_get_hand_cursor(nmeHandle); }
	/** @private */ public function nmeSetHandCursor(inVal):Bool
	{
		nme_simple_button_set_hand_cursor(nmeHandle, inVal);
		return inVal;
	}
	
	
	/** @private */ public function nmeSetHitTestState(inState:DisplayObject)
	{
		hitTestState = inState;
		nme_simple_button_set_state(nmeHandle, 3, inState == null ? null : inState.nmeHandle);
		return inState;
	}
	
	
	/** @private */ public function nmeSetOverState(inState:DisplayObject)
	{
		overState = inState;
		nme_simple_button_set_state(nmeHandle, 2, inState == null ? null : inState.nmeHandle);
		return inState;
	}
	
	
	/** @private */ public function nmeSetUpState(inState:DisplayObject)
	{
		upState = inState;
		nme_simple_button_set_state(nmeHandle, 0, inState == null ? null : inState.nmeHandle);
		return inState;
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_simple_button_set_state = Loader.load("nme_simple_button_set_state", 3);
	private static var nme_simple_button_get_enabled = Loader.load("nme_simple_button_get_enabled", 1);
	private static var nme_simple_button_set_enabled = Loader.load("nme_simple_button_set_enabled", 2);
	private static var nme_simple_button_get_hand_cursor = Loader.load("nme_simple_button_get_hand_cursor", 1);
	private static var nme_simple_button_set_hand_cursor = Loader.load("nme_simple_button_set_hand_cursor", 2);
	private static var nme_simple_button_create = Loader.load("nme_simple_button_create", 0);

}


#else
typedef SimpleButton = flash.display.SimpleButton;
#end