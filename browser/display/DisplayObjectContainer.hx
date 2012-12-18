package browser.display;


import browser.events.Event;
import browser.geom.Matrix;
import browser.geom.Point;
import browser.geom.Rectangle;
import browser.Html5Dom;
import browser.Lib;


class DisplayObjectContainer extends InteractiveObject {
	
	
	public var mouseChildren:Bool;
	public var nmeChildren:Array<DisplayObject>;
	public var nmeCombinedAlpha:Float;
	public var numChildren (get_numChildren, never):Int;
	public var tabChildren:Bool;
	
	
	public function new () {
		
		nmeChildren = new Array<DisplayObject> ();
		mouseChildren = true;
		tabChildren = true;
		
		super ();
		
		nmeCombinedAlpha = alpha;
		
	}
	
	
	public inline function __removeChild (child:DisplayObject):Void {
		
		nmeChildren.remove (child);
		
	}
	
	
	public function addChild (object:DisplayObject):DisplayObject {
		
		if (object == null) {
			
			throw "DisplayObjectContainer asked to add null child object";
			
		}
		
		if (object == this) {
			
			throw "Adding to self";
			
		}
		
		if (object.parent == this) {
			
			setChildIndex (object, nmeChildren.length - 1);
			return object;
			
		}
		
		#if debug
		for (child in nmeChildren) {
			
			if (child == object) {
				
				throw "Internal error: child already existed at index " + getChildIndex (object);
				
			}
			
		}
		#end
		
		object.parent = this;
		if (nmeIsOnStage ()) object.nmeAddToStage (this);
		
		if (nmeChildren == null) {
			
			nmeChildren = new Array <DisplayObject> ();
			
		}
		
		nmeChildren.push (object);
		return object;
		
	}
	
	
	public function addChildAt (object:DisplayObject, index:Int):DisplayObject {
		
		if (index > nmeChildren.length || index < 0) {
			
			throw "Invalid index position " + index;
			
		}
		
		if (object.parent == this) {
			
			setChildIndex (object, index);
			return object;
			
		}
		
		if (index == nmeChildren.length) {
			
			return addChild (object);
			
		} else {
			
			if (nmeIsOnStage ()) object.nmeAddToStage (this, nmeChildren[index]);
			nmeChildren.insert (index, object);
			object.parent = this;
			
		}
		
		return object;
		
	}
	
	
	public function contains (child:DisplayObject):Bool {
		
		if (child == null) return false;
		if (this == child) return true;
		
		for (c in nmeChildren) {
			
			if (c == child) return true;
			
		}
		
		return false;
		
	}
	
	
	public function getChildAt (index:Int):DisplayObject {
		
		if (index >= 0 && index < nmeChildren.length) {
			
			return nmeChildren[index];
			
		}
		
		throw "getChildAt : index out of bounds " + index + "/" + nmeChildren.length;
		return null;
		
	}
	
	
	public function getChildByName (inName:String):DisplayObject {
		
		for (child in nmeChildren) {
			
			if (child.name == inName) return child;
			
		}
		
		return null;
		
	}
	
	
	public function getChildIndex (inChild:DisplayObject):Int {
		
		for (i in 0...nmeChildren.length) {
			
			if (nmeChildren[i] == inChild) return i;
			
		}
		
		return -1;
		
	}
	
	
	public function getObjectsUnderPoint (point:Point):Array<DisplayObject> {
		
		var result = new Array<DisplayObject> ();
		nmeGetObjectsUnderPoint (point, result);
		return result;
		
	}
	
	
	override private function nmeAddToStage (newParent:DisplayObjectContainer, beforeSibling:DisplayObject = null):Void {
		
		super.nmeAddToStage (newParent, beforeSibling);
		
		for (child in nmeChildren) {
			
			if (child.nmeGetGraphics () == null || !child.nmeIsOnStage ()) {
				
				child.nmeAddToStage (this);
				
			}
			
		}
		
	}
	
	
	override public function nmeBroadcast (event:Event):Void {
		
		for (child in nmeChildren) {
			
			child.nmeBroadcast (event);
			
		}
		
		dispatchEvent (event);
		
	}
	
	
	override private function nmeGetObjectUnderPoint (point:Point):DisplayObject {
		
		if (!visible) return null;
		
		var l = nmeChildren.length - 1;
		
		for (i in 0...nmeChildren.length) {
			
			var result = null;
			
			if (mouseEnabled) {
				
				result = nmeChildren[l - i].nmeGetObjectUnderPoint (point);
				
			}
			
			if (result != null) {
				
				return mouseChildren ? result : this;
				
			}
			
		}
		
		return super.nmeGetObjectUnderPoint (point);
		
	}
	
	
	private function nmeGetObjectsUnderPoint (point:Point, stack:Array<DisplayObject>):Void {
		
		var l = nmeChildren.length - 1;
		
		for (i in 0...nmeChildren.length) {
			
			var result = nmeChildren[l - i].nmeGetObjectUnderPoint (point);
			
			if (result != null) {
				
				stack.push (result);
				
			}
			
		}
		
	}
	
	
	override public function nmeInvalidateMatrix (local:Bool = false):Void {
		
		//** FINAL **//	
		
		if (!_matrixChainInvalid && !_matrixInvalid) {	
			
			for (child in nmeChildren) {
				
				child.nmeInvalidateMatrix ();
				
			}
			
		}
		
		super.nmeInvalidateMatrix (local);
		
	}
	
	
	public inline function nmeRemoveChild (child:DisplayObject):DisplayObject {
		
		child.nmeRemoveFromStage ();
		child.parent = null;
		
		#if debug
		if (getChildIndex (child) >= 0) {
			
			throw "Not removed properly";
			
		}
		#end
		
		return child;
		
	}
	
	
	override private function nmeRemoveFromStage ():Void {
		
		super.nmeRemoveFromStage ();
		
		for (child in nmeChildren) {
			
			child.nmeRemoveFromStage ();
			
		}
		
	}
	
	
	override private function nmeRender (inMask:HTMLCanvasElement = null, clipRect:Rectangle = null):Void {
		
		if (!nmeVisible) return;
		
		if (clipRect == null && nmeScrollRect != null) {
			
			clipRect = nmeScrollRect;
			
		}
		
		super.nmeRender (inMask, clipRect);
		
		nmeCombinedAlpha = (parent != null ? parent.nmeCombinedAlpha * alpha : alpha);
		
		for (child in nmeChildren) {
			
			if (child.nmeVisible) {
				
				if (clipRect != null) {
					
					if (child._matrixInvalid || child._matrixChainInvalid) {
						
						//child.invalidateGraphics();
						child.nmeValidateMatrix ();
						
					}
					
				}
				
				child.nmeRender (inMask, clipRect);
				
			}
			
		}
		
	}
	
	
	private function nmeSwapSurface(c1:Int, c2:Int):Void {
		
		if (nmeChildren[c1] == null) throw "Null element at index " + c1 + " length " + nmeChildren.length;
		if (nmeChildren[c2] == null) throw "Null element at index " + c2 + " length " + nmeChildren.length;
		
		var gfx1 = nmeChildren[c1].nmeGetGraphics ();
		var gfx2 = nmeChildren[c2].nmeGetGraphics ();
		
		if (gfx1 != null && gfx2 != null) {
			
			Lib.nmeSwapSurface (gfx1.nmeSurface, gfx2.nmeSurface);
			
		}
		
	}
	
	
	override private function nmeUnifyChildrenWithDOM (lastMoveGfx:Graphics = null):Void {
		
		var gfx1 = nmeGetGraphics ();
		
		if (gfx1 != null) {
			
			lastMoveGfx = gfx1;
			
			for (child in nmeChildren) {
				
				var gfx2 = child.nmeGetGraphics ();
				
				if (gfx2 != null) {
					
					Lib.nmeSetSurfaceZIndexAfter (gfx2.nmeSurface, lastMoveGfx.nmeSurface);
					lastMoveGfx = gfx2;
					
				}
				
				child.nmeUnifyChildrenWithDOM (lastMoveGfx);
				
			}
			
		}
		
	}
	
	
	public function removeChild (inChild:DisplayObject):DisplayObject {
		
		for (child in nmeChildren) {
			
			if (child == inChild) {
				
				return nmeRemoveChild (child);
				
			}
			
		}
		
		throw "removeChild : none found?";
		
	}
	
	
	public function removeChildAt (index:Int):DisplayObject {
		
		if (index >= 0 && index < nmeChildren.length) {
			
			return nmeRemoveChild (nmeChildren[index]);
			
		}
		
		throw "removeChildAt(" + index + ") : none found?";
		
	}
	
	
	public function setChildIndex(child:DisplayObject, index:Int) {
		
		if (index > nmeChildren.length) {
			
			throw "Invalid index position " + index;
			
		}
		
		var oldIndex = getChildIndex (child);
		
		if (oldIndex < 0) {
			
			var msg = "setChildIndex : object " + child.name + " not found.";
			
			if (child.parent == this) {
				
				var realindex = -1;
				
				for (i in 0...nmeChildren.length) {
					
					if (nmeChildren[i] == child) {
						
						realindex = i;
						break;
						
					}
					
				}
				
				if (realindex != -1) {
					
					msg += "Internal error: Real child index was " + Std.string (realindex);
					
				} else {
					
					msg += "Internal error: Child was not in nmeChildren array!";
					
				}
				
			}
			
			throw msg;
			
		}
		
		if (index < oldIndex) { // move down ...
			
			var i = oldIndex;
			
			while (i > index) {
				
				swapChildren (nmeChildren[i], nmeChildren[i - 1]);
				i--;
				
			}
			
		} else if (oldIndex < index) { // move up ...
			
			var i = oldIndex;
			
			while (i < index) {
				
				swapChildren (nmeChildren[i], nmeChildren[i + 1]);
				i++;
				
			}
			
		}
		
	}
	
	
	public function swapChildren (child1:DisplayObject, child2:DisplayObject):Void {
		
		var c1 = -1;
		var c2 = -1;
		var swap:DisplayObject;
		
		for (i in 0...nmeChildren.length) {
			
			if (nmeChildren[i] == child1) {
				
				c1 = i;
				
			} else if (nmeChildren[i] == child2) {
				
				c2 = i;
				
			}
			
		}
		
		if (c1 != -1 && c2 != -1) {
			
			swap = nmeChildren[c1];
			nmeChildren[c1] = nmeChildren[c2];
			nmeChildren[c2] = swap;
			swap = null;
			nmeSwapSurface (c1, c2);
			
			//child1.nmeUnifyChildrenWithDOM(); // possibly no longer necessary?
			//child2.nmeUnifyChildrenWithDOM(); // possibly no longer necessary?
			
		}
		
	}
	
	
	public function swapChildrenAt (child1:Int, child2:Int):Void {
		
		var swap:DisplayObject = nmeChildren[child1];
		nmeChildren[child1] = nmeChildren[child2];
		nmeChildren[child2] = swap;
		swap = null;
		
	}
	
	
	override public function toString ():String {
		
		return "[DisplayObjectContainer name=" + this.name + " id=" + _nmeId + "]";
		
	}
	
	
	override function validateBounds ():Void {
		
		if (_boundsInvalid) {
			
			super.validateBounds ();
			
			for (obj in nmeChildren) {
				
				if (obj.visible) {
					
					var r = obj.getBounds (this);
					
					if (r.width != 0 || r.height != 0) {
						
						if (nmeBoundsRect.width == 0 && nmeBoundsRect.height == 0) {
							
							nmeBoundsRect = r.clone();
							
						} else {
							
							nmeBoundsRect.extendBounds (r);
							
						}
						
					}
					
				}
				
			}
			
			nmeSetDimensions ();
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	override private function set_filters (filters:Array<Dynamic>):Array<Dynamic> {
		
		super.set_filters (filters);
		
		// TODO: check if we need to merge filters with children.
		for (child in nmeChildren) {
			
			child.filters = filters;
			
		}
		
		return filters;
		
	}
	
	
	override private function set_nmeCombinedVisible (inVal:Bool):Bool {
		
		if (inVal != nmeCombinedVisible) {
			
			for (child in nmeChildren) {
				
				child.nmeCombinedVisible = (child.visible && inVal);
				
			}
			
		}
		
		return super.set_nmeCombinedVisible (inVal);
		
	}
	
	
	private inline function get_numChildren ():Int {
		
		return nmeChildren.length;
		
	}
	
	
	override private function set_visible (inVal:Bool):Bool {
		
		nmeCombinedVisible = inVal;
		return super.set_visible (inVal);
		
	}
	
	
}