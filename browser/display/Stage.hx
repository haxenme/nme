package browser.display;
#if js


import browser.display.Graphics;
import browser.display.StageDisplayState;
import browser.display.StageScaleMode;
import browser.events.Event;
import browser.events.FocusEvent;
import browser.events.KeyboardEvent;
import browser.events.MouseEvent;
import browser.events.TouchEvent;
import browser.geom.Matrix;
import browser.geom.Point;
import browser.geom.Rectangle;
import browser.ui.Acceleration;
import browser.ui.Keyboard;
import browser.Lib;
import nme.Vector;
import js.html.CanvasElement;
import js.html.DeviceMotionEvent;
import js.Browser;

#if stage3d
import browser.display.Stage3D;
#end


class Stage extends DisplayObjectContainer {
	
	
	public static inline var NAME:String = "Stage";
	public static var nmeAcceleration:Acceleration = { x: 0.0, y: 1.0, z: 0.0 };
	public static var OrientationPortrait = 1;
	public static var OrientationPortraitUpsideDown = 2;
	public static var OrientationLandscapeRight = 3;
	public static var OrientationLandscapeLeft = 4;
	
	public var align:StageAlign;
	public var backgroundColor(get_backgroundColor, set_backgroundColor):Int;
	@:isVar public var displayState(get_displayState, set_displayState):StageDisplayState;
	public var focus(get_focus, set_focus):InteractiveObject;
	public var frameRate(get_frameRate, set_frameRate):Float;
	public var fullScreenHeight(get_fullScreenHeight, null):Int;
	public var fullScreenWidth(get_fullScreenWidth, null):Int;
	public var nmePointInPathMode(default, null):PointInPathMode;
	@:isVar public var quality(get_quality, set_quality):String;
	public var scaleMode:StageScaleMode;
	public var showDefaultContextMenu(get_showDefaultContextMenu, set_showDefaultContextMenu):Bool;
	public var stageFocusRect:Bool;
	public var stageHeight(get_stageHeight, null):Int;
	public var stageWidth(get_stageWidth, null):Int;

	#if stage3d
	public var stage3Ds:Vector<Stage3D>;
	#end
	
	private static inline var DEFAULT_FRAMERATE = 0.0;
	private static inline var UI_EVENTS_QUEUE_MAX = 1000;
	
	private static var nmeMouseChanges:Array<String> = [ MouseEvent.MOUSE_OUT, MouseEvent.MOUSE_OVER, MouseEvent.ROLL_OUT, MouseEvent.ROLL_OVER ];
	private static var nmeTouchChanges:Array<String> = [ TouchEvent.TOUCH_OUT, TouchEvent.TOUCH_OVER, TouchEvent.TOUCH_ROLL_OUT, TouchEvent.TOUCH_ROLL_OVER ];
	
	private var nmeBackgroundColour:Int;
	private var nmeDragBounds:Rectangle;
	private var nmeDragObject:DisplayObject;
	private var nmeDragOffsetX:Float;
	private var nmeDragOffsetY:Float;
	private var nmeFocusObject:InteractiveObject;
	private var nmeFocusOverObjects:Array<InteractiveObject>;
	private var nmeFrameRate:Float;
	private var nmeInterval:Int;
	private var nmeInvalid:Bool;
	private var nmeMouseOverObjects:Array<InteractiveObject>;
	private var nmeShowDefaultContextMenu:Bool;
	private var nmeStageActive:Bool;
	private var nmeStageMatrix:Matrix;
	private var nmeTimer:Dynamic;
	private var nmeTouchInfo:Array<TouchInfo>;
	private var nmeUIEventsQueue:Array<js.html.Event>;
	private var nmeUIEventsQueueIndex:Int;
	private var nmeWindowWidth:Int;
	private var nmeWindowHeight:Int;
	private var _mouseX:Float;
	private var _mouseY:Float;
	
	
	public function new(width:Int, height:Int) {
		
		super();
		
		nmeFocusObject = null;
		nmeWindowWidth = width;
		nmeWindowHeight = height;
		stageFocusRect = false;
		scaleMode = StageScaleMode.SHOW_ALL;
		nmeStageMatrix = new Matrix();
		tabEnabled = true;
		frameRate = DEFAULT_FRAMERATE;
		this.backgroundColor = 0xffffff;
		name = NAME;
		loaderInfo = LoaderInfo.create(null);
		loaderInfo.parameters.width = Std.string(nmeWindowWidth);
		loaderInfo.parameters.height = Std.string(nmeWindowHeight);
		
		nmePointInPathMode = Graphics.nmeDetectIsPointInPathMode();
		nmeMouseOverObjects = [];
		showDefaultContextMenu = true;
		nmeTouchInfo = [];
		nmeFocusOverObjects = [];
		nmeUIEventsQueue = untyped __new__("Array", UI_EVENTS_QUEUE_MAX);
		nmeUIEventsQueueIndex = 0;

		#if stage3d
		stage3Ds = new Vector();
		stage3Ds.push(new Stage3D());
		alpha = 0;   // so that the stage itself does not preclude to see Stage3D OpenGLView
		#end
	}
	
	
	public static dynamic function getOrientation():Int {
		
		var rotation:Int = untyped window.orientation;
		var orientation:Int = OrientationPortrait;
		
		switch (rotation) {
			
			case -90: orientation = OrientationLandscapeLeft;
			case 180: orientation = OrientationPortraitUpsideDown;
			case 90: orientation = OrientationLandscapeRight;
			default: orientation = OrientationPortrait;
			
		}
		
		return orientation;
		
	}
	
	
	public function invalidate():Void {
		
		nmeInvalid = true;
		
	}
	
	
	private function nmeCheckFocusInOuts(event:FocusEvent, inStack:Array<InteractiveObject>):Void {
		
		var new_n = inStack.length;
		var new_obj:InteractiveObject = (new_n > 0 ? inStack[new_n - 1] : null);
		var old_n = nmeFocusOverObjects.length;
		var old_obj:InteractiveObject = (old_n > 0 ? nmeFocusOverObjects[old_n - 1] : null);
		
		if (new_obj != old_obj) {
			
			// focusOver/focusOut goes only over the non-common objects in the tree...
			var common = 0;
			while (common < new_n && common < old_n && inStack[common] == nmeFocusOverObjects[common]) {
				
				common++;
				
			}
			
			var focusOut = new FocusEvent(FocusEvent.FOCUS_OUT, false, false, new_obj, false /* not implemented */, 0 /* not implemented */);
			
			var i = old_n - 1;
			while (i >= common) {
				
				nmeFocusOverObjects[i].dispatchEvent(focusOut);
				i--;
				
			}
			
			var focusIn = new FocusEvent(FocusEvent.FOCUS_IN, false, false, old_obj, false /* not implemented */, 0 /* not implemented */);
			var i = new_n - 1;
			
			while (i >= common) {
				
				inStack[i].dispatchEvent(focusIn);
				i--;
				
			}
			
			nmeFocusOverObjects = inStack;
			focus = new_obj;
			
		}
		
	}
	
	
	private function nmeCheckInOuts(event:Event, stack:Array<InteractiveObject>, touchInfo:TouchInfo = null) {
		
		var prev = (touchInfo == null ? nmeMouseOverObjects : touchInfo.touchOverObjects);
		var changeEvents = (touchInfo == null ? nmeMouseChanges : nmeTouchChanges);
		
		var new_n = stack.length;
		var new_obj:InteractiveObject = (new_n > 0 ? stack[new_n - 1] : null);
		var old_n = prev.length;
		var old_obj:InteractiveObject = (old_n > 0 ? prev[old_n - 1] : null);
		
		if (new_obj != old_obj) {
			
			// mouseOut/MouseOver goes up the object tree...
			if (old_obj != null) {
				
				old_obj.nmeFireEvent(event.nmeCreateSimilar(changeEvents[0], new_obj, old_obj));
				
			}
			
			if (new_obj != null) {
				
				new_obj.nmeFireEvent(event.nmeCreateSimilar(changeEvents[1], old_obj, new_obj));
				
			}
			
			// rollOver/rollOut goes only over the non-common objects in the tree...
			var common = 0;
			while (common < new_n && common < old_n && stack[common] == prev[common]) {
				
				common++;
				
			}
			
			var rollOut = event.nmeCreateSimilar(changeEvents[2], new_obj, old_obj);
			var i = old_n - 1;
			
			while (i >= common) {
				
				prev[i].dispatchEvent(rollOut);
				i--;
				
			}
			
			var rollOver = event.nmeCreateSimilar(changeEvents[3], old_obj);
			var i = new_n - 1;
			
			while (i >= common) {
				
				stack[i].dispatchEvent(rollOver);
				i--;
				
			}
			
			if (touchInfo == null) {
				
				nmeMouseOverObjects = stack;
				
			} else {
				
				touchInfo.touchOverObjects = stack;
				
			}
			
		}
		
	}
	
	
	private function nmeDrag(point:Point):Void {
		
		var p = nmeDragObject.parent;
		
		if (p != null) {
			
			point = p.globalToLocal(point);
			
		}
		
		var x = point.x + nmeDragOffsetX;
		var y = point.y + nmeDragOffsetY;
		
		if (nmeDragBounds != null) {
			
			if (x < nmeDragBounds.x) {
				
				x = nmeDragBounds.x;
				
			} else if (x > nmeDragBounds.right) {
				
				x = nmeDragBounds.right;
				
			}
			
			if (y < nmeDragBounds.y) {
				
				y = nmeDragBounds.y;
				
			} else if (y > nmeDragBounds.bottom) {
				
				y = nmeDragBounds.bottom;
				
			}
			
		}
		
		nmeDragObject.x = x;
		nmeDragObject.y = y;
		
	}
	
	
	override private function nmeIsOnStage():Bool {
		
		return true;
		
	}
	
	
	public function nmeProcessStageEvent(evt:js.html.Event):Void {
		
		evt.stopPropagation();
		
		switch (evt.type) {
			
			case "resize":
				
				nmeOnResize(Lib.nmeGetWidth(), Lib.nmeGetHeight());
			
			case "focus":
				
				nmeOnFocus(cast evt, true);
			
			case "blur":
				
				nmeOnFocus(evt, false);
			
			case "mousemove":
				
				nmeOnMouse(cast evt, MouseEvent.MOUSE_MOVE);
			
			case "mousedown":
				
				nmeOnMouse(cast evt, MouseEvent.MOUSE_DOWN);
			
			case "mouseup":
				
				nmeOnMouse(cast evt, MouseEvent.MOUSE_UP);
			
			case "click":
				
				nmeOnMouse(cast evt, MouseEvent.CLICK);
			
			case "mousewheel":
				
				nmeOnMouse(cast evt, MouseEvent.MOUSE_WHEEL);
			
			case "dblclick":
				
				nmeOnMouse(cast evt, MouseEvent.DOUBLE_CLICK);
			
			case "keydown":
				
				var evt:js.html.KeyboardEvent = cast evt;
				var keyCode = (evt.keyCode != null ? evt.keyCode : evt.which);
				keyCode = Keyboard.nmeConvertMozillaCode(keyCode);
				
				nmeOnKey(keyCode, true, evt.charCode, evt.ctrlKey, evt.altKey, evt.shiftKey, evt.keyLocation);
			
			case "keyup":
				
				var evt:js.html.KeyboardEvent = cast evt;
				var keyCode = (evt.keyCode != null ? evt.keyCode : evt.which);
				keyCode = Keyboard.nmeConvertMozillaCode(keyCode);
				
				nmeOnKey(keyCode, false, evt.charCode, evt.ctrlKey, evt.altKey, evt.shiftKey, evt.keyLocation);
			
			case "touchstart":
				
				var evt:js.html.TouchEvent = cast evt;
				evt.preventDefault();
				var touchInfo = new TouchInfo();
				nmeTouchInfo[evt.changedTouches[0].identifier] = touchInfo;
				nmeOnTouch(evt, evt.changedTouches[0], TouchEvent.TOUCH_BEGIN, touchInfo, false);
			
			case "touchmove":
				
				var evt:js.html.TouchEvent = cast evt;
				var touchInfo = nmeTouchInfo[evt.changedTouches[0].identifier];
				nmeOnTouch(evt, evt.changedTouches[0], TouchEvent.TOUCH_MOVE, touchInfo, true);
			
			case "touchend":
				
				var evt:js.html.TouchEvent = cast evt;
				var touchInfo = nmeTouchInfo[evt.changedTouches[0].identifier];
				nmeOnTouch(evt, evt.changedTouches[0], TouchEvent.TOUCH_END, touchInfo, true);
				nmeTouchInfo[evt.changedTouches[0].identifier] = null;
			
			case Lib.HTML_ACCELEROMETER_EVENT_TYPE:
				
				var evt:DeviceMotionEvent = cast evt;
				nmeHandleAccelerometer(evt);
			
			case Lib.HTML_ORIENTATION_EVENT_TYPE:
				
				nmeHandleOrientationChange();
			
			default:
			
		}
		
	}
	
	
	public function nmeQueueStageEvent(evt:js.html.Event):Void {
		
		nmeUIEventsQueue[nmeUIEventsQueueIndex++] = evt;
		
	}
	
	
	public function nmeRenderAll() {
		
		nmeRender(null, null);
		
	}
	
	
	public function nmeRenderToCanvas(canvas:CanvasElement):Void {
		
		canvas.width = canvas.width;
		nmeRender(canvas);
		
	}
	
	
	private function nmeStageRender(?_) {
		
		if (!nmeStageActive) {
			
			nmeOnResize(nmeWindowWidth, nmeWindowHeight);
			var event = new Event(Event.ACTIVATE);
			event.target = this;
			nmeBroadcast(event);
			nmeStageActive = true;
			
		}
		
		// Dispatch all queued UI events before the main render loop.
		for (i in 0...nmeUIEventsQueueIndex) {
			
			if (nmeUIEventsQueue[i] != null) {
				
				nmeProcessStageEvent(nmeUIEventsQueue[i]);
				
			}
			
		}
		
		nmeUIEventsQueueIndex = 0;
		
		var event = new Event(Event.ENTER_FRAME);
		this.nmeBroadcast(event);
		
		if (nmeInvalid) {
			
			var event = new Event(Event.RENDER);
			this.nmeBroadcast(event);
			
		}
		
		this.nmeRenderAll();
		
	}
	
	
	public function nmeStartDrag(sprite:Sprite, lockCenter:Bool = false, bounds:Rectangle = null) {
		
		nmeDragBounds = (bounds==null) ? null : bounds.clone();
		nmeDragObject = sprite;
		
		if (nmeDragObject != null) {
			
			var mouse = new Point(_mouseX, _mouseY);
			var p = nmeDragObject.parent;
			
			if (p != null) {
				
				mouse = p.globalToLocal(mouse);
				
			}
			
			if (lockCenter) {
				
				var bounds = sprite.getBounds(this);
				nmeDragOffsetX = nmeDragObject.x - (bounds.width / 2 + bounds.x);
				nmeDragOffsetY = nmeDragObject.y - (bounds.height / 2 + bounds.y);
				
			} else {
				
				nmeDragOffsetX = nmeDragObject.x - mouse.x;
				nmeDragOffsetY = nmeDragObject.y - mouse.y;
				
			}
			
		}
		
	}
	
	
	public function nmeStopDrag(sprite:Sprite):Void {
		
		nmeDragBounds = null;
		nmeDragObject = null;
		
	}
	
	
	public function nmeUpdateNextWake():Void {
		
		if (nmeFrameRate == 0) {
			
			var nmeRequestAnimationFrame:Dynamic = untyped __js__("window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame");
			nmeRequestAnimationFrame(nmeUpdateNextWake);
			nmeStageRender();
			
		} else {
			
			Browser.window.clearInterval(nmeTimer);
			//nmeTimer = Browser.window.setInterval(cast nmeStageRender, nmeInterval, []);
			nmeTimer = Browser.window.setInterval(cast nmeStageRender, nmeInterval);
			
		}
		
	}
	
	
	override public function toString():String {
		
		return "[Stage id=" + _nmeId + "]";
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function nmeHandleAccelerometer(evt:DeviceMotionEvent):Void {
		
		nmeAcceleration.x = evt.accelerationIncludingGravity.x;
		nmeAcceleration.y = evt.accelerationIncludingGravity.y;
		nmeAcceleration.z = evt.accelerationIncludingGravity.z;
		
	}
	
	
	private function nmeHandleOrientationChange():Void {
		
		//js.Lib.alert("orientation: " + getOrientation());
		
	}
	
	
	private function nmeOnKey(code:Int, pressed:Bool, inChar:Int, ctrl:Bool, alt:Bool, shift:Bool, keyLocation:Int) {
		
		var event = new KeyboardEvent(pressed ? KeyboardEvent.KEY_DOWN : KeyboardEvent.KEY_UP, true, false, inChar, code, keyLocation, ctrl, alt, shift);
		dispatchEvent(event);
		
	}
	
	
	private function nmeOnFocus(event:Dynamic, hasFocus:Bool) {
		
		if (hasFocus) {
			
			dispatchEvent (new FocusEvent (FocusEvent.FOCUS_IN));
			nmeBroadcast (new Event (Event.ACTIVATE));
			
		} else {
			
			dispatchEvent (new FocusEvent (FocusEvent.FOCUS_OUT));
			nmeBroadcast (new Event (Event.DEACTIVATE));
			
		}
		
	}
	
	
	private function nmeOnMouse(event:js.html.MouseEvent, type:String) {
		
		var point:Point = untyped new Point(event.clientX - Lib.mMe.__scr.offsetLeft + window.pageXOffset, event.clientY - Lib.mMe.__scr.offsetTop + window.pageYOffset);
		
		if (nmeDragObject != null) {
			
			nmeDrag(point);
			
		}
		
		var obj = nmeGetObjectUnderPoint(point);
		
		// used in drag implementation
		_mouseX = point.x;
		_mouseY = point.y;
		
		var stack = new Array<InteractiveObject>();
		if (obj != null) obj.nmeGetInteractiveObjectStack(stack);
		
		if (stack.length > 0) {
			
			//var global = obj.localToGlobal(point);
			//var obj = stack[0];
			
			stack.reverse();
			var local = obj.globalToLocal(point);
			var evt = MouseEvent.nmeCreate(type, event, local, cast obj);
			
			nmeCheckInOuts(evt, stack);
			if (type == MouseEvent.MOUSE_DOWN) nmeCheckFocusInOuts(cast evt, stack);
			
			obj.nmeFireEvent(evt);
			
		} else {
			
			var evt = MouseEvent.nmeCreate(type, event, point, null);
			nmeCheckInOuts(evt, stack);
			if (type == MouseEvent.MOUSE_DOWN) nmeCheckFocusInOuts(cast evt, stack);
			
		}
		
	}
	
	
	public function nmeOnResize(inW:Int, inH:Int):Void {
		
		nmeWindowWidth = inW;
		nmeWindowHeight = inH;
		
		var event = new Event(Event.RESIZE);
		event.target = this;
		nmeBroadcast(event);
		
	}
	
	
	private function nmeOnTouch(event:js.html.TouchEvent, touch:js.html.Touch, type:String, touchInfo:TouchInfo, isPrimaryTouchPoint:Bool):Void {
		
		var point:Point = untyped new Point(touch.pageX - Lib.mMe.__scr.offsetLeft + window.pageXOffset, touch.pageY - Lib.mMe.__scr.offsetTop + window.pageYOffset);
		var obj = nmeGetObjectUnderPoint(point);
		
		// used in drag implementation
		_mouseX = point.x;
		_mouseY = point.y;
		
		var stack = new Array<InteractiveObject>();
		if (obj != null) obj.nmeGetInteractiveObjectStack(stack);
		
		if (stack.length > 0) {
			
			//var obj = stack[0];
			
			stack.reverse();
			var local = obj.globalToLocal(point);
			var evt = TouchEvent.nmeCreate(type, event, touch, local, cast obj);
			
			evt.touchPointID = touch.identifier;
			evt.isPrimaryTouchPoint = isPrimaryTouchPoint;
			
			nmeCheckInOuts(evt, stack, touchInfo);
			obj.nmeFireEvent(evt);
			
			var mouseType = switch (type) {
				
				case TouchEvent.TOUCH_BEGIN: MouseEvent.MOUSE_DOWN;
				case TouchEvent.TOUCH_END: MouseEvent.MOUSE_UP;
				default: 
					
					if (nmeDragObject != null) {
						
						nmeDrag(point);
						
					}
					
					MouseEvent.MOUSE_MOVE;
				
			}
			
			obj.nmeFireEvent(MouseEvent.nmeCreate(mouseType, cast evt, local, cast obj));
			
		} else {
			
			var evt = TouchEvent.nmeCreate(type, event, touch, point, null);
			evt.touchPointID = touch.identifier;
			evt.isPrimaryTouchPoint = isPrimaryTouchPoint;
			nmeCheckInOuts(evt, stack, touchInfo);
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_backgroundColor():Int { return nmeBackgroundColour; }
	private function set_backgroundColor(col:Int):Int { return nmeBackgroundColour = col; }
	
	
	private inline function get_displayState():StageDisplayState { return this.displayState; }
	private function set_displayState(displayState:StageDisplayState):StageDisplayState {
		
		if (displayState != this.displayState && this.displayState != null) {
			
			switch (displayState) {
				
				case NORMAL: Lib.nmeDisableFullScreen();
				case FULL_SCREEN: Lib.nmeEnableFullScreen();
				
			}
			
		}
		
		this.displayState = displayState;
		return displayState;
		
	}
	
	
	private function get_focus():InteractiveObject { return nmeFocusObject; }
	private function set_focus(inObj:InteractiveObject):InteractiveObject { return nmeFocusObject = inObj; }
	
	
	private function get_frameRate():Float { return nmeFrameRate; }
	private function set_frameRate(speed:Float):Float {
		
		if (speed == 0) {
			
			var window = Browser.window;
			var nmeRequestAnimationFrame:Dynamic = untyped __js__("window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame");
			
			if (nmeRequestAnimationFrame == null) {
				
				speed = 60;
				
			}
			
		}
		
		if (speed != 0) {
			
			nmeInterval = Std.int( 1000.0/speed );
			
		}
		
		nmeFrameRate = speed;
		nmeUpdateNextWake();
		
		return speed;
	}
	
	
	private inline function get_fullScreenWidth():Int { return Lib.nmeFullScreenWidth(); }
	private inline function get_fullScreenHeight():Int { return Lib.nmeFullScreenHeight(); }
	
	
	private override function get_mouseX():Float { return _mouseX; }
	private override function get_mouseY():Float { return _mouseY; }
	
	
	private function get_quality():String { return this.quality != null ? this.quality : StageQuality.BEST; }
	private function set_quality(inQuality:String):String { return this.quality = inQuality; }
	
	
	private inline function get_showDefaultContextMenu():Bool { return nmeShowDefaultContextMenu; }
	private function set_showDefaultContextMenu(showDefaultContextMenu:Bool):Bool {
		
		if (showDefaultContextMenu != this.showDefaultContextMenu && this.showDefaultContextMenu != null) {
			
			if (!showDefaultContextMenu) {
				
				Lib.nmeDisableRightClick(); 
				
			} else {
				
				Lib.nmeEnableRightClick();
				
			}
			
		}
		
		nmeShowDefaultContextMenu = showDefaultContextMenu;
		return showDefaultContextMenu;
		
	}
	
	
	override private function get_stage():Stage {
		
		return Lib.nmeGetStage();
		
	}
	
	
	private function get_stageHeight():Int { return nmeWindowHeight; }
	private function get_stageWidth():Int { return nmeWindowWidth; }
	
	
}


private class TouchInfo {
	
	
	public var touchOverObjects:Array<InteractiveObject>;
	
	
	public function new() {
		
		touchOverObjects = [];
		
	}
	
	
}


#end