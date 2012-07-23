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

import jeash.Html5Dom;

import jeash.accessibility.AccessibilityProperties;
import jeash.display.Stage;
import jeash.display.Graphics;
import jeash.events.EventDispatcher;
import jeash.events.Event;
import jeash.events.EventPhase;
import jeash.display.DisplayObjectContainer;
import jeash.display.IBitmapDrawable;
import jeash.display.InteractiveObject;
import jeash.geom.Rectangle;
import jeash.geom.Matrix;
import jeash.geom.Point;
import jeash.geom.Transform;
import jeash.filters.BitmapFilter;
import jeash.display.BitmapData;
import jeash.Lib;

/**
 * @author	Niel Drummond
 * @author	Hugh Sanderson
 * @author	Russell Weir
 */
class DisplayObject extends EventDispatcher, implements IBitmapDrawable
{
	public var x(jeashGetX, jeashSetX):Float;
	public var y(jeashGetY, jeashSetY):Float;
	public var scaleX(jeashGetScaleX, jeashSetScaleX):Float;
	public var scaleY(jeashGetScaleY, jeashSetScaleY):Float;
	public var rotation(jeashGetRotation, jeashSetRotation):Float;
	
	public var accessibilityProperties:AccessibilityProperties;
	public var alpha:Float;
	public var name(default, default):String;
	public var cacheAsBitmap:Bool;
	public var width(jeashGetWidth, jeashSetWidth):Float;
	public var height(jeashGetHeight, jeashSetHeight):Float;

	public var visible(jeashGetVisible, jeashSetVisible):Bool;
	public var opaqueBackground(getOpaqueBackground, setOpaqueBackground):Null<Int>;
	public var mouseX(jeashGetMouseX, jeashSetMouseX):Float;
	public var mouseY(jeashGetMouseY, jeashSetMouseY):Float;
	public var parent(default, jeashSetParent):DisplayObjectContainer;
	public var stage(getStage, null):Stage;
	
	public var scrollRect(getScrollRect, setScrollRect):Rectangle;
	public var mask(getMask, setMask):DisplayObject;
	public var filters(jeashGetFilters, jeashSetFilters):Array<Dynamic>;
	public var blendMode:jeash.display.BlendMode;
	public var loaderInfo:LoaderInfo;

	public var transform(getTransform, setTransform):Transform;

	private var _graphicsDirty(never, setGraphicsDirty):Bool;
	var mBoundsDirty(getBoundsDirty, setBoundsDirty):Bool;
	var mMtxChainDirty:Bool;
	var mMtxDirty:Bool;
	
	var mBoundsRect : Rectangle;
	var mGraphicsBounds : Rectangle;
	var mScale9Grid : Rectangle;
	var mMatrix:Matrix;
	var mFullMatrix:Matrix;
	
	var jeashX : Float;
	var jeashY : Float;
	var jeashScaleX : Float;
	var jeashScaleY : Float;
	var jeashRotation : Float;
	var jeashVisible : Bool;
	var jeashLastOpacity:Float;

	static var mNameID = 0;

	var mScrollRect:Rectangle;
	var mOpaqueBackground:Null<Int>;

	var mMask:DisplayObject;
	var mMaskingObj:DisplayObject;
	var mMaskHandle:Dynamic;
	var jeashFilters:Array<BitmapFilter>;

	public function new() {
		parent = null;
		super(null);
		x = y = 0;
		jeashScaleX = jeashScaleY = 1.0;
		alpha = 1.0;
		rotation = 0.0;
		mMatrix = new Matrix();
		mFullMatrix = new Matrix();
		mMask = null;
		mMaskingObj = null;
		mBoundsRect = new Rectangle();
		mBoundsDirty = true;
		mGraphicsBounds = null;
		mMaskHandle = null;
		name = "DisplayObject " + mNameID++;
		jeashFilters = [];

		visible = true;
	}

	override public function toString() { return name; }

	private function jeashSetParent(inValue:DisplayObjectContainer):DisplayObjectContainer {
		if (inValue == this.parent) return inValue;

		mMtxChainDirty = true;

		if (this.parent != null) {
			this.parent.__removeChild(this);
			this.parent.jeashInvalidateBounds();	
		}
		
		if (inValue != null) {
			inValue.jeashInvalidateBounds();
		}

		if (this.parent == null && inValue != null) {
			this.parent = inValue;
			var evt = new jeash.events.Event(jeash.events.Event.ADDED, true, false);
			evt.target = this;
			dispatchEvent(evt);
		} else if (this.parent != null && inValue == null) {
			this.parent = inValue;
			var evt = new jeash.events.Event(jeash.events.Event.REMOVED, true, false);
			evt.target = this;
			dispatchEvent(evt);
		} else {
			this.parent = inValue;
		}
		return inValue;
	}

	private function getStage() {
		var gfx = jeashGetGraphics();
		if (gfx != null && Lib.jeashIsOnStage(gfx.jeashSurface))
			return jeash.Lib.jeashGetStage();
		return null;
	}

	private function getScrollRect() : Rectangle {
		if (mScrollRect == null) return null;
		return mScrollRect.clone();
	}

	private function setScrollRect(inRect:Rectangle) {
		mScrollRect = inRect;
		return getScrollRect();
	}

	private function jeashAsInteractiveObject() : jeash.display.InteractiveObject { return null; }

	public function hitTestObject(obj:DisplayObject) {
		return false;
	}

	public function hitTestPoint(x:Float, y:Float, ?shapeFlag:Bool) {
		var boundingBox:Bool = shapeFlag == null ? true : !shapeFlag;

		if (!boundingBox)
			return jeashGetObjectUnderPoint(new Point(x, y)) != null;
		else {
			var gfx = jeashGetGraphics();
			if (gfx != null) {
				var extX = gfx.jeashExtent.x;
				var extY = gfx.jeashExtent.y;
				var local = globalToLocal(new Point(x, y));
				if (local.x-extX < 0 || local.y-extY < 0 || (local.x-extX)*scaleX > width || (local.y-extY)*scaleY > height) 
					return false; 
				else 
					return true; 
			}
			return false;
		}
	}

	public function localToGlobal( point:Point ) {
		if (this.parent == null) {
			return new Point(this.x + point.x, this.y + point.y);
		} else {
			point.x = point.x + this.x;
			point.y = point.y + this.y;
			return this.parent.localToGlobal(point);
		}
	}

	private function jeashGetMouseX() { return globalToLocal(new Point(stage.mouseX, 0)).x; }
	private function jeashSetMouseX(x:Float) { return null; }
	private function jeashGetMouseY() { return globalToLocal(new Point(0, stage.mouseY)).y; }
	private function jeashSetMouseY(y:Float) { return null; }

	private function getTransform() { return  new Transform(this); }

	private function setTransform(trans:Transform) {
		mMatrix = trans.matrix.clone();
		return trans;
	}
	
	private function getFullMatrix(?childMatrix:Matrix=null) {
		if (childMatrix == null) {
			return mFullMatrix.clone();
		} else {
			return childMatrix.mult(mFullMatrix);
		}
	}

	public function getBounds(targetCoordinateSpace:DisplayObject) : Rectangle {
		if (mMtxDirty || mMtxChainDirty)
			jeashValidateMatrix();
		
		if (mBoundsDirty) {
			buildBounds();
		}
		
		var mtx : Matrix = mFullMatrix.clone();
		//perhaps inverse should be stored and updated lazily?
		if (targetCoordinateSpace != null) // will be null when target space is stage and this is not on stage
			mtx.concat(targetCoordinateSpace.mFullMatrix.clone().invert());
		var rect : Rectangle = mBoundsRect.transform(mtx);	//transform does cloning
		return rect;
	}

	public function getRect(targetCoordinateSpace : DisplayObject) : Rectangle {
		// TODO
		return null;
	}

	public function globalToLocal(inPos:Point) {
		return mFullMatrix.clone().invert().transformPoint(inPos);
	}

	public function jeashGetMatrix() {
		return mMatrix.clone();
	}

	public function jeashSetMatrix(inMatrix:Matrix) {
		mMatrix = inMatrix.clone();
		return inMatrix;
	}

	private function jeashGetGraphics() : jeash.display.Graphics {
		return null;
	}

	private function getOpaqueBackground() { 
		return mOpaqueBackground;
	}
	private function setOpaqueBackground(inBG:Null<Int>) {
		mOpaqueBackground = inBG;
		return mOpaqueBackground;
	}

	private function getBackgroundRect() {
		if (mGraphicsBounds == null) {
			var gfx = jeashGetGraphics();
			if (gfx != null)
				mGraphicsBounds = gfx.jeashExtent.clone();
		}
		return mGraphicsBounds;
	}
	
	/**
	 * Bounds are invalidated when:
	 * - a child is added or removed from a container
	 * - a child is scaled, rotated, translated, or skewed
	 * - the display of an object changes (graphics changed,
	 * bitmap loaded, textbox resized)
	 * - a child has its bounds invalidated
	 * ---> Invalidates down to stage
	 */
	//** internal **//
	//** FINAL **//	
	private function jeashInvalidateBounds():Void{
		//TODO :: adjust so that parent is only invalidated if it's bounds are changed by this change
		mBoundsDirty = true;
		if (parent != null)
			parent.jeashInvalidateBounds();
	}
	
	/**
	 * Matrices are invalidated when:
	 * - the object is scaled, rotated, translated, or skewed
	 * - an object's parent has its matrices invalidated
	 * ---> 	Invalidates up through children
	 */
	private function jeashInvalidateMatrix( ? local : Bool = false):Void {
		mMtxChainDirty = mMtxChainDirty || !local;	//note that a parent has an invalid matrix 
		mMtxDirty = mMtxDirty || local; //invalidate the local matrix
	}
	
	private function jeashValidateMatrix() {
		if (mMtxDirty || (mMtxChainDirty && parent!=null)) {
			//validate parent matrix
			if (mMtxChainDirty && parent != null) {
				parent.jeashValidateMatrix();
			}
			
			//validate local matrix
			if (mMtxDirty) {
				//update matrix if necessary
				//set non scale elements to identity
				mMatrix.b = mMatrix.c = mMatrix.tx = mMatrix.ty = 0;
			
				//set scale
				mMatrix.a = jeashScaleX;
				mMatrix.d = jeashScaleY;
			
				//set rotation if necessary
				var rad = jeashRotation * Math.PI / 180.0;
		
				if (rad != 0.0)
					mMatrix.rotate(rad);
			
				//set translation
				mMatrix.tx = jeashX;
				mMatrix.ty = jeashY;	
			}
			
			
			if (parent != null)
				mFullMatrix = parent.getFullMatrix(mMatrix);
			else
				mFullMatrix = mMatrix;
			
			mMtxDirty = mMtxChainDirty = false;
		}
	}

	private function jeashRender(inMatrix:Matrix, inMask:HTMLCanvasElement, ?clipRect:Rectangle) {
		var gfx = jeashGetGraphics();

		if (gfx != null) {
			// Cases when the rendering phase should be skipped
			if (!jeashVisible) return;

			if (mMtxDirty || mMtxChainDirty) {
				jeashValidateMatrix();
			}
			
			var m = if (inMatrix != null) inMatrix else mFullMatrix.clone();

			if (gfx.jeashRender(inMask, m, jeashFilters)) jeashInvalidateBounds();
					
			if (jeashFilters != null) {
				for (filter in jeashFilters) {
					filter.jeashApplyFilter(gfx.jeashSurface);
				}
			}

			m.tx += gfx.jeashExtentWithFilters.x*m.a + gfx.jeashExtentWithFilters.y*m.c;
			m.ty += gfx.jeashExtentWithFilters.x*m.b + gfx.jeashExtentWithFilters.y*m.d;

			var premulAlpha = (parent != null ? parent.alpha : 1) * alpha;
			if (inMask != null) {
				Lib.jeashDrawToSurface(gfx.jeashSurface, inMask, m, premulAlpha, clipRect);
			} else {
				// clipRect is ignored, used anywhere ?
				Lib.jeashSetSurfaceTransform(gfx.jeashSurface, m);
				if (premulAlpha != jeashLastOpacity) {
					Lib.jeashSetSurfaceOpacity(gfx.jeashSurface, premulAlpha);
					jeashLastOpacity = premulAlpha;
				}
			}
		} else {
			if (mMtxDirty || mMtxChainDirty) {
				jeashValidateMatrix();
			}
		}
	}

	public function drawToSurface(inSurface : Dynamic,
			matrix:jeash.geom.Matrix,
			colorTransform:jeash.geom.ColorTransform,
			blendMode:BlendMode,
			clipRect:jeash.geom.Rectangle,
			smoothing:Bool):Void {
		var oldAlpha = alpha;
		alpha = 1;
		if (matrix == null) matrix = new Matrix();
		jeashRender(matrix, inSurface, clipRect);
		alpha = oldAlpha;
	}

	private function jeashGetObjectUnderPoint(point:Point):DisplayObject {
		if (!visible) return null;
		var gfx = jeashGetGraphics();
		if (gfx != null) {
			var extX = gfx.jeashExtent.x;
			var extY = gfx.jeashExtent.y;
			var local = globalToLocal(point);
			if (local.x-extX < 0 || local.y-extY < 0 || (local.x-extX)*scaleX > width || (local.y-extY)*scaleY > height) return null; 
			switch (stage.jeashPointInPathMode) {
				case USER_SPACE:
					if (gfx.jeashHitTest(local.x, local.y))
						return cast this;
				case DEVICE_SPACE:
					if (gfx.jeashHitTest((local.x)*scaleX, (local.y)*scaleY))
						return cast this;
			}
		}

		return null;
	}

	// Masking
	private function getMask() : DisplayObject {
		return mMask;
	}

	private function setMask(inMask:DisplayObject) : DisplayObject {
		if (mMask != null)
			mMask.mMaskingObj = null;
		mMask = inMask;
		if (mMask != null)
			mMask.mMaskingObj = this;
		return mMask;
	}

	// @r533
	private function jeashSetFilters(filters:Array<Dynamic>) {
		var oldFilterCount = (jeashFilters == null) ? 0 : jeashFilters.length;

		if (filters == null) {
			jeashFilters = null;
			if (oldFilterCount > 0) _graphicsDirty = true;
		} else {
			jeashFilters = new Array<BitmapFilter>();
			for (filter in filters) jeashFilters.push(filter.clone());
			_graphicsDirty = true;
		}
		return filters;
	}

	private function setGraphicsDirty(inValue:Bool):Bool {
		var gfx = jeashGetGraphics();
		if (gfx != null)
			gfx.jeashChanged = gfx.jeashClearNextCycle = inValue;
		return inValue;
	}

	// @r533
	private function jeashGetFilters() {
		if (jeashFilters == null) return [];
		var result = new Array<BitmapFilter>();
		for (filter in jeashFilters)
			result.push(filter.clone());
		return result;
	}

	private function buildBounds() {
		var gfx = jeashGetGraphics();
		if (gfx == null) {
			mBoundsRect = new Rectangle(x, y, 0, 0);
		} else {
			mBoundsRect = gfx.jeashExtent.clone();
			if (mScale9Grid != null) {
				mBoundsRect.width *= scaleX;
				mBoundsRect.height *= scaleY;
			}
			gfx.boundsDirty = false;
		}
		mBoundsDirty = false;
	}

	private function getScreenBounds() {
		if (mBoundsDirty)
			buildBounds();
		return mBoundsRect.clone();
	}

	private function jeashGetInteractiveObjectStack(outStack:Array<InteractiveObject>) {
		var io = jeashAsInteractiveObject();
		if (io != null)
			outStack.push(io);
		if (this.parent != null)
			this.parent.jeashGetInteractiveObjectStack(outStack);
	}

	// @r551
	private function jeashFireEvent(event:jeash.events.Event) {
		var stack:Array<InteractiveObject> = [];
		if (this.parent != null)
			this.parent.jeashGetInteractiveObjectStack(stack);
		var l = stack.length;

		if (l > 0) {
			// First, the "capture" phase ...
			event.jeashSetPhase(EventPhase.CAPTURING_PHASE);
			stack.reverse();
			for (obj in stack) {
				event.currentTarget = obj;
				obj.jeashDispatchEvent(event);
				if (event.jeashGetIsCancelled())
					return;
			}
		}

		// Next, the "target"
		event.jeashSetPhase(EventPhase.AT_TARGET);
		event.currentTarget = this;
		jeashDispatchEvent(event);
		if (event.jeashGetIsCancelled())
			return;

		// Last, the "bubbles" phase
		if (event.bubbles) {
			event.jeashSetPhase(EventPhase.BUBBLING_PHASE);
			stack.reverse();
			for (obj in stack) {
				event.currentTarget = obj;
				obj.jeashDispatchEvent(event);
				if (event.jeashGetIsCancelled())
					return;
			}
		}
	}

	// @533
	private function jeashBroadcast(event:jeash.events.Event) {
		jeashDispatchEvent(event);
	}
	
	private function jeashDispatchEvent(event:jeash.events.Event):Bool {
		if (event.target == null) {
			event.target = this;
		}
		event.currentTarget = this;
		return super.dispatchEvent(event);
	}
	
	override public function dispatchEvent(event:jeash.events.Event):Bool {
		var result = jeashDispatchEvent(event);
		
		if (event.jeashGetIsCancelled())
			return true;
		
		if (event.bubbles && parent != null) {
			parent.dispatchEvent(event);
		}
		
		return result;
	}

	private function jeashAddToStage(newParent:DisplayObjectContainer, ?beforeSibling:DisplayObject) {
		var wasOnStage = (stage != null);
		var gfx = jeashGetGraphics();
		if (gfx == null) throw this + " tried to add to stage with null graphics context";

		if (newParent.jeashGetGraphics() != null) {
			Lib.jeashSetSurfaceId(gfx.jeashSurface, name);

			if (beforeSibling != null && beforeSibling.jeashGetGraphics() != null) {
				Lib.jeashAppendSurface(gfx.jeashSurface, beforeSibling.jeashGetGraphics().jeashSurface);
			} else {
				var stageChildren = [];
				for (child in newParent.jeashChildren) {
					if (child.stage != null)
						stageChildren.push(child);
				}

				if (stageChildren.length < 1) {
					Lib.jeashAppendSurface(gfx.jeashSurface, null, newParent.jeashGetGraphics().jeashSurface);
				} else {
					var nextSibling = stageChildren[stageChildren.length-1];
					var container;
					while (Std.is(nextSibling, DisplayObjectContainer)) {
						container = cast(nextSibling, DisplayObjectContainer);
						if (container.numChildren > 0)
							nextSibling = container.jeashChildren[container.numChildren-1];
						else
							break;
					}
					if (nextSibling.jeashGetGraphics() != gfx) {
						Lib.jeashAppendSurface(gfx.jeashSurface, null, nextSibling.jeashGetGraphics().jeashSurface);
					} else {
						Lib.jeashAppendSurface(gfx.jeashSurface);
					}
				}
			}
		} else {
			if (newParent.name == Stage.NAME) // only stage is allowed to add to a parent with no context
				Lib.jeashAppendSurface(gfx.jeashSurface);
		}

		if (!wasOnStage && stage != null) {
			var evt = new jeash.events.Event(jeash.events.Event.ADDED_TO_STAGE, false, false);
			evt.target = this;
			dispatchEvent(evt);
		}
	}

	private function jeashRemoveFromStage() {
		this.parent = null;

		var gfx = jeashGetGraphics();
		if (gfx != null && Lib.jeashIsOnStage(gfx.jeashSurface)) {
			Lib.jeashRemoveSurface(gfx.jeashSurface);

			var evt = new jeash.events.Event(jeash.events.Event.REMOVED_FROM_STAGE, false, false);
			evt.target = this;
			dispatchEvent(evt);
		}
	}

	private function jeashGetVisible() { return jeashVisible; }

	private function jeashSetVisible(visible:Bool) {
		var gfx = jeashGetGraphics();
		if (gfx != null)
			if (gfx.jeashSurface != null)
				Lib.jeashSetSurfaceVisible(gfx.jeashSurface, visible);
		jeashVisible = visible;
		return visible;
	}

	private function jeashGetHeight() : Float {
		if (mBoundsDirty) buildBounds();
		return jeashScaleY * mBoundsRect.height;
	}

	private function jeashSetHeight(inHeight:Float) : Float {
		if (parent != null)
			parent.jeashInvalidateBounds();
		if (mBoundsDirty)
			buildBounds();
		var h = mBoundsRect.height;
		if (jeashScaleY*h != inHeight) {
			if (h<=0) return 0;
			jeashScaleY = inHeight/h;
			jeashInvalidateMatrix(true);
		}
		return inHeight;
	}

	private function jeashGetWidth() : Float {
		if (mBoundsDirty) buildBounds();
		return jeashScaleX * mBoundsRect.width;
	}

	private function jeashSetWidth(inWidth:Float) : Float {
		if (parent != null)
			parent.jeashInvalidateBounds();
		if (mBoundsDirty)
			buildBounds();
		var w = mBoundsRect.width;
		if (jeashScaleX*w != inWidth) {
			if (w <= 0) return 0;
			jeashScaleX = inWidth/w;
			jeashInvalidateMatrix(true);
		}
		return inWidth;
	}

	private function jeashGetX():Float {
		return jeashX;
	}
	
	private function jeashGetY():Float {
		return jeashY;
	}
	
	private function jeashSetX(n:Float):Float {
		jeashInvalidateMatrix(true);
		jeashX = n;
		if (parent != null)
			parent.jeashInvalidateBounds();
		return n;
	}

	private function jeashSetY(n:Float):Float{
		jeashInvalidateMatrix(true);
		jeashY = n;
		if (parent != null)
			parent.jeashInvalidateBounds();
		return n;
	}

	private function jeashGetScaleX() { return jeashScaleX; }
	private function jeashGetScaleY() { return jeashScaleY; }
	private function jeashSetScaleX(inS:Float) { 
		if (jeashScaleX == inS)
			return inS;		
		if (parent != null)
			parent.jeashInvalidateBounds();
		if (mBoundsDirty)
			buildBounds();
		if (!mMtxDirty)
			jeashInvalidateMatrix(true);	
		jeashScaleX=inS;
		return inS;
	}

	private function jeashSetScaleY(inS:Float) { 
		if (jeashScaleY == inS)
			return inS;		
		if (parent != null)
			parent.jeashInvalidateBounds();
		if (mBoundsDirty)
			buildBounds();
		if (!mMtxDirty)
			jeashInvalidateMatrix(true);	
		jeashScaleY = inS;
		return inS;
	}

	private function jeashSetRotation(n:Float):Float{
		if (!mMtxDirty)
			jeashInvalidateMatrix(true);
		if (parent != null)
			parent.jeashInvalidateBounds();

		jeashRotation = n;
		return n;
	}
	
	private function jeashGetRotation():Float{
		return jeashRotation;
	}

	private function jeashUnifyChildrenWithDOM(lastMoveGfx:Graphics = null) {
		var gfx1 = jeashGetGraphics();
		if (gfx1 != null && lastMoveGfx != null) 
			Lib.jeashSetSurfaceZIndexAfter(gfx1.jeashSurface, lastMoveGfx.jeashSurface);
	}

	private function getBoundsDirty():Bool {
		var gfx = jeashGetGraphics();
		if (gfx == null)
			return mBoundsDirty;
		else
			return mBoundsDirty || gfx.boundsDirty;
	}

	private function setBoundsDirty(inValue:Bool):Bool {
		mBoundsDirty = inValue;
		return inValue;
	}
}

