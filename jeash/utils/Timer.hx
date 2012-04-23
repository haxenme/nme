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

package jeash.utils;

import jeash.events.EventDispatcher;
import jeash.events.TimerEvent;

/**
* @author Niel Drummond
* @author Russell Weir
**/
class Timer extends EventDispatcher {
	public var currentCount(default,null) : Int;
	public var delay(default,__setDelay) : Float;
	public var repeatCount(default,__setRepeatCount) : Int;
	public var running(default,null) : Bool;

	var timerId : Int;

	public function new(delay : Float, repeatCount : Int=0) : Void {
		super();
		this.running = false;
		this.delay = delay;
		this.repeatCount = repeatCount;
		this.currentCount = 0;
	}

	public function reset() : Void {
		stop();
		currentCount = 0;
	}

	public function start() : Void {
		if(running)
			return;
		running = true;
		
		timerId = untyped window.setTimeout(__onInterval, Std.int(delay));
	}

	public function stop() : Void {
		if (timerId != null) {
			untyped window.clearTimeout(timerId);
			timerId = null;
		}
		running = false;
	}

	private function __onInterval() : Void
	{
		var evtCom : TimerEvent = null;

		if( repeatCount != 0 && ++currentCount >= repeatCount ) {
			stop();
			evtCom = new TimerEvent(TimerEvent.TIMER_COMPLETE);
			evtCom.target = this;
		}

		var evt = new TimerEvent(TimerEvent.TIMER);
		evt.target = this;
		dispatchEvent(evt);
		// dispatch complete if necessary
		if(evtCom != null)
			dispatchEvent(evtCom);
	}

	private function __setDelay(v:Float) : Float
	{
		if(v != delay) {
			var wasRunning = running;
			if(running)
				stop();
			this.delay = v;
			if(wasRunning)
				start();
		}
		return v;
	}

	private function __setRepeatCount(v : Int ) : Int
	{
		if(running && v != 0 && v <= currentCount)
			stop();
		repeatCount = v;
		return v;
	}
}
