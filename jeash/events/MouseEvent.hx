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

package jeash.events;

import jeash.geom.Point;
import jeash.display.InteractiveObject;

class MouseEvent extends Event
{
	public var altKey : Bool;
	public var buttonDown : Bool;
	public var ctrlKey : Bool;
	public var delta : Int;
	public var localX : Float;
	public var localY : Float;
	public var relatedObject : jeash.display.InteractiveObject;
	public var shiftKey : Bool;
	public var stageX : Float;
	public var stageY : Float;
	public var commandKey : Bool;
	public var clickCount : Int;

	public static var CLICK : String = "click";
	public static var DOUBLE_CLICK : String = "doubleClick";
	public static var MOUSE_DOWN : String = "mouseDown";
	public static var MOUSE_MOVE : String = "mouseMove";
	public static var MOUSE_OUT : String = "mouseOut";
	public static var MOUSE_OVER : String = "mouseOver";
	public static var MOUSE_UP : String = "mouseUp";
	public static var MOUSE_WHEEL : String = "mouseWheel";
	public static var ROLL_OUT : String = "rollOut";
	public static var ROLL_OVER : String = "rollOver";

	public function new(type : String, 
			bubbles : Bool = true, 
			cancelable : Bool = false,
			localX : Float = 0,
			localY : Float = 0,
			?relatedObject : jeash.display.InteractiveObject,
			ctrlKey : Bool = false,
			altKey : Bool = false,
			shiftKey : Bool = false,
			buttonDown : Bool = false,
			delta : Int = 0,
			commandKey : Bool = false,
			clickCount : Int = 0) {
		super(type, bubbles, cancelable);

		this.shiftKey = shiftKey;
		this.altKey = altKey;
		this.ctrlKey = ctrlKey;
		this.bubbles = bubbles;
		this.relatedObject = relatedObject;
		this.delta = delta;
		this.localX = localX;
		this.localY = localY;
		this.buttonDown = buttonDown;
		this.commandKey = commandKey;
		this.clickCount = clickCount;
	}

	public static function jeashCreate(type:String, event:Html5Dom.MouseEvent, local:Point, target:InteractiveObject) {
		var jeashMouseDown:Bool = false;

		// cross-browser mouse wheel delta sniff
		var delta = if ( type == jeash.events.MouseEvent.MOUSE_WHEEL )
		{
			var mouseEvent : Dynamic = event;
			if (mouseEvent.wheelDelta) { /* IE/Opera. */
				#if !haxe_210
				if ( js.Lib.isOpera )
					Std.int(mouseEvent.wheelDelta/40);
				else
				#end
					Std.int(mouseEvent.wheelDelta/120);
			} else if (mouseEvent.detail) { /** Mozilla case. */
				Std.int(-mouseEvent.detail);
			}

		} else { 2; }

		// source: http://unixpapa.com/js/mouse.html
		if (type == jeash.events.MouseEvent.MOUSE_DOWN)
			jeashMouseDown = if ( event.which != null ) 
				event.which == 1
			else if (event.button != null) 
				#if haxe_210
				(event.button == 0) 
				#else
				(js.Lib.isIE && event.button == 1 || event.button == 0) 
				#end
			else false;
		else if (type == jeash.events.MouseEvent.MOUSE_UP)
			if ( event.which != null ) 
				if (event.which == 1)
					jeashMouseDown = false;
			else if (event.button != null) 
				#if haxe_210
				if (event.button == 0)
				#else
				if (js.Lib.isIE && event.button == 1 || event.button == 0) 
				#end
					jeashMouseDown = false;
			else 
				jeashMouseDown = false;

		var pseudoEvent = new jeash.events.MouseEvent(type,
				true, false,
				local.x,local.y,
				null,
				event.ctrlKey,
				event.altKey,
				event.shiftKey,
				jeashMouseDown,
				delta);

		pseudoEvent.stageX = Lib.current.stage.mouseX;
		pseudoEvent.stageY = Lib.current.stage.mouseY;
		pseudoEvent.target = target;
		return pseudoEvent;
	}

	override public function jeashCreateSimilar(type:String, ?related:InteractiveObject, ?targ:InteractiveObject) {
		var result = new MouseEvent(type, bubbles, cancelable, localX, localY,
				related==null ? relatedObject : related,
				ctrlKey, altKey, shiftKey, buttonDown, delta, commandKey, clickCount );

		if (targ!=null)
			result.target = targ;
		return cast result;
	}

	public function updateAfterEvent() { }
}

