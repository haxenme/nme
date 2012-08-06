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

import jeash.display.DisplayObject;
import jeash.display.InteractiveObject;
import jeash.media.SoundTransform;
import jeash.events.MouseEvent;

class SimpleButton extends DisplayObjectContainer
{
	public var downState(default, jeashSetDownState) : DisplayObject;
	public var enabled : Bool;
	public var hitTestState(default, jeashSetHitTestState) : DisplayObject;
	public var overState(default, jeashSetOverState) : DisplayObject;
	public var soundTransform : SoundTransform;
	public var trackAsMenu : Bool;
	public var upState(default, jeashSetUpState) : DisplayObject;
	public var useHandCursor : Bool;

	var currentState (default, jeashSetCurrentState) : DisplayObject;

	public function new(?upState : DisplayObject, ?overState : DisplayObject, ?downState : DisplayObject, ?hitTestState : DisplayObject) {
		super();

		this.upState = (upState != null) ? upState : jeashGenerateDefaultState();
		this.overState = (overState != null) ? overState : jeashGenerateDefaultState();
		this.downState = (downState != null) ? downState : jeashGenerateDefaultState();
		this.hitTestState = (hitTestState != null) ? hitTestState : jeashGenerateDefaultState();

		currentState = this.upState;
	}

	override public function toString() { return "[SimpleButton name=" + this.name + " id=" + _jeashId + "]"; }

	function switchState(state:DisplayObject) {
		if (this.currentState != null && this.currentState.stage != null) {
			removeChild(this.currentState);
			addChild(state);
		} else {
			addChild(state);
		}
	}

	function jeashGenerateDefaultState () return new DisplayObject()

	function jeashSetCurrentState (state:DisplayObject) {
		switchState(state);
		return currentState = state;
	}

	function jeashSetHitTestState (hitTestState:DisplayObject) {
		if (hitTestState != this.hitTestState) {
			// Events bubble up to this instance.
			addEventListener(MouseEvent.MOUSE_OVER, function (_) { if (overState != currentState) currentState = overState; });
			addEventListener(MouseEvent.MOUSE_OUT, function (_) {  if (upState != currentState) currentState = upState; });
			addEventListener(MouseEvent.MOUSE_DOWN, function (_) { currentState = downState; });
			addEventListener(MouseEvent.MOUSE_UP, function (_) { currentState = upState; });

			hitTestState.alpha = 0.0;
			addChild(hitTestState);
		}
		return this.hitTestState = hitTestState;
	}

	function jeashSetDownState (downState:DisplayObject) {
		if (this.downState != null && currentState == this.downState) currentState = downState;
		return this.downState = downState;
	}

	function jeashSetOverState (overState:DisplayObject) {
		if (this.overState != null && currentState == this.overState) currentState = overState;
		return this.overState = overState;
	}

	function jeashSetUpState (upState:DisplayObject) {
		if (this.upState != null && currentState == this.upState) currentState = upState;
		return this.upState = upState;
	}

	override function jeashSetParent(displayObject : DisplayObjectContainer):DisplayObjectContainer {
		super.jeashSetParent(displayObject);
		if (currentState != null) {
			addChild(currentState);
			if (hitTestState != null) addChild(hitTestState);
			switchState(currentState);
		}
		return displayObject;
	}
}
