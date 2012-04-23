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

import jeash.display.InteractiveObject;
import jeash.geom.Point;

class TouchEvent extends Event
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

	public var isPrimaryTouchPoint:Bool;
	public var touchPointID:Int;

	public static var TOUCH_BEGIN:String = "touchBegin";
	public static var TOUCH_END:String = "touchEnd";
	public static var TOUCH_MOVE:String = "touchMove";
	public static var TOUCH_OUT:String = "touchOut";
	public static var TOUCH_OVER:String = "touchOver";
	public static var TOUCH_ROLL_OUT:String = "touchRollOut";
	public static var TOUCH_ROLL_OVER:String = "touchRollOver";
	public static var TOUCH_TAP:String = "touchTap";

	public function new(type:String, 
			bubbles:Bool = true, 
			cancelable:Bool = false, 
			localX:Float = 0, 
			localY:Float = 0, 
			relatedObject:InteractiveObject = null, 
			ctrlKey:Bool = false, 
			altKey:Bool = false, 
			shiftKey:Bool = false, 
			buttonDown:Bool = false, 
			delta:Int = 0, 
			commandKey:Bool = false, 
			clickCount:Int = 0) {
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

		touchPointID = 0;
		isPrimaryTouchPoint = true;
	}
	
	public static function jeashCreate(type:String, event:Html5Dom.TouchEvent, touch:Html5Dom.Touch, local:Point, target:InteractiveObject) {
		var evt = new TouchEvent(type, true, false, 
				local.x, local.y, 
				null, 
				event.ctrlKey, event.altKey, event.shiftKey, 
				false /* note: buttonDown not supported on w3c spec */, 0, 0);
		evt.stageX = Lib.current.stage.mouseX;
		evt.stageY = Lib.current.stage.mouseY;
		evt.target = target;
		return evt;
	}
	
	override public function jeashCreateSimilar(type:String, ?related:InteractiveObject, ?targ:InteractiveObject) {
		var result = new TouchEvent(type, bubbles, cancelable, 
				localX, localY, 
				related == null ? relatedObject : related, 
				ctrlKey, altKey, shiftKey, 
				buttonDown, delta, commandKey);
		
		result.touchPointID = touchPointID;
		result.isPrimaryTouchPoint = isPrimaryTouchPoint;
		if (targ != null)
			result.target = targ;
		return cast result;
	}
	
}

