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
import jeash.display.BlendMode;
import jeash.Lib;

/**
 * @author	Niel Drummond
 * @author	Hugh Sanderson
 * @author	Russell Weir
 */
class DisplayObject extends EventDispatcher, implements IBitmapDrawable
{
	private static inline var GRAPHICS_INVALID:Int 				= 1 << 1;
	private static inline var MATRIX_INVALID:Int 				= 1 << 2;
	private static inline var MATRIX_CHAIN_INVALID:Int 			= 1 << 3;
	private static inline var MATRIX_OVERRIDDEN:Int 			= 1 << 4;
	private static inline var TRANSFORM_INVALID:Int 			= 1 << 5;
	private static inline var BOUNDS_INVALID:Int 				= 1 << 6;
	
	private static inline var RENDER_VALIDATE_IN_PROGRESS:Int 	= 1 << 10;
		
	private static inline var ALL_RENDER_FLAGS:Int =
			GRAPHICS_INVALID |
			TRANSFORM_INVALID |
			BOUNDS_INVALID;

	private var _jeashRenderFlags:Int;

	private var _jeashId:String;

	private var jeashX:Float;
	public var x(jeashGetX, jeashSetX):Float;
	private var jeashY:Float;
	public var y(jeashGetY, jeashSetY):Float;
	private var _fullScaleX:Float;
	private var jeashScaleX:Float;
	public var scaleX(jeashGetScaleX, jeashSetScaleX):Float;
	private var _fullScaleY:Float;
	private var jeashScaleY:Float;
	public var scaleY(jeashGetScaleY, jeashSetScaleY):Float;
	private var jeashRotation:Float;
	public var rotation(jeashGetRotation, jeashSetRotation):Float;

	private var jeashWidth:Float;
	public var width(jeashGetWidth, jeashSetWidth):Float;
	private var jeashHeight:Float;
	public var height(jeashGetHeight, jeashSetHeight):Float;

	public var transform(default, setTransform):Transform;

	public var accessibilityProperties:AccessibilityProperties;
	public var alpha:Float;
	public var name:String;
	public var cacheAsBitmap:Bool;

	private var jeashVisible:Bool;
	public var visible(jeashGetVisible, jeashSetVisible):Bool;
	public var jeashCombinedVisible(default, jeashSetCombinedVisible):Bool;

	public var mouseX(jeashGetMouseX, never):Float;
	public var mouseY(jeashGetMouseY, never):Float;
	public var parent(default, jeashSetParent):DisplayObjectContainer;
	public var stage(getStage, never):Stage;
	
	private var jeashScrollRect:Rectangle;
	public var scrollRect(getScrollRect, setScrollRect):Rectangle;
	private var jeashMask:DisplayObject;
	private var jeashMaskingObj:DisplayObject;
	public var mask(getMask, setMask):DisplayObject;
	private var jeashFilters:Array<BitmapFilter>;
	public var filters(jeashGetFilters, jeashSetFilters):Array<Dynamic>;
	public var blendMode:BlendMode;
	public var scale9Grid:Rectangle;
	private var jeashBoundsRect:Rectangle;

	private var _boundsInvalid(getBoundsInvalid, never):Bool;
	private var _matrixChainInvalid(getMatrixChainInvalid, never):Bool;
	private var _matrixInvalid(getMatrixInvalid, never):Bool;

	private var _topmostSurface(getTopmostSurface, null):HTMLElement;
	private var _bottommostSurface(getBottommostSurface, null):HTMLElement;

	public function new() {
		super(null);

		_jeashId = jeash.utils.Uuid.uuid();
		parent = null;

		// initialize transform
		this.transform = new Transform(this);
		jeashX = jeashY = 0.0;
		jeashScaleX = jeashScaleY = 1.0;
		jeashRotation = 0.0;
		jeashWidth = jeashHeight = 0.0;

		// initialize graphics metadata
		visible = true;
		alpha = 1.0;
		jeashFilters = new Array<BitmapFilter>();
		jeashBoundsRect = new Rectangle();

		jeashScrollRect = null;
		jeashMask = null;
		jeashMaskingObj = null;
		jeashCombinedVisible = visible;
	}

	private function getTopmostSurface():HTMLElement {
		var gfx = jeashGetGraphics();
		if (gfx != null)
			return gfx.jeashSurface;
		return null;
	}

	private function getBottommostSurface():HTMLElement {
		var gfx = jeashGetGraphics();
		if (gfx != null)
			return gfx.jeashSurface;
		return null;
	}

	override public function toString() { return "[DisplayObject name=" + this.name + " id=" + _jeashId + "]"; }

	private function jeashSetParent(inValue:DisplayObjectContainer):DisplayObjectContainer {
		if (inValue == this.parent) return inValue;

		jeashInvalidateMatrix();

		if (this.parent != null) {
			this.parent.__removeChild(this);
			this.parent.jeashInvalidateBounds();	
		}

		if (inValue != null)
			inValue.jeashInvalidateBounds();

		if (this.parent == null && inValue != null) {
			this.parent = inValue;
			var evt = new jeash.events.Event(jeash.events.Event.ADDED, true, false);
			dispatchEvent(evt);
		} else if (this.parent != null && inValue == null) {
			this.parent = inValue;
			var evt = new jeash.events.Event(jeash.events.Event.REMOVED, true, false);
			dispatchEvent(evt);
		} else {
			this.parent = inValue;
		}
		return inValue;
	}

	private function getStage() {
		var gfx = jeashGetGraphics();
		if (gfx != null)
			return jeash.Lib.jeashGetStage();
		return null;
	}

	private function jeashIsOnStage() {
		var gfx = jeashGetGraphics();
		if (gfx != null && Lib.jeashIsOnStage(gfx.jeashSurface))
			return true;
		return false;
	}

	private function getScrollRect() : Rectangle {
		if (jeashScrollRect == null) return null;
		return jeashScrollRect.clone();
	}

	private function setScrollRect(inValue:Rectangle) {
		jeashScrollRect = inValue;
		return inValue;
	}

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

	private function jeashGetMouseX() { return globalToLocal(new Point(stage.mouseX, 0)).x; }
	private function jeashGetMouseY() { return globalToLocal(new Point(0, stage.mouseY)).y; }

	private function setTransform(inValue:Transform) {
		this.transform = inValue;
		jeashInvalidateMatrix(true);
		return inValue;
	}

	public function getBounds(targetCoordinateSpace:DisplayObject):Rectangle {
		if (_matrixInvalid || _matrixChainInvalid)
			jeashValidateMatrix();
		
		if (_boundsInvalid)
			validateBounds();
		
		var m:Matrix = jeashGetFullMatrix();
		// perhaps inverse should be stored and updated lazily?
		if (targetCoordinateSpace != null) // will be null when target space is stage and this is not on stage
			m.concat(targetCoordinateSpace.jeashGetFullMatrix().invert());
		var rect:Rectangle = jeashBoundsRect.transform(m);	// transform does cloning
		return rect;
	}

	public function getRect(targetCoordinateSpace:DisplayObject):Rectangle {
		// should not account for stroke widths, but is that possible?
		return getBounds(targetCoordinateSpace);
	}

	public function globalToLocal(inPos:Point) {
		if (_matrixInvalid || _matrixChainInvalid)
			jeashValidateMatrix();
		
		return jeashGetFullMatrix().invert().transformPoint(inPos);
	}

	public function localToGlobal( point:Point ) {
		if (_matrixInvalid || _matrixChainInvalid)
			jeashValidateMatrix();
		
		var matrix = jeashGetFullMatrix();
		return jeashGetFullMatrix().transformPoint(point);
	}

	private inline function jeashGetMatrix():Matrix {
		return transform.matrix;
	}

	private inline function jeashSetMatrix(inValue:Matrix):Matrix {
		transform.jeashSetMatrix(inValue);
		return inValue;
	}

 	public inline function jeashGetFullMatrix(?localMatrix:Matrix) {
		return transform.jeashGetFullMatrix(localMatrix);
	}

 	public inline function jeashSetFullMatrix(inValue:Matrix) {
		return transform.jeashSetFullMatrix(inValue);
	}

	private function jeashGetGraphics():Graphics {
		return null;
	}

	private inline function jeashGetSurface():HTMLCanvasElement {
		var gfx = jeashGetGraphics();
		var surface = null;
		if (gfx != null)
			surface = gfx.jeashSurface;
		return surface;
	}
	
	/**
	 * Matrices are invalidated when:
	 * - the object is scaled, rotated, translated, or skewed
	 * - an object's parent has its matrices invalidated
	 * ---> 	Invalidates up through children
	 */
	public function jeashInvalidateMatrix(?local:Bool=false):Void {
		if (local) {
			jeashSetFlag(MATRIX_INVALID);		// invalidate the local matrix
		} else {
			jeashSetFlag(MATRIX_CHAIN_INVALID);	// a parent has an invalid matrix
		}
	}

	public function jeashMatrixOverridden():Void {
		jeashSetFlag(MATRIX_OVERRIDDEN);
		jeashSetFlag(MATRIX_INVALID);
		jeashInvalidateBounds();
	}
	
	private function jeashValidateMatrix() {
		var parentMatrixInvalid = _matrixChainInvalid && parent != null;
		if (_matrixInvalid || parentMatrixInvalid) {
			// validate parent matrix
			if (parentMatrixInvalid)
				parent.jeashValidateMatrix();

			// validate local matrix
			var m = jeashGetMatrix();

			if (jeashTestFlag(MATRIX_OVERRIDDEN))
				jeashClearFlag(MATRIX_INVALID);

			if (_matrixInvalid) {
				// update matrix if necessary
				m.identity();
			
				// set scale
				m.scale(jeashScaleX, jeashScaleY);
			
				// set rotation if necessary
				var rad = jeashRotation * Transform.DEG_TO_RAD;
				if (rad != 0.0)
					m.rotate(rad);
			
				// set translation
				m.translate(jeashX, jeashY);

				jeashSetMatrix(m);
			}
			
			var cm = jeashGetFullMatrix();
			var fm = parent == null ? m : parent.jeashGetFullMatrix(m);
			_fullScaleX = fm._sx;
			_fullScaleY = fm._sy;

			if (cm.a != fm.a
					|| cm.b != fm.b
					|| cm.c != fm.c
					|| cm.d != fm.d
					|| cm.tx != fm.tx
					|| cm.ty != fm.ty) {
				jeashSetFullMatrix(fm);
				jeashSetFlag(TRANSFORM_INVALID);
			}
			jeashClearFlag(MATRIX_INVALID | MATRIX_CHAIN_INVALID | MATRIX_OVERRIDDEN);
		}
	}

	private inline function jeashApplyFilters(surface:HTMLCanvasElement) {
		if (jeashFilters != null) {
			for (filter in jeashFilters)
				filter.jeashApplyFilter(surface);
		} 
	}

	private function jeashRender(?inMask:HTMLCanvasElement, ?clipRect:Rectangle) {
		if (!jeashCombinedVisible) return;

		var gfx = jeashGetGraphics();
		if (gfx == null) return;

		if (_matrixInvalid || _matrixChainInvalid)
			jeashValidateMatrix();

		/*
		var clip0:Point = null;
		var clip1:Point = null;
		var clip2:Point = null;
		var clip3:Point = null;
		if (clipRect != null) {
			var topLeft = clipRect.topLeft;
			var topRight = clipRect.topLeft.clone();
			topRight.x += clipRect.width;
			var bottomRight = clipRect.bottomRight;
			var bottomLeft = clipRect.bottomRight.clone();
			bottomLeft.x -= clipRect.width;
			clip0 = this.globalToLocal(this.parent.localToGlobal(topLeft));
			clip1 = this.globalToLocal(this.parent.localToGlobal(topRight));
			clip2 = this.globalToLocal(this.parent.localToGlobal(bottomRight));
			clip3 = this.globalToLocal(this.parent.localToGlobal(bottomLeft));
		}
		*/
		if (gfx.jeashRender(inMask, jeashFilters, 1, 1))
			handleGraphicsUpdated(gfx);

		var fullAlpha:Float = (parent != null ? parent.jeashCombinedAlpha : 1) * alpha;
		if (inMask != null) {
			var m = getSurfaceTransform(gfx);
			Lib.jeashDrawToSurface(gfx.jeashSurface, inMask, m, fullAlpha, clipRect);
		} else {
			if (jeashTestFlag(TRANSFORM_INVALID)) {
				var m = getSurfaceTransform(gfx);
				Lib.jeashSetSurfaceTransform(gfx.jeashSurface, m);
				jeashClearFlag(TRANSFORM_INVALID);
			}
			Lib.jeashSetSurfaceOpacity(gfx.jeashSurface, fullAlpha);
			/*if (clipRect != null) {
				var rect = new Rectangle();
				rect.topLeft = this.globalToLocal(this.parent.localToGlobal(clipRect.topLeft));
				rect.bottomRight = this.globalToLocal(this.parent.localToGlobal(clipRect.bottomRight));
				Lib.jeashSetSurfaceClipping(gfx.jeashSurface, rect);
			}*/
		}
	}

	private inline function handleGraphicsUpdated(gfx:Graphics):Void {
		jeashInvalidateBounds();
		jeashApplyFilters(gfx.jeashSurface);
		jeashSetFlag(TRANSFORM_INVALID);
	}

	private inline function getSurfaceTransform(gfx:Graphics):Matrix {
		var extent = gfx.jeashExtentWithFilters;
		var fm = jeashGetFullMatrix();

		/*
		var tx = fm.tx;
		var ty = fm.ty;
		var nm = new Matrix();
		nm.scale(1/_fullScaleX, 1/_fullScaleY);
		fm = fm.mult(nm);
		fm.tx = tx;
		fm.ty = ty;
		*/
		
		fm.jeashTranslateTransformed(extent.topLeft);
		return fm;
	}

	public function drawToSurface(inSurface:Dynamic,
			matrix:jeash.geom.Matrix,
			inColorTransform:jeash.geom.ColorTransform,
			blendMode:BlendMode,
			clipRect:jeash.geom.Rectangle,
			smoothing:Bool):Void {
		var oldAlpha = alpha;
		alpha = 1;
		jeashRender(inSurface, clipRect);
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
					if (gfx.jeashHitTest(local.x * scaleX, local.y * scaleY))
						return cast this;
			}
		}
		return null;
	}

	// Masking
	private function getMask():DisplayObject {
		return jeashMask;
	}

	private function setMask(inValue:DisplayObject):DisplayObject {
		if (jeashMask != null)
			jeashMask.jeashMaskingObj = null;
		jeashMask = inValue;
		if (jeashMask != null)
			jeashMask.jeashMaskingObj = this;
		return jeashMask;
	}

	// @r533
	private function jeashSetFilters(filters:Array<Dynamic>) {
		var oldFilterCount = (jeashFilters == null) ? 0 : jeashFilters.length;

		if (filters == null) {
			jeashFilters = null;
			if (oldFilterCount > 0) invalidateGraphics();
		} else {
			jeashFilters = new Array<BitmapFilter>();
			for (filter in filters) jeashFilters.push(filter.clone());
			invalidateGraphics();
		}
		return filters;
	}

	private inline function invalidateGraphics():Void {
		var gfx = jeashGetGraphics();
		if (gfx != null)
			gfx.jeashInvalidate();
	}

	// @r533
	private function jeashGetFilters() {
		if (jeashFilters == null) return [];
		var result = new Array<BitmapFilter>();
		for (filter in jeashFilters)
			result.push(filter.clone());
		return result;
	}

	private function getScreenBounds() {
		if (_boundsInvalid)
			validateBounds();
		return jeashBoundsRect.clone();
	}

	private function jeashGetInteractiveObjectStack(outStack:Array<InteractiveObject>) {
		var io:InteractiveObject = cast this;
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
		if (event.target == null)
			event.target = this;
		event.currentTarget = this;
		return super.dispatchEvent(event);
	}
	
	override public function dispatchEvent(event:jeash.events.Event):Bool {
		var result = jeashDispatchEvent(event);
		
		if (event.jeashGetIsCancelled())
			return true;
		
		if (event.bubbles && parent != null)
			parent.dispatchEvent(event);
		
		return result;
	}

	private function jeashAddToStage(newParent:DisplayObjectContainer, ?beforeSibling:DisplayObject) {
		var gfx = jeashGetGraphics();
		if (gfx == null) return;

		if (newParent.jeashGetGraphics() != null) {
			Lib.jeashSetSurfaceId(gfx.jeashSurface, _jeashId);

			if (beforeSibling != null && beforeSibling.jeashGetGraphics() != null) {
				Lib.jeashAppendSurface(gfx.jeashSurface, beforeSibling._bottommostSurface);
			} else {
				var stageChildren = [];
				for (child in newParent.jeashChildren) {
					if (child.stage != null)
						stageChildren.push(child);
				}

				if (stageChildren.length < 1) {
					Lib.jeashAppendSurface(gfx.jeashSurface, null, newParent._topmostSurface);
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
						Lib.jeashAppendSurface(gfx.jeashSurface, null, nextSibling._topmostSurface);
					} else {
						Lib.jeashAppendSurface(gfx.jeashSurface);
					}
				}
			}
			Lib.jeashSetSurfaceTransform(gfx.jeashSurface, getSurfaceTransform(gfx));
		} else {
			if (newParent.name == Stage.NAME) { // only stage is allowed to add to a parent with no context
				Lib.jeashAppendSurface(gfx.jeashSurface);
			}
		}

		if (jeashIsOnStage()) {
			var evt = new jeash.events.Event(jeash.events.Event.ADDED_TO_STAGE, false, false);
			dispatchEvent(evt);
		}
	}

	private function jeashRemoveFromStage() {
		var gfx = jeashGetGraphics();
		if (gfx != null && Lib.jeashIsOnStage(gfx.jeashSurface)) {
			Lib.jeashRemoveSurface(gfx.jeashSurface);

			var evt = new jeash.events.Event(jeash.events.Event.REMOVED_FROM_STAGE, false, false);
			dispatchEvent(evt);
		}
	}

	private function jeashGetVisible() {
		return jeashVisible;
	}
	private function jeashSetVisible(inValue:Bool) {
		if (jeashVisible != inValue) {
			jeashVisible = inValue;
			setSurfaceVisible(inValue);
		}
		return jeashVisible;
	}

	private function jeashSetCombinedVisible(inValue:Bool):Bool {
		if (jeashCombinedVisible != inValue) {
			jeashCombinedVisible = inValue;
			setSurfaceVisible(inValue);
		}
		return jeashCombinedVisible;
	}

	private function setSurfaceVisible(inValue:Bool):Void {
		var gfx = jeashGetGraphics();
		if (gfx != null && gfx.jeashSurface != null)
			Lib.jeashSetSurfaceVisible(gfx.jeashSurface, inValue);
	}

	private function jeashGetWidth():Float {
		if (_boundsInvalid)
			validateBounds();
		return jeashWidth;
	}
	private function jeashSetWidth(inValue:Float):Float {
		if (_boundsInvalid) validateBounds();
		var w = jeashBoundsRect.width;
		if (jeashScaleX * w != inValue) {
			if (w <= 0) return 0;
			jeashScaleX = inValue / w;
			jeashInvalidateMatrix(true);
			jeashInvalidateBounds();
		}
		return inValue;
	}

	private function jeashGetHeight():Float {
		if (_boundsInvalid)
			validateBounds();
		return jeashHeight;
	}
	private function jeashSetHeight(inValue:Float):Float {
		if (_boundsInvalid) validateBounds();
		var h = jeashBoundsRect.height;
		if (jeashScaleY * h != inValue) {
			if (h <= 0) return 0;
			jeashScaleY = inValue / h;
			jeashInvalidateMatrix(true);
			jeashInvalidateBounds();
		}
		return inValue;
	}
	
	private function jeashGetX():Float {
		return jeashX;
	}
	private function jeashSetX(inValue:Float):Float {
		if (jeashX != inValue) {
			jeashX = inValue;
			jeashInvalidateMatrix(true);
			if (parent != null)
				parent.jeashInvalidateBounds();
		}
		return inValue;
	}
	
	private function jeashGetY():Float {
		return jeashY;
	}
	private function jeashSetY(inValue:Float):Float {
		if (jeashY != inValue) {
			jeashY = inValue;
			jeashInvalidateMatrix(true);
			if (parent != null)
				parent.jeashInvalidateBounds();
		}
		return inValue;
	}
	
	private function jeashGetScaleX():Float {
		return jeashScaleX;
	}
	private function jeashSetScaleX(inValue:Float) { 
		if (jeashScaleX != inValue) {
			jeashScaleX = inValue;
			jeashInvalidateMatrix(true);
			jeashInvalidateBounds();
		}
		return inValue;
	}
	
	private function jeashGetScaleY():Float {
		return jeashScaleY;
	}
	private function jeashSetScaleY(inValue:Float) { 
		if (jeashScaleY != inValue) {
			jeashScaleY = inValue;
			jeashInvalidateMatrix(true);
			jeashInvalidateBounds();
		}
		return inValue;
	}
	
	private function jeashGetRotation():Float {
		return jeashRotation;
	}
	private function jeashSetRotation(inValue:Float):Float {
		if (jeashRotation != inValue) {
			jeashRotation = inValue;
			jeashInvalidateMatrix(true);
			jeashInvalidateBounds();
		}
		return inValue;
	}

	private function jeashUnifyChildrenWithDOM(lastMoveGfx:Graphics = null) {
		var gfx = jeashGetGraphics();
		if (gfx != null && lastMoveGfx != null) 
			Lib.jeashSetSurfaceZIndexAfter(gfx.jeashSurface, lastMoveGfx.jeashSurface);
	}

	private function validateBounds() {
		if (_boundsInvalid) {
			var gfx = jeashGetGraphics();
			if (gfx == null) {
				jeashBoundsRect.x = x;
				jeashBoundsRect.y = y;
				jeashBoundsRect.width = 0;
				jeashBoundsRect.height = 0;
			} else {
				jeashBoundsRect = gfx.jeashExtent.clone();
				jeashSetDimensions();
				gfx.boundsDirty = false;
			}
			jeashClearFlag(BOUNDS_INVALID);
		}
	}

	private inline function jeashSetDimensions():Void {
		if (scale9Grid != null) {
			jeashBoundsRect.width *= jeashScaleX;
			jeashBoundsRect.height *= jeashScaleY;
			jeashWidth = jeashBoundsRect.width;
			jeashHeight = jeashBoundsRect.height;
		} else {
			jeashWidth = jeashBoundsRect.width * jeashScaleX;
			jeashHeight = jeashBoundsRect.height * jeashScaleY;
		}
	}

	private inline function getBoundsInvalid():Bool {
		var gfx = jeashGetGraphics();
		if (gfx == null)
			return jeashTestFlag(BOUNDS_INVALID);
		else
			return jeashTestFlag(BOUNDS_INVALID) || gfx.boundsDirty;
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
	private inline function jeashInvalidateBounds():Void {
		//TODO :: adjust so that parent is only invalidated if it's bounds are changed by this change
		jeashSetFlag(BOUNDS_INVALID);
		if (parent != null)
			parent.jeashSetFlag(BOUNDS_INVALID);
	}

	private inline function getMatrixChainInvalid():Bool {
		return jeashTestFlag(MATRIX_CHAIN_INVALID);
	}

	private inline function getMatrixInvalid():Bool {
		return jeashTestFlag(MATRIX_INVALID);
	}
	
	private inline function jeashTestFlag(mask:Int):Bool {
		return (_jeashRenderFlags & mask) != 0;
	}
		
	private inline function jeashSetFlag(mask:Int):Void {
		_jeashRenderFlags |= mask;
	}
		
	private inline function jeashClearFlag(mask:Int):Void {
		_jeashRenderFlags &= ~mask;
	}
	
	private inline function jeashSetFlagToValue(mask:Int, value:Bool):Void {
		if (value)
			_jeashRenderFlags |= mask;
		else
			_jeashRenderFlags &= ~mask;
	}
}

