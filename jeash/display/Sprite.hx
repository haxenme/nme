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

import jeash.display.Graphics;
import jeash.display.InteractiveObject;
import jeash.geom.Matrix;
import jeash.geom.Rectangle;
import jeash.geom.Point;
import jeash.Lib;
import jeash.events.MouseEvent;

class Sprite extends DisplayObjectContainer {
	var jeashGraphics:Graphics;
	public var graphics(jeashGetGraphics,null):Graphics;
	public var useHandCursor(default,jeashSetUseHandCursor):Bool;
	public var buttonMode:Bool;
	public var dropTarget(jeashGetDropTarget,null):DisplayObject;

	var jeashCursorCallbackOver:Dynamic->Void;
	var jeashCursorCallbackOut:Dynamic->Void;
	var jeashDropTarget:DisplayObject;

	public function new() {
		jeashGraphics = new Graphics();
		super();
		buttonMode = false;
		name = "Sprite " + DisplayObject.mNameID++;
		Lib.jeashSetSurfaceId(jeashGraphics.jeashSurface, name);
	}

	public function startDrag(?lockCenter:Bool, ?bounds:Rectangle):Void {
		if (stage != null)
			stage.jeashStartDrag(this, lockCenter, bounds);
	}

	public function stopDrag():Void {
		if (stage != null) {
			stage.jeashStopDrag(this);
			var l = parent.jeashChildren.length-1;
			var obj:DisplayObject = stage;
			for(i in 0...parent.jeashChildren.length) {
				var result = parent.jeashChildren[l-i].jeashGetObjectUnderPoint(new Point(stage.mouseX, stage.mouseY));
				if (result != null) obj = result;
			}

			if (obj != this)
				jeashDropTarget = obj;
			else
				jeashDropTarget = stage;
		}
	}

	override public function jeashGetGraphics() { 
		return jeashGraphics; 
	}

	function jeashSetUseHandCursor(cursor:Bool) {
		if (cursor == this.useHandCursor) return cursor;

		if (jeashCursorCallbackOver != null)
			removeEventListener(MouseEvent.ROLL_OVER, jeashCursorCallbackOver);
		if (jeashCursorCallbackOut != null)
			removeEventListener(MouseEvent.ROLL_OUT, jeashCursorCallbackOut);

		if (!cursor) {
			Lib.jeashSetCursor(Default);
		} else {
			jeashCursorCallbackOver = function (_) { Lib.jeashSetCursor(Pointer); }
			jeashCursorCallbackOut = function (_) { Lib.jeashSetCursor(Default); }
			addEventListener(MouseEvent.ROLL_OVER, jeashCursorCallbackOver);
			addEventListener(MouseEvent.ROLL_OUT, jeashCursorCallbackOut);
		}
		this.useHandCursor = cursor;

		return cursor;
	}

	function jeashGetDropTarget() return jeashDropTarget

	// force monomorphic access for better JIT-ing
	override public function jeashSetX(n:Float):Float {
		jeashInvalidateMatrix(true);
		jeashX=n;
		if(parent!=null)
			parent.jeashInvalidateBounds();
		return n;
	}

	// force monomorphic access for better JIT-ing
	override public function jeashSetY(n:Float):Float {
		jeashInvalidateMatrix(true);
		jeashY=n;
		if(parent!=null)
			parent.jeashInvalidateBounds();
		return n;
	}

	// force monomorphic access for better JIT-ing
	override public function jeashSetScaleX(inS:Float) { 
		if(jeashScaleX==inS)
			return inS;		
		if(parent!=null)
			parent.jeashInvalidateBounds();
		if(mBoundsDirty)
			BuildBounds();
		if(!mMtxDirty)
			jeashInvalidateMatrix(true);	
		jeashScaleX=inS;
		return inS;
	}

	// force monomorphic access for better JIT-ing
	override public function jeashSetScaleY(inS:Float) { 
		if(jeashScaleY==inS)
			return inS;		
		if(parent!=null)
			parent.jeashInvalidateBounds();
		if(mBoundsDirty)
			BuildBounds();
		if(!mMtxDirty)
			jeashInvalidateMatrix(true);	
		jeashScaleY=inS;
		return inS;
	}

	// force monomorphic access for better JIT-ing
	override private function jeashSetRotation(n:Float):Float{
		if(!mMtxDirty)
			jeashInvalidateMatrix(true);
		if(parent!=null)
			parent.jeashInvalidateBounds();

		jeashRotation = n;
		return n;
	}
	
}

