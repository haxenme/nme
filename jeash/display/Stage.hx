/**
 * Copyright (c) 2010, Jeash contributors.
 * 
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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package jeash.display;

import Html5Dom;

import jeash.Lib;
import jeash.ui.Keyboard;
import jeash.geom.Matrix;
import jeash.events.FocusEvent;
import jeash.events.Event;
import jeash.display.StageScaleMode;
import jeash.display.StageDisplayState;
import jeash.display.Graphics;
import jeash.geom.Point;
import jeash.geom.Rectangle;

class Stage extends DisplayObjectContainer
{
	var jeashWindowWidth : Int;
	var jeashWindowHeight : Int;
	var jeashTimer : Dynamic;
	var jeashInterval : Int;
	var jeashDragObject:DisplayObject;
	var jeashDragBounds:Rectangle;
	var jeashDragOffsetX:Float;
	var jeashDragOffsetY:Float;
	var jeashMouseOverObjects:Array<InteractiveObject>;
	var jeashStageMatrix:Matrix;
	var jeashStageActive:Bool;
	var jeashFrameRate:Float;
	var jeashBackgroundColour:Int;
	var jeashShowDefaultContextMenu:Bool;
	var jeashTouchInfo:Array<TouchInfo>;
	var jeashFocusOverObjects:Array<InteractiveObject>;
	var jeashUIEventsQueue:Array<Event>;
	var jeashUIEventsQueueIndex:Int;

	public var jeashPointInPathMode(default,null):PointInPathMode;

	public var stageWidth(jeashGetStageWidth,null):Int;
	public var stageHeight(jeashGetStageHeight,null):Int;
	public var frameRate(jeashGetFrameRate,jeashSetFrameRate):Float;
	public var quality(jeashGetQuality,jeashSetQuality):String;
	public var scaleMode:StageScaleMode;
	public var align:jeash.display.StageAlign;
	public var stageFocusRect:Bool;
	public var focus(jeashGetFocus,jeashSetFocus):InteractiveObject;
	public var backgroundColor(jeashGetBackgroundColour,jeashSetBackgroundColour):Int;
	public var showDefaultContextMenu(jeashGetShowDefaultContextMenu,jeashSetShowDefaultContextMenu):Bool;
	public var displayState(jeashGetDisplayState,jeashSetDisplayState):StageDisplayState;
	public var fullScreenWidth(jeashGetFullScreenWidth,null):UInt;
	public var fullScreenHeight(jeashGetFullScreenHeight,null):UInt;

	public function jeashGetStageWidth() { return jeashWindowWidth; }
	public function jeashGetStageHeight() { return jeashWindowHeight; }

	private var jeashFocusObject : InteractiveObject;
	static var jeashMouseChanges : Array<String> = [ jeash.events.MouseEvent.MOUSE_OUT, jeash.events.MouseEvent.MOUSE_OVER, jeash.events.MouseEvent.ROLL_OUT, jeash.events.MouseEvent.ROLL_OVER ];
	static var jeashTouchChanges : Array<String> = [ jeash.events.TouchEvent.TOUCH_OUT, jeash.events.TouchEvent.TOUCH_OVER,	jeash.events.TouchEvent.TOUCH_ROLL_OUT, jeash.events.TouchEvent.TOUCH_ROLL_OVER ];
	static inline var DEFAULT_FRAMERATE = 60.0;
	static inline var UI_EVENTS_QUEUE_MAX = 1000;

	public function new(width:Int, height:Int)
	{
		super();
		jeashFocusObject = null;
		jeashWindowWidth = width;
		jeashWindowHeight = height;
		stageFocusRect = false;
		scaleMode = StageScaleMode.SHOW_ALL;
		jeashStageMatrix = new Matrix();
		tabEnabled = true;
		frameRate=DEFAULT_FRAMERATE;
		jeashSetBackgroundColour(0xffffff);
		name = "Stage";
		loaderInfo = LoaderInfo.create(null);
		loaderInfo.parameters.width = Std.string(jeashWindowWidth);
		loaderInfo.parameters.height = Std.string(jeashWindowHeight);

		jeashPointInPathMode = Graphics.jeashDetectIsPointInPathMode();
		jeashMouseOverObjects = [];
		showDefaultContextMenu = true;
		jeashTouchInfo = [];
		jeashFocusOverObjects = [];
		jeashUIEventsQueue = untyped __new__("Array", UI_EVENTS_QUEUE_MAX);
		jeashUIEventsQueueIndex = 0;

		// bug in 2.07 release
		// displayState = StageDisplayState.NORMAL;
	}

	// @r551
	public function jeashStartDrag(sprite:Sprite, lockCenter:Bool = false, ?bounds:Rectangle)
	{
		jeashDragBounds = (bounds==null) ? null : bounds.clone();
		jeashDragObject = sprite;

		if (jeashDragObject!=null)
		{
			if (lockCenter)
			{
				var bounds = sprite.getBounds(this);
				jeashDragOffsetX = -bounds.width/2-bounds.x;
				jeashDragOffsetY = -bounds.height/2-bounds.y;
			}
			else
			{
				var mouse = new Point(mouseX,mouseY);
				var p = jeashDragObject.parent;

				if (p!=null)
					mouse = p.globalToLocal(mouse);

				jeashDragOffsetX = jeashDragObject.x - mouse.x;
				jeashDragOffsetY = jeashDragObject.y - mouse.y;
			}
		}
	}

	// @r551
	function jeashDrag(point:Point)
	{
		var p = jeashDragObject.parent;
		if (p!=null)
			point = p.globalToLocal(point);

		var x = point.x + jeashDragOffsetX;
		var y = point.y + jeashDragOffsetY;

		if (jeashDragBounds!=null)
		{
			if (x < jeashDragBounds.x) x = jeashDragBounds.x;
			else if (x > jeashDragBounds.right) x = jeashDragBounds.right;

			if (y < jeashDragBounds.y) y = jeashDragBounds.y;
			else if (y > jeashDragBounds.bottom) y = jeashDragBounds.bottom;
		}

		jeashDragObject.x = x;
		jeashDragObject.y = y;
	}

	public function jeashStopDrag(sprite:Sprite) : Void
	{
		jeashDragBounds = null;
		jeashDragObject = null;
	}

	function jeashCheckFocusInOuts(event:FocusEvent, inStack:Array<InteractiveObject>) {

		var new_n = inStack.length;
		var new_obj:InteractiveObject = new_n > 0 ? inStack[new_n - 1] : null;
		var old_n = jeashFocusOverObjects.length;
		var old_obj:InteractiveObject = old_n > 0 ? jeashFocusOverObjects[old_n - 1] : null;
		
		if (new_obj != old_obj)
		{
			// focusOver/focusOut goes only over the non-common objects in the tree...
			var common = 0;
			while (common < new_n && common < old_n && inStack[common] == jeashFocusOverObjects[common] )
				common++;
			
			var focusOut = new jeash.events.FocusEvent(jeash.events.FocusEvent.FOCUS_OUT, false, false, new_obj, false /* not implemented */, 0 /* not implemented */);
			
			var i = old_n - 1;
			while (i >= common) {
				jeashFocusOverObjects[i].dispatchEvent(focusOut);
				i--;
			}
			
			var focusIn = new jeash.events.FocusEvent(jeash.events.FocusEvent.FOCUS_IN, false, false, old_obj, false /* not implemented */, 0 /* not implemented */);
			var i = new_n - 1;
			
			while (i >= common) {
				inStack[i].dispatchEvent(focusIn);
				i--;
			}
			
			jeashFocusOverObjects = inStack;
			focus = new_obj;
		}
	}

	// @r551 without touch events
	private function jeashCheckInOuts(event:jeash.events.Event, stack:Array<InteractiveObject>, ?touchInfo:TouchInfo) {
		var prev = touchInfo == null ? jeashMouseOverObjects : touchInfo.touchOverObjects;
		var events = touchInfo == null ? jeashMouseChanges : jeashTouchChanges;

		var new_n = stack.length;
		var new_obj:InteractiveObject = new_n>0 ? stack[new_n-1] : null;
		var old_n = prev.length;
		var old_obj:InteractiveObject = old_n>0 ? prev[old_n-1] : null;
		if (new_obj!=old_obj) {
			// mouseOut/MouseOver goes up the object tree...
			if (old_obj!=null)
				old_obj.jeashFireEvent( event.jeashCreateSimilar(events[0], new_obj, old_obj) );

			if (new_obj!=null)
				new_obj.jeashFireEvent( event.jeashCreateSimilar(events[1], old_obj, new_obj) );

			// rollOver/rollOut goes only over the non-common objects in the tree...
			var common = 0;
			while(common<new_n && common<old_n && stack[common] == prev[common] )
				common++;

			var rollOut = event.jeashCreateSimilar(events[2], new_obj, old_obj);
			var i = old_n-1;
			while(i>=common) {
				prev[i].dispatchEvent(rollOut);
				i--;
			}

			var rollOver = event.jeashCreateSimilar(events[3],old_obj);
			var i = new_n-1;
			while(i>=common) {
				stack[i].dispatchEvent(rollOver);
				i--;
			}

			if (touchInfo == null)
				jeashMouseOverObjects = stack;
			else
				touchInfo.touchOverObjects = stack;
		}
	}

	public function jeashQueueStageEvent(evt:Html5Dom.Event)
		jeashUIEventsQueue[jeashUIEventsQueueIndex++] = evt

	public function jeashProcessStageEvent(evt:Html5Dom.Event) {
		evt.stopPropagation();

		switch(evt.type) {
			case "resize":
				jeashOnResize(jeashGetStageWidth(), jeashGetStageHeight());

			case "mousemove":
				jeashOnMouse(cast evt, jeash.events.MouseEvent.MOUSE_MOVE);

			case "mousedown":
				jeashOnMouse(cast evt, jeash.events.MouseEvent.MOUSE_DOWN);

			case "mouseup":
				jeashOnMouse(cast evt, jeash.events.MouseEvent.MOUSE_UP);

			case "click":
				jeashOnMouse(cast evt, jeash.events.MouseEvent.CLICK);

			case "mousewheel":
				jeashOnMouse(cast evt, jeash.events.MouseEvent.MOUSE_WHEEL);

			case "dblclick":
				jeashOnMouse(cast evt, jeash.events.MouseEvent.DOUBLE_CLICK);

			case "keydown":
				var evt:KeyboardEvent = cast evt; 
				var keyCode = if (evt.keyIdentifier != null)
					try {
						Keyboard.jeashConvertWebkitCode(evt.keyIdentifier);
					} catch (e:Dynamic) {
						#if debug
						jeash.Lib.trace("keydown error: " + e);
						#end
						evt.keyCode;
					}
				else
					Keyboard.jeashConvertMozillaCode(evt.keyCode);

				jeashOnKey( keyCode, true,
						evt.keyLocation,
						evt.ctrlKey, evt.altKey,
						evt.shiftKey );

			case "keyup":
				var evt:KeyboardEvent = cast evt; 
				var keyCode = if (evt.keyIdentifier != null)
					try {
						Keyboard.jeashConvertWebkitCode(evt.keyIdentifier);
					} catch (e:Dynamic) {
						#if debug
						jeash.Lib.trace("keyup error: " + e);
						#end
						evt.keyCode;
					}
				else
					Keyboard.jeashConvertMozillaCode(evt.keyCode);

				jeashOnKey( keyCode, false,
						evt.keyLocation,
						evt.ctrlKey, evt.altKey,
						evt.shiftKey );
					
			case "touchstart":
				var evt:TouchEvent = cast evt;
				evt.preventDefault();
				var touchInfo = new TouchInfo();
				jeashTouchInfo[evt.changedTouches[0].identifier] = touchInfo;
				jeashOnTouch(evt, evt.changedTouches[0], jeash.events.TouchEvent.TOUCH_BEGIN, touchInfo, false);

			case "touchmove":
				var evt:TouchEvent = cast evt;
				var touchInfo = jeashTouchInfo[evt.changedTouches[0].identifier];
				jeashOnTouch(evt, evt.changedTouches[0], jeash.events.TouchEvent.TOUCH_MOVE, touchInfo, true);

			case "touchend":
				var evt:TouchEvent = cast evt;
				var touchInfo = jeashTouchInfo[evt.changedTouches[0].identifier];
				jeashOnTouch(evt, evt.changedTouches[0], jeash.events.TouchEvent.TOUCH_END, touchInfo, true);
				jeashTouchInfo[evt.changedTouches[0].identifier] = null;

			default:
		}
	}

	// @r551
	function jeashOnMouse(event:Html5Dom.MouseEvent, type:String) {
		var point : Point = untyped 
			new Point(event.clientX - Lib.mMe.__scr.offsetLeft + window.pageXOffset, event.clientY - Lib.mMe.__scr.offsetTop + window.pageYOffset);

		if (jeashDragObject!=null)
			jeashDrag(point);

		var obj = jeashGetObjectUnderPoint(point);

		// used in drag implementation
		mouseX = point.x;
		mouseY = point.y;

		var stack = new Array<InteractiveObject>();
		if (obj!=null) obj.jeashGetInteractiveObjectStack(stack);

		if (stack.length > 0) {
			//var global = obj.localToGlobal(point);
			//var obj = stack[0];
			stack.reverse();
			var local = obj.globalToLocal(point);

			var evt = jeash.events.MouseEvent.jeashCreate(type, event, local, cast obj);

			jeashCheckInOuts(evt, stack);
			if (type == jeash.events.MouseEvent.MOUSE_DOWN) jeashCheckFocusInOuts(cast evt, stack);

			obj.jeashFireEvent(evt);
		} else {
			var evt = jeash.events.MouseEvent.jeashCreate(type, event, point, null);

			jeashCheckInOuts(evt, stack);
			if (type == jeash.events.MouseEvent.MOUSE_DOWN) jeashCheckFocusInOuts(cast evt, stack);
		}
	}

	// @r1095
	private function jeashOnTouch(event:TouchEvent, touch:Touch, type:String, touchInfo:TouchInfo, isPrimaryTouchPoint:Bool) {
		var point : Point = untyped 
			new Point(touch.pageX - Lib.mMe.__scr.offsetLeft + window.pageXOffset, touch.pageY - Lib.mMe.__scr.offsetTop + window.pageYOffset);

		var obj = jeashGetObjectUnderPoint(point);

		// used in drag implementation
		mouseX = point.x;
		mouseY = point.y;

		var stack = new Array<InteractiveObject>();
		if (obj!=null) obj.jeashGetInteractiveObjectStack(stack);

		if (stack.length > 0) {
			//var obj = stack[0];
			stack.reverse();
			var local = obj.globalToLocal(point);

			var evt = jeash.events.TouchEvent.jeashCreate(type, event, touch, local, cast obj);

			evt.touchPointID = touch.identifier;
			evt.isPrimaryTouchPoint = isPrimaryTouchPoint;

			jeashCheckInOuts(evt, stack, touchInfo);

			obj.jeashFireEvent(evt);

			var mouseType = switch (type) {
				case jeash.events.TouchEvent.TOUCH_BEGIN: jeash.events.MouseEvent.MOUSE_DOWN;
				case jeash.events.TouchEvent.TOUCH_END: jeash.events.MouseEvent.MOUSE_UP;
				default: 
					if (jeashDragObject != null) 
						jeashDrag(point);

					jeash.events.MouseEvent.MOUSE_MOVE;
			}

			obj.jeashFireEvent(jeash.events.MouseEvent.jeashCreate(mouseType, cast evt, local, cast obj));

		} else {
			var evt = jeash.events.TouchEvent.jeashCreate(type, event, touch, point, null);
			evt.touchPointID = touch.identifier;
			evt.isPrimaryTouchPoint = isPrimaryTouchPoint;
			jeashCheckInOuts(evt, stack, touchInfo);
		}
	}

	function jeashOnKey( code:Int , pressed : Bool, inChar:Int,
			ctrl:Bool, alt:Bool, shift:Bool )
	{
		var event = new jeash.events.KeyboardEvent(
				pressed ? jeash.events.KeyboardEvent.KEY_DOWN:
				jeash.events.KeyboardEvent.KEY_UP,
				true,false,
				inChar,
				code,
				(shift || ctrl) ? 1 : 0, // TODO
				ctrl,alt,shift);

		dispatchEvent(event);
	}


	public function jeashOnResize(inW:Int, inH:Int)
	{
		jeashWindowWidth = inW;
		jeashWindowHeight = inH;
		var event = new jeash.events.Event( jeash.events.Event.RESIZE );
		event.target = this;
		jeashBroadcast(event);
	}


	public function jeashGetBackgroundColour() { return jeashBackgroundColour; }
	public function jeashSetBackgroundColour(col:Int) : Int
	{
		jeashBackgroundColour = col;
		return col;
	}

	public function jeashSetFocus(inObj:InteractiveObject) { return jeashFocusObject = inObj; }
	public function jeashGetFocus() { return jeashFocusObject; }

	public function jeashRenderAll() {
		jeashRender(null, null);
	}

	public function jeashRenderToCanvas(canvas:HTMLCanvasElement) {
		canvas.width = canvas.width;

		jeashRender(null, canvas);
	}

	public function jeashSetQuality(inQuality:String):String {
		this.quality = inQuality;
		return inQuality;
	}

	public function jeashGetQuality():String
	{
		return if (this.quality != null)
			this.quality;
		else
			StageQuality.BEST;
	}

	function jeashGetFrameRate() { return jeashFrameRate; }
	function jeashSetFrameRate(speed:Float):Float {
		var window : Window = cast js.Lib.window;
		jeashInterval = Std.int( 1000.0/speed );

		jeashUpdateNextWake();

		jeashFrameRate = speed;
		return speed;
	}

	public function jeashUpdateNextWake () {
		var window : Window = cast js.Lib.window;
		window.clearInterval( jeashTimer );
		jeashTimer = window.setInterval( jeashStageRender, jeashInterval, [] );
	}

	function jeashStageRender (?_) {
		if (!jeashStageActive) {
			jeashOnResize(jeashWindowWidth, jeashWindowHeight);
			var event = new jeash.events.Event( jeash.events.Event.ACTIVATE );
			event.target = this;
			jeashBroadcast(event);
			jeashStageActive = true;
		}

		// Dispatch all queued UI events before the main render loop.
		for (i in 0...jeashUIEventsQueueIndex) {
			if (jeashUIEventsQueue[i] != null) {
				jeashProcessStageEvent(jeashUIEventsQueue[i]);
			}
		}
		jeashUIEventsQueueIndex = 0;

		var event = new jeash.events.Event( jeash.events.Event.ENTER_FRAME );
		this.jeashBroadcast(event);

		this.jeashRenderAll();
		
		var event = new jeash.events.Event( jeash.events.Event.RENDER );
		this.jeashBroadcast(event);
	}

	override function jeashIsOnStage() { return true; }
	override function jeashGetMouseX() { return this.mouseX; }
	override function jeashSetMouseX(x:Float) { this.mouseX = x; return x; }
	override function jeashGetMouseY() { return this.mouseY; }
	override function jeashSetMouseY(y:Float) { this.mouseY = y; return y; }

	inline function jeashGetShowDefaultContextMenu() { return jeashShowDefaultContextMenu; }
	function jeashSetShowDefaultContextMenu(showDefaultContextMenu:Bool)
	{
		if (showDefaultContextMenu != this.showDefaultContextMenu && this.showDefaultContextMenu != null)
			if (!showDefaultContextMenu) Lib.jeashDisableRightClick(); else Lib.jeashEnableRightClick();
		jeashShowDefaultContextMenu = showDefaultContextMenu;
		return showDefaultContextMenu;
	}

	inline function jeashGetDisplayState() { return this.displayState; }
	function jeashSetDisplayState(displayState:StageDisplayState)
	{
		if (displayState != this.displayState && this.displayState != null)
			switch (displayState) {
				case NORMAL: Lib.jeashDisableFullScreen();
				case FULL_SCREEN: Lib.jeashEnableFullScreen();
			}
		this.displayState = displayState;
		return displayState;
	}

	inline function jeashGetFullScreenWidth() { return Lib.jeashFullScreenWidth(); }
	inline function jeashGetFullScreenHeight() { return Lib.jeashFullScreenHeight(); }

}

class TouchInfo {
	public var touchOverObjects:Array<InteractiveObject>;
	public function new() touchOverObjects = []
}

