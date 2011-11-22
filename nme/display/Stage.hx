package nme.display;
#if (cpp || neko)


import haxe.Timer;
import nme.display.DisplayObjectContainer;
import nme.events.MouseEvent;
import nme.events.FocusEvent;
import nme.events.KeyboardEvent;
import nme.events.TouchEvent;
import nme.events.Event;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.media.SoundChannel;
import nme.net.URLLoader;
import nme.Loader;


class Stage extends DisplayObjectContainer
{
	
	/**
	 * Time, in seconds, we wake up before the frame is due.  We then do a
	 * "busy wait" to ensure the frame comes at the right time.  By increasing this number,
	 * the frame rate will be more constant, but the busy wait will take more CPU.
	 */
	public static var nmeEarlyWakeup = 0.005;
	
	public static var OrientationPortrait = 1;
	public static var OrientationPortraitUpsideDown = 2;
	public static var OrientationLandscapeRight = 3;
	public static var OrientationLandscapeLeft = 4;
	public static var OrientationFaceUp = 5;
	public static var OrientationFaceDown = 6;
	
	public var active(default, null):Bool;
	public var align(nmeGetAlign, nmeSetAlign):StageAlign;
	public var displayState(nmeGetDisplayState, nmeSetDisplayState):StageDisplayState;
	public var dpiScale(nmeGetDPIScale, null):Float;
	public var focus(nmeGetFocus, nmeSetFocus):InteractiveObject;
	public var frameRate(default, nmeSetFrameRate): Float;
	public var isOpenGL(nmeIsOpenGL, null):Bool;
	public var onKey:Int -> Bool -> Int -> Int -> Void; 
	public var onQuit:Void -> Void; 
	public var pauseWhenDeactivated:Bool;
	public var quality(nmeGetQuality, nmeSetQuality):StageQuality;
	public var renderRequest:Void -> Void; 
	public var scaleMode(nmeGetScaleMode, nmeSetScaleMode):StageScaleMode;
	public var stageFocusRect(nmeGetStageFocusRect, nmeSetStageFocusRect):Bool;
	public var stageHeight(nmeGetStageHeight, null):Int;
	public var stageWidth(nmeGetStageWidth, null):Int;
	
	private static var efLeftDown = 0x0001;
	private static var efShiftDown = 0x0002;
	private static var efCtrlDown = 0x0004;
	private static var efAltDown = 0x0008;
	private static var efCommandDown = 0x0010;
	private static var efLocationRight = 0x4000;
	private static var efNoNativeClick = 0x10000;
	private static var nmeMouseChanges:Array<String> = [ MouseEvent.MOUSE_OUT, MouseEvent.MOUSE_OVER, MouseEvent.ROLL_OUT, MouseEvent.ROLL_OVER ];
	private static var nmeTouchChanges:Array<String> = [ TouchEvent.TOUCH_OUT, TouchEvent.TOUCH_OVER,	TouchEvent.TOUCH_ROLL_OUT, TouchEvent.TOUCH_ROLL_OVER ];
	private static var sClickEvents = [ "click", "middleClick", "rightClick" ];
	private static var sDownEvents = [ "mouseDown", "middleMouseDown", "rightMouseDown" ];
	private static var sUpEvents = [ "mouseUp", "middleMouseUp", "rightMouseUp" ];
	
	private var nmeDragBounds:Rectangle;
	private var nmeDragObject:Sprite;
	private var nmeDragOffsetX:Float;
	private var nmeDragOffsetY:Float;
	private var nmeFocusOverObjects:Array<InteractiveObject>;
	private var nmeFramePeriod:Float;
	private var nmeInvalid:Bool;
	private var nmeLastClickTime:Float;
	private var nmeLastDown:Array<InteractiveObject>;
	private var nmeLastRender:Float;
	private var nmeMouseOverObjects:Array<InteractiveObject>;
	private var nmeTouchInfo:IntHash<TouchInfo>;
	
	
	public function new(inHandle:Dynamic, inWidth:Int, inHeight:Int)
	{
		super(inHandle, "Stage");
		nmeMouseOverObjects = [];
		nmeFocusOverObjects = [];
		active = true;
		pauseWhenDeactivated = true;
		
		#if android
		renderRequest = nme_stage_request_render;
		#else
		renderRequest = null;
		#end
		
		nme_set_stage_handler(nmeHandle, nmeProcessStageEvent, inWidth, inHeight);
		nmeInvalid = false;
		nmeLastRender = 0;
		nmeLastDown = [];
		nmeLastClickTime = 0.0;
		nmeSetFrameRate(100);
		nmeTouchInfo = new IntHash<TouchInfo>();
	}
	
	
	public static dynamic function getOrientation():Int 
	{
		return nme_stage_get_orientation();
	}
	
	
	public function invalidate():Void
	{
		nmeInvalid = true;
	}
	
	
	private function nmeCheckFocusInOuts(inEvent:Dynamic, inStack:Array<InteractiveObject>)
	{
		// Exit ...
		var new_n = inStack.length;
		var new_obj:InteractiveObject = new_n > 0 ? inStack[new_n - 1] : null;
		var old_n = nmeFocusOverObjects.length;
		var old_obj:InteractiveObject = old_n > 0 ? nmeFocusOverObjects[old_n - 1] : null;
		
		if (new_obj != old_obj)
		{
			// focusOver/focusOut goes only over the non-common objects in the tree...
			var common = 0;
			while (common < new_n && common < old_n && inStack[common] == nmeFocusOverObjects[common] )
				common++;
			
			var focusOut = new FocusEvent(FocusEvent.FOCUS_OUT, false, false, new_obj, inEvent.flags > 0, inEvent.code);
			
			var i = old_n - 1;
			while (i >= common)
			{
				nmeFocusOverObjects[i].dispatchEvent(focusOut);
				i--;
			}
			
			var focusIn = new FocusEvent(FocusEvent.FOCUS_IN, false, false, old_obj, inEvent.flags > 0, inEvent.code);
			var i = new_n - 1;
			
			while (i >= common)
			{
				inStack[i].dispatchEvent(focusIn);
				i--;
			}
			
			nmeFocusOverObjects = inStack;
		}
	}
	
	
	private function nmeCheckInOuts(inEvent:MouseEvent, inStack:Array<InteractiveObject>, ?touchInfo:TouchInfo)
	{
		var prev = touchInfo == null ? nmeMouseOverObjects : touchInfo.touchOverObjects;
		var events = touchInfo == null ? nmeMouseChanges : nmeTouchChanges;
		
		var new_n = inStack.length;
		var new_obj:InteractiveObject = new_n > 0 ? inStack[new_n - 1] : null;
		var old_n = prev.length;
		var old_obj:InteractiveObject = old_n > 0 ? prev[old_n - 1] : null;
		
		if (new_obj != old_obj)
		{
			// mouseOut/MouseOver goes up the object tree...
			if (old_obj != null)
				old_obj.nmeFireEvent(inEvent.nmeCreateSimilar(events[0], new_obj, old_obj));
			
			if (new_obj != null)
				new_obj.nmeFireEvent(inEvent.nmeCreateSimilar(events[1], old_obj));
			
			// rollOver/rollOut goes only over the non-common objects in the tree...
			var common = 0;
			while (common < new_n && common < old_n && inStack[common] == prev[common])
				common++;
			
			var rollOut = inEvent.nmeCreateSimilar(events[2], new_obj, old_obj);
			var i = old_n - 1;
			while (i >= common)
			{
				prev[i].dispatchEvent(rollOut);
				i--;
			}
			
			var rollOver = inEvent.nmeCreateSimilar(events[3], old_obj);
			var i = new_n - 1;
			while (i >= common)
			{
				inStack[i].dispatchEvent(rollOver);
				i--;
			}
			
			if (touchInfo == null)
				nmeMouseOverObjects = inStack;
			else
				touchInfo.touchOverObjects = inStack;
			
			return false;
		}
		
		return true;
	}
	
	
	private function nmeCheckRender()
	{
		//trace("nmeCheckRender " + frameRate);
		if (frameRate > 0)
		{
			var now = Timer.stamp();
			if (now >= nmeLastRender + nmeFramePeriod)
			{
				nmeLastRender = now;
				if (renderRequest != null)
					renderRequest();
				else
					nmeRender(true);
			}
		}
	}
	
	
	private function nmeDoProcessStageEvent(inEvent:Dynamic):Float
	{
		var result = 0.0;
		
		#if android try { #end
		//if (inEvent.type!=9) trace("Stage Event : " + inEvent);
		var type:Int = Std.int(Reflect.field(inEvent, "type"));
		
		switch(type)
		{
			case 2: // etChar
				if (onKey != null)
					untyped onKey(inEvent.code, inEvent.down, inEvent.char, inEvent.flags);
			
			case 1: // etKeyDown
				nmeOnKey(inEvent, KeyboardEvent.KEY_DOWN);
			
			case 3: // etKeyUp
				nmeOnKey(inEvent, KeyboardEvent.KEY_UP);
			
			case 4: // etMouseMove
				nmeOnMouse(inEvent, MouseEvent.MOUSE_MOVE, true);
			
			case 5: // etMouseDown
				nmeOnMouse(inEvent, MouseEvent.MOUSE_DOWN, true);
			
			case 6: // etMouseClick
				nmeOnMouse(inEvent, MouseEvent.CLICK, true);
			
			case 7: // etMouseUp
				nmeOnMouse(inEvent, MouseEvent.MOUSE_UP, true);
			
			case 8: // etResize
				nmeOnResize(inEvent.x, inEvent.y);
				if (renderRequest == null)
					nmeRender(false);
			
			case 9: // etPoll
				nmePollTimers();
			
			case 10: // etQuit
				if (onQuit != null)
					untyped onQuit();
			
			case 11: // etFocus
				nmeOnFocus(inEvent);
			
			case 12: // etShouldRotate
				if (shouldRotateInterface(inEvent.value))
					inEvent.result = 2;
			
			case 14: // etRedraw
				nmeRender(true);
			
			case 15: // etTouchBegin
				var touchInfo = new TouchInfo();
				nmeTouchInfo.set(inEvent.value, touchInfo);
				nmeOnTouch(inEvent, TouchEvent.TOUCH_BEGIN, touchInfo);
				// trace("etTouchBegin : " + inEvent.value + "   " + inEvent.x + "," + inEvent.y+ " OBJ:" + inEvent.id  );
				if ((inEvent.flags & 0x8000) > 0)
					nmeOnMouse(inEvent, MouseEvent.MOUSE_DOWN, false);
			
			case 16: // etTouchMove
				var touchInfo = nmeTouchInfo.get(inEvent.value);
				nmeOnTouch(inEvent, TouchEvent.TOUCH_MOVE, touchInfo);
			
			case 17: // etTouchEnd
				var touchInfo = nmeTouchInfo.get (inEvent.value);
				nmeOnTouch (inEvent, TouchEvent.TOUCH_END, touchInfo);
				nmeTouchInfo.remove(inEvent.value);
				// trace("etTouchEnd : " + inEvent.value + "   " + inEvent.x + "," + inEvent.y + " OBJ:" + inEvent.id );
				if ((inEvent.flags & 0x8000) > 0)
					nmeOnMouse(inEvent, MouseEvent.MOUSE_UP, false);
			
			case 18: // etTouchTap
				//nmeOnTouchTap(inEvent.TouchEvent.TOUCH_TAP);
			
			case 19: // etChange
				nmeOnChange(inEvent);
			
			case 20: // etActivate
				nmeSetActive(true);
			
			case 21: // etDeactivate
				nmeSetActive(false);
			
			case 22: // etGotInputFocus
				var evt = new Event(Event.GOT_INPUT_FOCUS);
				nmeBroadcast(evt);
			
			case 23: // etLostInputFocus
				var evt = new Event(Event.LOST_INPUT_FOCUS);
				nmeBroadcast(evt);
			
			// TODO: user, sys_wm, sound_finished
		}
		
		result = nmeUpdateNextWake();
		
		#if android } catch (e:Dynamic) { trace("ERROR: " +  e); } #end
		
		return result;
	}
	

	private function nmeProcessStageEvent(inEvent:Dynamic):Dynamic
	{
		nmeDoProcessStageEvent(inEvent);
		return null;
	}
	
	
	private function nmeDrag(inMouse:Point)
	{
		var p = nmeDragObject.parent;
		if (p != null)
			inMouse = p.globalToLocal(inMouse);
		
		var x = inMouse.x + nmeDragOffsetX;
		var y = inMouse.y + nmeDragOffsetY;
		
		if (nmeDragBounds != null)
		{
			if (x < nmeDragBounds.x) x = nmeDragBounds.x;
			else if (x > nmeDragBounds.right) x = nmeDragBounds.right;
			
			if (y < nmeDragBounds.y) y = nmeDragBounds.y;
			else if (y > nmeDragBounds.bottom) y = nmeDragBounds.bottom;
		}
		
		nmeDragObject.x = x;
		nmeDragObject.y = y;
	}
	
	
	public override function nmeGetStage():Stage
	{
		return this;
	}
	
	
	private function nmeNextFrameDue(inOtherTimers:Float)
	{
		if (!active && pauseWhenDeactivated)
			return inOtherTimers;
		if (frameRate > 0)
		{
			var next = nmeLastRender + nmeFramePeriod - Timer.stamp() - nmeEarlyWakeup;
			if (next < inOtherTimers)
				return next;
		}
		return inOtherTimers;
	}
	
	
	private function nmeOnChange(inEvent)
	{
		var obj:DisplayObject = nmeFindByID(inEvent.id);
		if (obj != null)
			obj.nmeFireEvent(new Event(Event.CHANGE));
	}
	
	
	private function nmeOnFocus(inEvent:Dynamic)
	{
		var stack = new Array<InteractiveObject>();
		var obj:DisplayObject = nmeFindByID(inEvent.id);
		if (obj != null)
			obj.nmeGetInteractiveObjectStack(stack);
		if (stack.length > 0 && (inEvent.value == 1 || inEvent.value == 2))
		{
			var obj = stack[0];
			var evt = new FocusEvent(inEvent.value == 1 ? FocusEvent.MOUSE_FOCUS_CHANGE : FocusEvent.KEY_FOCUS_CHANGE, true, true, nmeFocusOverObjects.length == 0 ? null : nmeFocusOverObjects[0], inEvent.flags > 0, inEvent.code);
			obj.nmeFireEvent(evt);
			if (evt.nmeGetIsCancelled())
			{
				inEvent.result = 1;
				return;
			}
		}
		
		stack.reverse();
		
		nmeCheckFocusInOuts(inEvent, stack);
	}
	
	
	function nmeOnKey(inEvent:Dynamic,inType:String)
	{
		var stack = new Array<InteractiveObject>();
		var obj:DisplayObject = nmeFindByID(inEvent.id);
		if (obj != null)
			obj.nmeGetInteractiveObjectStack(stack);
		if (stack.length > 0)
		{
			var obj = stack[0];
			var flags:Int = inEvent.flags;
			var evt = new KeyboardEvent(inType, true, true, inEvent.code, inEvent.value, ((flags & efLocationRight) == 0) ? 1 : 0, (flags & efCtrlDown) != 0, (flags & efAltDown) != 0, (flags & efShiftDown) !=0);
			obj.nmeFireEvent(evt);
			if (evt.nmeGetIsCancelled())
				inEvent.result = 1;
		}
	}
	
	
	private function nmeOnMouse(inEvent:Dynamic, inType:String, inFromMouse:Bool)
	{
		var type = inType;
		var button:Int = inEvent.value;
		if (!inFromMouse)
			button = 0;
		var wheel = 0;
		if (inType == MouseEvent.MOUSE_DOWN)
		{
			if (button > 2)
				return;
			type = sDownEvents[button];
		}
		else if (inType == MouseEvent.MOUSE_UP)
		{
			if (button > 2)
			{
				type = MouseEvent.MOUSE_WHEEL;
				wheel = button == 3 ? -1 : 1;
				//trace(wheel);
			}
			else
				type = sUpEvents[button];
			}
			
			if (nmeDragObject != null)
				nmeDrag(new Point(inEvent.x, inEvent.y));
			
			var stack = new Array<InteractiveObject>();
			var obj:DisplayObject = nmeFindByID(inEvent.id);
			if (obj != null)
				obj.nmeGetInteractiveObjectStack(stack);
			
			var local:Point = null;
			if (stack.length > 0)
			{
				var obj = stack[0];
				stack.reverse();
				local = obj.globalToLocal(new Point(inEvent.x, inEvent.y));
				var evt = MouseEvent.nmeCreate(type, inEvent, local, obj);
				evt.delta = wheel;
				if (inFromMouse)
					nmeCheckInOuts(evt, stack);
				obj.nmeFireEvent(evt);
			}
			else
			{
				//trace("No obj?");
				local = new Point(inEvent.x, inEvent.y);
				var evt = MouseEvent.nmeCreate(type, inEvent, local, null);
				evt.delta = wheel;
				if (inFromMouse)
					nmeCheckInOuts(evt, stack);
			}
			
			var click_obj = stack.length > 0 ? stack[ stack.length - 1] : this;
			if (inType == MouseEvent.MOUSE_DOWN && button < 3)
			{
				nmeLastDown[button] = click_obj;
			}
			else if (inType == MouseEvent.MOUSE_UP && button < 3)
			{
				if (click_obj == nmeLastDown[button])
				{
				var evt = MouseEvent.nmeCreate(sClickEvents[button], inEvent, local, click_obj);
				click_obj.nmeFireEvent(evt);

				if (button == 0 && click_obj.doubleClickEnabled)				
				{
					var now = Timer.stamp();
					if (now - nmeLastClickTime < 0.25)
					{
						var evt = MouseEvent.nmeCreate(MouseEvent.DOUBLE_CLICK, inEvent, local, click_obj);
						click_obj.nmeFireEvent(evt);
					}
					nmeLastClickTime = now;
				}
			}
			nmeLastDown[button] = null;
		}
	}
	
	
	private function nmeOnResize(inW:Float, inH:Float)
	{
		var evt = new Event(Event.RESIZE);
		nmeBroadcast(evt);
	}
	
	
	private function nmeOnTouch (inEvent:Dynamic, inType:String, touchInfo:TouchInfo)
	{
		var stack = new Array<InteractiveObject>();
		var obj:DisplayObject = nmeFindByID(inEvent.id);
		if (obj != null)
			obj.nmeGetInteractiveObjectStack(stack);
		
		if (stack.length > 0)
		{
			var obj = stack[0];
			stack.reverse();
			var local = obj.globalToLocal(new Point(inEvent.x, inEvent.y));
			var evt = TouchEvent.nmeCreate(inType, inEvent, local, obj);
			evt.touchPointID = inEvent.value;
			evt.isPrimaryTouchPoint = (inEvent.flags & 0x8000) > 0;
			//if (evt.isPrimaryTouchPoint)
			nmeCheckInOuts(evt, stack, touchInfo);
			obj.nmeFireEvent(evt);
			if (evt.isPrimaryTouchPoint && inType == TouchEvent.TOUCH_MOVE)
			{
				if (nmeDragObject != null)
					nmeDrag(new Point(inEvent.x, inEvent.y));
				
				var evt = MouseEvent.nmeCreate(MouseEvent.MOUSE_MOVE, inEvent, local, obj);
				obj.nmeFireEvent(evt);
			}
		}
		else
		{
			//trace("No object?");
			var evt = TouchEvent.nmeCreate(inType, inEvent, new Point(inEvent.x, inEvent.y), null);
			evt.touchPointID = inEvent.value;
			evt.isPrimaryTouchPoint = (inEvent.flags & 0x8000) > 0;
			//if (evt.isPrimaryTouchPoint)
			nmeCheckInOuts(evt, stack, touchInfo);
		}
	}
	
	
	public function nmePollTimers()
	{
		//trace("poll");
		Timer.nmeCheckTimers();
		SoundChannel.nmePollComplete();
		URLLoader.nmePollData();
		nmeCheckRender();
	}
	
	
	public function nmeRender(inSendEnterFrame:Bool)
	{
		if (!active)
			return;
		
		//trace("Render");
		if (inSendEnterFrame)
		{
			nmeBroadcast(new Event(Event.ENTER_FRAME));
		}
		if (nmeInvalid)
		{
			nmeInvalid = false;
			nmeBroadcast(new Event(Event.RENDER));
		}
		nme_render_stage(nmeHandle);
	}
	
	
	public function nmeSetActive(inActive:Bool)
	{
		// trace("nmeSetActive : " + inActive);
		if (inActive != active)
		{
			active = inActive;
			if (!active)
				nmeLastRender = Timer.stamp();
			
			var evt = new Event(inActive ? Event.ACTIVATE : Event.DEACTIVATE);
			nmeBroadcast(evt);
			if (inActive)
				nmePollTimers();
		}
	}
	
	
	public function nmeStartDrag(sprite:Sprite, lockCenter:Bool, bounds:Rectangle):Void
	{
		nmeDragBounds = (bounds == null) ? null : bounds.clone();
		nmeDragObject = sprite;
		
		if (nmeDragObject != null)
		{
			if (lockCenter)
			{
				nmeDragOffsetX = -nmeDragObject.width / 2;
				nmeDragOffsetY = -nmeDragObject.height / 2;
			}
			else
			{
				var mouse = new Point(mouseX, mouseY);
				var p = nmeDragObject.parent;
				if (p != null)
					mouse = p.globalToLocal(mouse);
				
				nmeDragOffsetX = nmeDragObject.x - mouse.x;
				nmeDragOffsetY = nmeDragObject.y - mouse.y;
			}
		}
	}


	public function nmeStopDrag(sprite:Sprite):Void
	{
		nmeDragBounds = null;
		nmeDragObject = null;
	}
	
	
	public function nmeUpdateNextWake()
	{
		// TODO: In a multi-stage environment, may need to handle this better...
		var next_wake = Timer.nmeNextWake(315000000.0);
		if (next_wake > 0.02 && (nme.media.SoundChannel.nmeCompletePending() || nme.net.URLLoader.nmeLoadPending()))
		{
			next_wake = (active || !pauseWhenDeactivated) ? 0.020 : 0.500;
		}
		next_wake = nmeNextFrameDue(next_wake);
		nme_stage_set_next_wake(nmeHandle, next_wake);
		return next_wake;
	}
	
	
	public static function setFixedOrientation(inOrientation:Int)
	{
		// If you set this, you don't need to set the 'shouldRotateInterface' function.
		nme_stage_set_fixed_orientation(inOrientation);
	}
	
	
	public static dynamic function shouldRotateInterface(inOrientation:Int):Bool
	{
		return inOrientation == OrientationPortrait;
	}
	
	
	public function showCursor(inShow:Bool)
	{
		nme_stage_show_cursor(nmeHandle, inShow);
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetAlign():StageAlign
	{
		var i:Int = nme_stage_get_align(nmeHandle);
		return Type.createEnumIndex(StageAlign, i);
	}
	
	
	private function nmeSetAlign(inMode:StageAlign):StageAlign
	{
		nme_stage_set_align(nmeHandle, Type.enumIndex(inMode));
		return inMode;
	}
	
	
	private function nmeGetDisplayState():StageDisplayState
	{
		var i:Int = nme_stage_get_display_state(nmeHandle);
		return Type.createEnumIndex(StageDisplayState, i);
	}
	
	
	private function nmeSetDisplayState(inState:StageDisplayState):StageDisplayState
	{
		nme_stage_set_display_state(nmeHandle, Type.enumIndex(inState));
		return inState;
	}
	
	
	private function nmeGetDPIScale():Float
	{
		return nme_stage_get_dpi_scale(nmeHandle);
	}
	
	
	private function nmeGetFocus():InteractiveObject
	{
		var id = nme_stage_get_focus_id(nmeHandle);
		var obj:DisplayObject = nmeFindByID(id);
		return cast obj;
	}
	
	
	private function nmeSetFocus(inObject:InteractiveObject):InteractiveObject
	{
		if (inObject == null)
			nme_stage_set_focus(nmeHandle, null, 0);
		else
			nme_stage_set_focus(nmeHandle, inObject.nmeHandle, 0);
		return inObject;
	}
	
	
	private function nmeSetFrameRate(inRate:Float):Float
	{
		frameRate = inRate;
		nmeFramePeriod = frameRate <= 0 ? frameRate : 1.0 / frameRate;
		return inRate;
	}
	
	
	private function nmeIsOpenGL():Bool
	{
		return nme_stage_is_opengl(nmeHandle);
	}
	
	
	private function nmeGetQuality():StageQuality
	{
		var i:Int = nme_stage_get_quality(nmeHandle);
		return Type.createEnumIndex(StageQuality, i);
	}
	
	
	private function nmeSetQuality(inQuality:StageQuality):StageQuality
	{
		nme_stage_set_quality(nmeHandle, Type.enumIndex(inQuality));
		return inQuality;
	}
	
	
	private function nmeGetScaleMode():StageScaleMode
	{
		var i:Int = nme_stage_get_scale_mode(nmeHandle);
		return Type.createEnumIndex(StageScaleMode, i);
	}
	
	
	private function nmeSetScaleMode(inMode:StageScaleMode):StageScaleMode
	{
		nme_stage_set_scale_mode(nmeHandle, Type.enumIndex(inMode));
		return inMode;
	}
	
	
	private function nmeGetStageFocusRect():Bool { return nme_stage_get_focus_rect(nmeHandle); }
	private function nmeSetStageFocusRect(inVal:Bool):Bool
	{
		nme_stage_set_focus_rect(nmeHandle, inVal);
		return inVal;
	}
	
	
	private function nmeGetStageHeight():Int
	{
		return nme_stage_get_stage_height(nmeHandle);
	}
	
	
	function nmeGetStageWidth():Int
	{
		return nme_stage_get_stage_width(nmeHandle);
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_set_stage_handler = Loader.load("nme_set_stage_handler", 4);
	private static var nme_render_stage = Loader.load("nme_render_stage", 1);
	private static var nme_stage_get_focus_id = Loader.load("nme_stage_get_focus_id", 1);
	private static var nme_stage_set_focus = Loader.load("nme_stage_set_focus", 3);
	private static var nme_stage_get_focus_rect = Loader.load("nme_stage_get_focus_rect", 1);
	private static var nme_stage_set_focus_rect = Loader.load("nme_stage_set_focus_rect", 2);
	private static var nme_stage_is_opengl = Loader.load("nme_stage_is_opengl", 1);
	private static var nme_stage_get_stage_width = Loader.load("nme_stage_get_stage_width", 1);
	private static var nme_stage_get_stage_height = Loader.load("nme_stage_get_stage_height", 1);
	private static var nme_stage_get_dpi_scale = Loader.load("nme_stage_get_dpi_scale", 1);
	private static var nme_stage_get_scale_mode = Loader.load("nme_stage_get_scale_mode", 1);
	private static var nme_stage_set_scale_mode = Loader.load("nme_stage_set_scale_mode", 2);
	private static var nme_stage_get_align = Loader.load("nme_stage_get_align", 1);
	private static var nme_stage_set_align = Loader.load("nme_stage_set_align", 2);
	private static var nme_stage_get_quality = Loader.load("nme_stage_get_quality", 1);
	private static var nme_stage_set_quality = Loader.load("nme_stage_set_quality", 2);
	private static var nme_stage_get_display_state = Loader.load("nme_stage_get_display_state", 1);
	private static var nme_stage_set_display_state = Loader.load("nme_stage_set_display_state", 2);
	private static var nme_stage_set_next_wake = Loader.load("nme_stage_set_next_wake", 2);
	private static var nme_stage_request_render = Loader.load("nme_stage_request_render", 0);
	private static var nme_stage_show_cursor = Loader.load("nme_stage_show_cursor", 2);
	private static var nme_stage_set_fixed_orientation = Loader.load("nme_stage_set_fixed_orientation", 1);
	private static var nme_stage_get_orientation = Loader.load("nme_stage_get_orientation", 0);

}


class TouchInfo
{

	public var touchOverObjects:Array<InteractiveObject>;
	
	
	public function new()
	{	
		touchOverObjects = [];	
	}
	
}


#else
typedef Stage = flash.display.Stage;
#end