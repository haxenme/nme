package native.display;


import native.errors.ArgumentError;
import native.events.Event;
import native.geom.Point;
import native.errors.RangeError;
import native.Loader;


class DisplayObjectContainer extends InteractiveObject {	
	
	
	public var mouseChildren (get_mouseChildren, set_mouseChildren):Bool;
	public var numChildren (get_numChildren, null):Int;
	public var tabChildren (get_tabChildren, set_tabChildren):Bool;
	//public var textSnapshot (get_textSnapshot, null):TextSnapshot; // not implemented
	
	/** @private */ private var nmeChildren:Array<DisplayObject>;
	
	
	public function new (inHandle:Dynamic, inType:String) {
		
		super (inHandle, inType);
		nmeChildren = [];
		
	}
	
	
	public function addChild (child:DisplayObject):DisplayObject {
		
		nmeAddChild (child);
		return child;
		
	}
	
	
	public function addChildAt (child:DisplayObject, index:Int):DisplayObject {
		
		nmeAddChild (child);
		nmeSetChildIndex (child, index);
		return child;
		
	}
	
	
	public function areInaccessibleObjectsUnderPoint (point:Point):Bool {
		
		return false;
		
	}
	
	
	public function contains (child:DisplayObject):Bool {
		
		if (child == null)
			return false;
		
		if (this == child)
			return true;
		
		for (c in nmeChildren)
			if (c == child)
				return true;
		
		return false;
		
	}
	
	
	public function getChildAt (index:Int):DisplayObject {
		
		if (index >= 0 && index < nmeChildren.length)
			return nmeChildren[index];
		
		// TODO
		throw new RangeError ("getChildAt : index out of bounds " + index + "/" + nmeChildren.length);
		
		return null;
		
	}
	
	
	public function getChildByName (name:String):DisplayObject {
		
		for (c in nmeChildren)
			if (name == c.name)
				return c;
		return null;
		
	}
	
	
	public function getChildIndex (child:DisplayObject):Int {
		
		return nmeGetChildIndex (child);
		
	}
	
	
	public function getObjectsUnderPoint (point:Point):Array<DisplayObject> {
		
		var result = new Array<DisplayObject> ();
		nmeGetObjectsUnderPoint (point, result);
		return result;
		
	}
	
	
	/** @private */ private inline function nmeAddChild (child:DisplayObject):Void {
		
		if (child == this) {
			
			throw "Adding to self";
			
		}
		
		if (child.nmeParent == this) {
			
			setChildIndex (child, nmeChildren.length - 1);
			
		} else {
			
			child.nmeSetParent (this);
			nmeChildren.push (child);
			nme_doc_add_child (nmeHandle, child.nmeHandle);
			
		}
		
	}
	
	
	/** @private */ override public function nmeBroadcast (inEvt:Event) {
		
		var i = 0;
		
		if (nmeChildren.length > 0)
			while (true) {
				
				var child = nmeChildren[i];
				child.nmeBroadcast (inEvt);
				
				if (i >= nmeChildren.length)
					break;
				
				if (nmeChildren[i] == child) {
					
					i++;
					if (i >= nmeChildren.length)
						break;
					
				}
				
			}
		
		super.nmeBroadcast (inEvt);
		
	}
	
	
	/** @private */ override function nmeFindByID (inID:Int):DisplayObject {
		
		if (nmeID == inID)
			return this;
		
		for (child in nmeChildren) {
			
			var found = child.nmeFindByID (inID);
			
			if (found != null)
				return found;
			
		}
		
		return super.nmeFindByID (inID);
		
	}
	
	
	/** @private */ private function nmeGetChildIndex (child:DisplayObject):Int {
		
		for (i in 0...nmeChildren.length)
			if (nmeChildren[i] == child)
				return i;
		return -1;
		
	}
	
	
	/** @private */ public override function nmeGetObjectsUnderPoint (point:Point, result:Array<DisplayObject>) {
		
		super.nmeGetObjectsUnderPoint (point, result);
		
		for (child in nmeChildren)
			child.nmeGetObjectsUnderPoint (point, result);
		
	}
	
	
	/** @private */ override function nmeOnAdded (inObj:DisplayObject, inIsOnStage:Bool) {
		
		super.nmeOnAdded (inObj, inIsOnStage);
		
		for (child in nmeChildren)
			child.nmeOnAdded (inObj, inIsOnStage);
		
	}
	
	
	/** @private */ override function nmeOnRemoved (inObj:DisplayObject, inWasOnStage:Bool) {
		
		super.nmeOnRemoved (inObj, inWasOnStage);
		
		for (child in nmeChildren)
			child.nmeOnRemoved (inObj, inWasOnStage);
		
	}
	
	
	/** @private */ public function nmeRemoveChildFromArray (child:DisplayObject) {
		
		var i = nmeGetChildIndex (child);
		
		if (i >= 0) {
			
			nme_doc_remove_child (nmeHandle, i);
			nmeChildren.splice (i, 1);
			
		}
		
	}
	
	
	/** @private */ private inline function nmeSetChildIndex (child:DisplayObject, index:Int):Void {
		
		if (index > nmeChildren.length)
			throw "Invalid index position " + index;
		
		var s:DisplayObject = null;
		var orig = nmeGetChildIndex (child);
		
		if (orig < 0) {
			
			var msg = "setChildIndex : object " + child.toString() + " not found.";
			
			if (child.nmeParent == this) {
				
				var realindex = -1;
				
				for (i in 0...nmeChildren.length) {
					
					if (nmeChildren[i] == child) {
						
						realindex = i;
						break;
						
					}
					
				}
				
				if (realindex != -1)
					msg += "Internal error: Real child index was " + Std.string (realindex);
				else
					msg += "Internal error: Child was not in nmeChildren array!";
				
			}
			
			throw msg;
			
		}
		
		nme_doc_set_child_index (nmeHandle, child.nmeHandle, index);
		
		if (index < orig) { // move down ...  
			
			var i = orig;
			
			while (i > index) {
				
				nmeChildren[i] = nmeChildren[i - 1];
				i--;
				
			}
			
			nmeChildren[index] = child;
			
		} else if (orig < index) { // move up ...
			
			var i = orig;
			while (i < index) {
				
				nmeChildren[i] = nmeChildren[i + 1];
				i++;
				
			}
			
			nmeChildren[index] = child;
			
		}
		
	}
	
	
	/** @private */ private inline function nmeSwapChildrenAt (index1:Int, index2:Int):Void {
		
		if (index1 < 0 || index2 < 0 || index1 > nmeChildren.length || index2 > nmeChildren.length)
			throw new RangeError ("swapChildrenAt : index out of bounds");
		
		if (index1 != index2) {
			
			var tmp = nmeChildren[index1];
			nmeChildren[index1] = nmeChildren[index2];
			nmeChildren[index2] = tmp;
			nme_doc_swap_children (nmeHandle, index1, index2);
			
		}
		
	}

	
	public function removeChild (child:DisplayObject):DisplayObject {
		
		var c = nmeGetChildIndex (child);
		
		if (c >= 0) {
			
			child.nmeSetParent (null);
			return child;
			
		}
		
		//throw new ArgumentError("The supplied DisplayObject must be a child of the caller.");
		
		return null;
		
	}
	
	
	public function removeChildAt (index:Int):DisplayObject {
		
		if (index >= 0 && index < nmeChildren.length) {
			
			var result = nmeChildren[index];
			result.nmeSetParent (null);
			return result;
			
		}
		
		throw new ArgumentError ("The supplied DisplayObject must be a child of the caller.");
		
	}
	
	
	public function setChildIndex (child:DisplayObject, index:Int):Void {
		
		nmeSetChildIndex (child, index);
		
	}
	
	
	public function swapChildren (child1:DisplayObject, child2:DisplayObject):Void {
		
		var idx1 = nmeGetChildIndex (child1);
		var idx2 = nmeGetChildIndex (child2);
		if (idx1 < 0 || idx2 < 0)
			throw "swapChildren:Could not find children";
		nmeSwapChildrenAt (idx1, idx2);
		
	}
	
	
	public function swapChildrenAt (index1:Int, index2:Int):Void {
		
		nmeSwapChildrenAt (index1, index2);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_mouseChildren ():Bool { return nme_doc_get_mouse_children (nmeHandle); }
	private function set_mouseChildren (inVal:Bool):Bool {
		
		nme_doc_set_mouse_children (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_numChildren ():Int { return nmeChildren.length; }
	private function get_tabChildren () { return false; }
	private function set_tabChildren (inValue:Bool) { return false; }
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_create_display_object_container = Loader.load ("nme_create_display_object_container", 0);
	private static var nme_doc_add_child = Loader.load ("nme_doc_add_child", 2);
	private static var nme_doc_remove_child = Loader.load ("nme_doc_remove_child", 2);
	private static var nme_doc_set_child_index = Loader.load ("nme_doc_set_child_index", 3);
	private static var nme_doc_get_mouse_children = Loader.load ("nme_doc_get_mouse_children", 1);
	private static var nme_doc_set_mouse_children = Loader.load ("nme_doc_set_mouse_children", 2);
	private static var nme_doc_swap_children = Loader.load ("nme_doc_swap_children", 3);
	
	
}