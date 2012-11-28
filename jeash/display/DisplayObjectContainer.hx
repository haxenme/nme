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
import jeash.events.Event;
import jeash.geom.Matrix;
import jeash.geom.Rectangle;
import jeash.geom.Point;
import jeash.Lib;

class DisplayObjectContainer extends InteractiveObject
{
	public var jeashChildren:Array<DisplayObject>;
	public var numChildren(jeashGetNumChildren, never):Int;
	public var mouseChildren:Bool;
	public var tabChildren:Bool;
	public var jeashCombinedAlpha:Float;

	public function new() {
		jeashChildren = new Array<DisplayObject>();
		mouseChildren = true;
		tabChildren = true;
		super();
		jeashCombinedAlpha = alpha;
	}

	override public function toString() { return "[DisplayObjectContainer name=" + this.name + " id=" + _jeashId + "]"; }

	override public function jeashBroadcast(event:jeash.events.Event) {
		for (child in jeashChildren)
			child.jeashBroadcast(event);
		dispatchEvent(event);
	}

	override function validateBounds() {
		if (_boundsInvalid) {
			super.validateBounds();
			for (obj in jeashChildren) {
				if (obj.visible) {
					var r = obj.getBounds(this);
					if (r.width != 0 || r.height != 0) {
						if (jeashBoundsRect.width == 0 && jeashBoundsRect.height == 0)
							jeashBoundsRect = r.clone();
						else
							jeashBoundsRect.extendBounds(r);
					}
				}
			}
			jeashSetDimensions();
		}
	}

	//** FINAL **//	
	override public function jeashInvalidateMatrix(local:Bool=false) : Void {
		if (!_matrixChainInvalid && !_matrixInvalid) {	
			for (child in jeashChildren) {
				child.jeashInvalidateMatrix();
			}
		}
		super.jeashInvalidateMatrix(local);
	}

	private inline function jeashGetNumChildren() {
		return jeashChildren.length;
	}

	override private function jeashRender(?inMask:HTMLCanvasElement, ?clipRect:Rectangle, ?overrideMatrix:Matrix) {
		if (!jeashVisible) return;

		if (clipRect == null && jeashScrollRect != null) {
			clipRect = jeashScrollRect;
		}
		super.jeashRender(inMask, clipRect, overrideMatrix);
		jeashCombinedAlpha = parent != null ? parent.jeashCombinedAlpha * alpha : alpha;
		for (child in jeashChildren) {
			if (child.jeashVisible) {
				if (clipRect != null) {
					if (child._matrixInvalid || child._matrixChainInvalid) {
						child.invalidateGraphics();
						child.jeashValidateMatrix();
					}
				}
				if (inMask != null && overrideMatrix != null) {
					// rendering to mask surface, be sure to account for current child transform
					child.jeashValidateMatrix();
					overrideMatrix = child.transform.matrix.mult(overrideMatrix);
				}
				child.jeashRender(inMask, clipRect, overrideMatrix);
			}
		}
	}

	override private function jeashAddToStage(newParent:DisplayObjectContainer, ?beforeSibling:DisplayObject) {
		super.jeashAddToStage(newParent, beforeSibling);
		for (child in jeashChildren) {
			if (child.jeashGetGraphics() == null || !child.jeashIsOnStage()) {
				child.jeashAddToStage(this);
			}
		}
	}

	override private function jeashRemoveFromStage() {
		super.jeashRemoveFromStage();
		for (child in jeashChildren)
			child.jeashRemoveFromStage();
	}

	public function addChild(object:DisplayObject):DisplayObject {
		if (object == null)
			throw "DisplayObjectContainer asked to add null child object";
		if (object == this)
			throw "Adding to self";

		if (object.parent == this) {
			setChildIndex(object, jeashChildren.length-1);
			return object;
		}

		#if debug
		for (child in jeashChildren) {
			if (child == object) {
				throw "Internal error: child already existed at index " + getChildIndex(object);
			}
		}
		#end

		object.parent = this;
		if (jeashIsOnStage()) object.jeashAddToStage(this);
		
		if (jeashChildren == null) {
			
			jeashChildren = new Array <DisplayObject> ();
			
		}
		
		jeashChildren.push(object);

		return object;
	}

	public function addChildAt(object:DisplayObject, index:Int):DisplayObject {
		if (index > jeashChildren.length || index < 0) {
			throw "Invalid index position " + index;
		}

		if (object.parent == this) {
			setChildIndex(object, index);
			return object;
		}

		if (index == jeashChildren.length) {
			return addChild(object);
		} else {
			if (jeashIsOnStage()) object.jeashAddToStage(this, jeashChildren[index]);
			jeashChildren.insert(index, object);
			object.parent = this;
		}
		return object;
	}

	// @r498
	public function contains(child:DisplayObject) {
		if (child == null)
			return false;
		if (this == child)
			return true;
		for (c in jeashChildren)
			if (c == child) return true;
		return false;
	}

	// @r498
	public function getChildAt(index:Int):DisplayObject {
		if (index >= 0 && index < jeashChildren.length)
			return jeashChildren[index];
		throw "getChildAt : index out of bounds " + index + "/" + jeashChildren.length;
		return null;
	}

	public function getChildByName(inName:String):DisplayObject {
		for (child in jeashChildren)
			if (child.name == inName) return child;
		return null;
	}

	public function getChildIndex(inChild:DisplayObject) {
		for (i in 0...jeashChildren.length)
			if (jeashChildren[i] == inChild) return i;
		return -1;
	}

	public function removeChild(inChild:DisplayObject):DisplayObject {
		for (child in jeashChildren) {
			if (child == inChild)
				return jeashRemoveChild(child);
		}
		throw "removeChild : none found?";
	}

	public function removeChildAt(index:Int):DisplayObject {
		if (index >= 0 && index < jeashChildren.length)
			return jeashRemoveChild(jeashChildren[index]);
		throw "removeChildAt("+index+") : none found?";
	}

	public inline function jeashRemoveChild(child:DisplayObject):DisplayObject {
		child.jeashRemoveFromStage();
		child.parent = null;
		#if debug
		if (getChildIndex(child) >= 0)
			throw "Not removed properly";
		#end
		return child;
	}

	public inline function __removeChild(child:DisplayObject):Void {
		jeashChildren.remove(child);
	}

	public function setChildIndex(child:DisplayObject, index:Int) {
		if (index > jeashChildren.length) {
			throw "Invalid index position " + index;
		}

		var oldIndex = getChildIndex(child);
		if (oldIndex < 0) {
			var msg = "setChildIndex : object " + child.name + " not found.";
			if (child.parent == this) {
				var realindex = -1;
				for (i in 0...jeashChildren.length) {
					if (jeashChildren[i] == child) {
						realindex = i;
						break;
					}
				}
				if (realindex != -1)
					msg += "Internal error: Real child index was " + Std.string(realindex);
				else
					msg += "Internal error: Child was not in jeashChildren array!";
			}
			throw msg;
		}

		if (index < oldIndex) { // move down ...
			var i = oldIndex;
			while (i > index) {
				swapChildren(jeashChildren[i], jeashChildren[i-1]);
				i--;
			}
		} else if (oldIndex < index) { // move up ...
			var i = oldIndex;
			while (i < index) {
				swapChildren(jeashChildren[i], jeashChildren[i+1]);
				i++;
			}
		}
	}

	private function jeashSwapSurface(c1:Int, c2:Int) {
		if (jeashChildren[c1] == null) throw "Null element at index " + c1 + " length " + jeashChildren.length;
		if (jeashChildren[c2] == null) throw "Null element at index " + c2 + " length " + jeashChildren.length;
		var gfx1 = jeashChildren[c1].jeashGetGraphics();
		var gfx2 = jeashChildren[c2].jeashGetGraphics();
		if (gfx1 != null && gfx2 != null)
			Lib.jeashSwapSurface(gfx1.jeashSurface, gfx2.jeashSurface);
	}

	public function swapChildren(child1:DisplayObject, child2:DisplayObject) {
		var c1 : Int = -1;
		var c2 : Int = -1;
		var swap : DisplayObject;
		for (i in 0...jeashChildren.length) {
			if (jeashChildren[i] == child1) c1 = i;
			else if (jeashChildren[i] == child2) c2 = i;
		}
		if (c1 != -1 && c2 != -1) {
			swap = jeashChildren[c1];
			jeashChildren[c1] = jeashChildren[c2];
			jeashChildren[c2] = swap;
			swap = null;
			jeashSwapSurface(c1, c2);
			//child1.jeashUnifyChildrenWithDOM(); // possibly no longer necessary?
			//child2.jeashUnifyChildrenWithDOM(); // possibly no longer necessary?
		}
	}

	override private function jeashUnifyChildrenWithDOM(lastMoveGfx:Graphics = null) {
		var gfx1 = jeashGetGraphics();
		if (gfx1 != null) {
			lastMoveGfx = gfx1;
			for (child in jeashChildren) {
				var gfx2 = child.jeashGetGraphics();
				if (gfx2 != null) {
					Lib.jeashSetSurfaceZIndexAfter(gfx2.jeashSurface, lastMoveGfx.jeashSurface);
					lastMoveGfx = gfx2;
				}
				child.jeashUnifyChildrenWithDOM(lastMoveGfx);
			}
		}
	}

	public function swapChildrenAt(child1:Int, child2:Int) {
		var swap : DisplayObject = jeashChildren[child1];
		jeashChildren[child1] = jeashChildren[child2];
		jeashChildren[child2] = swap;
		swap = null;
	}

	override private function jeashGetObjectUnderPoint(point:Point) {
		if (!visible) return null;
		var l = jeashChildren.length-1;
		for (i in 0...jeashChildren.length) {
			var result = jeashChildren[l-i].jeashGetObjectUnderPoint(point);
			if (result != null)
				return mouseChildren ? result : this;
		}

		return super.jeashGetObjectUnderPoint(point);
	}

	// @r551
	public function getObjectsUnderPoint(point:Point) {
		var result = new Array<DisplayObject>();
		jeashGetObjectsUnderPoint(point, result);
		return result;
	}

	function jeashGetObjectsUnderPoint(point:Point, stack:Array<DisplayObject>) {
		var l = jeashChildren.length-1;
		for (i in 0...jeashChildren.length) {
			var result = jeashChildren[l-i].jeashGetObjectUnderPoint(point);
			if (result != null)
				stack.push(result);
		}
	}

	// TODO: check if we need to merge filters with children.
	override private function jeashSetFilters(filters:Array<Dynamic>) {
		super.jeashSetFilters(filters);
		for (child in jeashChildren)
			child.jeashSetFilters(filters);
		return filters;
	}

	override private function jeashSetVisible(inVal:Bool):Bool {
		jeashCombinedVisible = inVal;
		return super.jeashSetVisible(inVal);
	}

	override private function jeashSetCombinedVisible(inVal:Bool):Bool {
		if (inVal != jeashCombinedVisible) {
			for (child in jeashChildren) {
				child.jeashCombinedVisible = child.visible && inVal;
			}
		}
		return super.jeashSetCombinedVisible(inVal);
	}
}
