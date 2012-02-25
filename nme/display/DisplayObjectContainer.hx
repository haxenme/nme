package nme.display;
#if (cpp || neko)


import nme.events.Event;
import nme.geom.Point;
import nme.errors.RangeError;
import nme.Loader;


class DisplayObjectContainer extends InteractiveObject
{	
	
	public var mouseChildren(nmeGetMouseChildren, nmeSetMouseChildren):Bool;
	public var numChildren(nmeGetNumChildren, null):Int;
	public var tabChildren(nmeGetTabChildren, nmeSetTabChildren):Bool;
	//public var textSnapshot(nmeGetTextSnapshot, null):TextSnapshot; // not implemented
	
	private var nmeChildren:Array<DisplayObject>;
	
	
	public function new(inHandle:Dynamic, inType:String)
	{	
		super(inHandle, inType);
		nmeChildren = [];
	}
	
	
	public function addChild(child:DisplayObject):DisplayObject
	{	
		if (child == this)
		{	
			throw "Adding to self";	
		}
		
		if (child.nmeParent == this)
		{	
			setChildIndex(child, nmeChildren.length - 1);
		}
		else
		{	
			child.nmeSetParent(this);
			nmeChildren.push(child);
			nme_doc_add_child(nmeHandle, child.nmeHandle);
		}
		
		return child;
	}
	
	
	public function addChildAt(child:DisplayObject, index:Int):DisplayObject
	{	
		addChild(child);
		setChildIndex(child, index);
		
		return child;
	}
	
	
	public function areInaccessibleObjectsUnderPoint(point:Point):Bool
	{		
		return false;
	}
	
	
	public function contains(child:DisplayObject):Bool
	{	
		if (child == null)
			return false;
		
		if (this == child)
			return true;
		
		for (c in nmeChildren)
			if (c == child)
				return true;
		
		return false;	
	}
	
	
	public function getChildAt(index:Int):DisplayObject
	{	
		if (index >= 0 && index < nmeChildren.length)
			return nmeChildren[index];
		
		// TODO
		throw new RangeError("getChildAt : index out of bounds " + index + "/" + nmeChildren.length);
		
		return null;
	}

	
	public function getChildByName(name:String):DisplayObject
	{	
		for (c in nmeChildren)
			if (name == c.name)
				return c;
		return null;	
	}
	
	
	public function getChildIndex(child:DisplayObject):Int
	{	
		for (i in 0...nmeChildren.length)
			if (nmeChildren[i] == child)
				return i;	
		return -1;
	}

	
	public function getObjectsUnderPoint(point:Point):Array<DisplayObject>
	{	
		var result = new Array<DisplayObject>();
		nmeGetObjectsUnderPoint(point, result);
		return result;
	}
	

	override public function nmeBroadcast(inEvt:Event)
	{	
		var i = 0;
		
		if (nmeChildren.length > 0)
			while (true)
			{	
				var child = nmeChildren[i];
				child.nmeBroadcast (inEvt);
				
				if (i >= nmeChildren.length)
					break;
				
				if (nmeChildren[i] == child)
				{	
					i++;
					if (i >= nmeChildren.length)
						break;	
				}
			}
		
		dispatchEvent(inEvt);
	}
	
	
	override function nmeFindByID(inID:Int):DisplayObject
	{	
		if (nmeID == inID)
			return this;
		
		for (child in nmeChildren)
		{	
			var found = child.nmeFindByID(inID);
			
			if (found != null)
				return found;
		}
		
		return super.nmeFindByID(inID);
	}
	
	
	public override function nmeGetObjectsUnderPoint(point:Point, result:Array<DisplayObject>)
	{	
		super.nmeGetObjectsUnderPoint(point, result);
		
		for (child in nmeChildren)
			nmeGetObjectsUnderPoint(point, result);
	}
	
	
	override function nmeOnAdded(inObj:DisplayObject, inIsOnStage:Bool)
	{	
		super.nmeOnAdded(inObj, inIsOnStage);
		
		for (child in nmeChildren)
			child.nmeOnAdded(inObj, inIsOnStage);
	}
	
	
	override function nmeOnRemoved(inObj:DisplayObject, inWasOnStage:Bool)
	{	
		super.nmeOnRemoved(inObj, inWasOnStage);
		
		for (child in nmeChildren)
			child.nmeOnRemoved(inObj, inWasOnStage);
	}
	
	
	/**
	 * @private
	 */
	public function nmeRemoveChildFromArray(child:DisplayObject)
	{
		var i = getChildIndex(child);
		
		if (i >= 0)
		{	
			nme_doc_remove_child(nmeHandle, i);
			nmeChildren.splice(i, 1);	
		}
	}

	
	public function removeChild(child:DisplayObject):DisplayObject
	{	
		var c = getChildIndex(child);
		
		if (c >= 0)
		{	
			child.nmeSetParent(null);
			return child;
		}
		
		return null;
	}
	
	
	public function removeChildAt(index:Int):DisplayObject
	{	
		if (index >= 0 && index < nmeChildren.length)
		{	
			var result = nmeChildren[index];
			result.nmeSetParent(null);
			return result;
		}
		
		return null;
	}
	
	
	public function setChildIndex(child:DisplayObject, index:Int):Void
	{	
		if (index > nmeChildren.length)
			throw "Invalid index position " + index;
		
		var s:DisplayObject = null;
		var orig = getChildIndex(child);
		
		if (orig < 0)
		{	
			var msg = "setChildIndex : object " + child.toString() + " not found.";
			
			if (child.nmeParent == this)
			{	
				var realindex = -1;
				
				for (i in 0...nmeChildren.length)
				{	
					if (nmeChildren[i] == child)
					{	
						realindex = i;
						break;	
					}
				}
				
				if (realindex != -1)
					msg += "Internal error: Real child index was " + Std.string(realindex);
				else
					msg += "Internal error: Child was not in nmeChildren array!";	
			}
			
			throw msg;
		}
		
		nme_doc_set_child_index(nmeHandle, child.nmeHandle, index);
		
		if (index < orig) // move down ...
		{ 
			var i = orig;
			
			while (i > index)
			{	
				nmeChildren[i] = nmeChildren[i - 1];
				i--;	
			}
			
			nmeChildren[index] = child;
			
		}
		else if (orig < index) // move up ...
		{ 
			var i = orig;
			while (i < index)
			{	
				nmeChildren[i] = nmeChildren[i + 1];
				i++;	
			}
			
			nmeChildren[index] = child;
		}
	}
	
	
	public function swapChildren(child1:DisplayObject, child2:DisplayObject):Void
	{	
		var idx1 = getChildIndex(child1);
		var idx2 = getChildIndex(child2);
		if (idx1 < 0 || idx2 < 0)
			throw "swapChildren:Could not find children";
		swapChildrenAt(idx1, idx2);
	}
	
	
	public function swapChildrenAt(index1:Int, index2:Int):Void
	{	
		if (index1 < 0 || index2 < 0 || index1 > nmeChildren.length || index2 > nmeChildren.length)
			throw new RangeError ("swapChildrenAt : index out of bounds");
		
		if (index1 == index2)
			return;
		
		var tmp = nmeChildren[index1];
		nmeChildren[index1] = nmeChildren[index2];
		nmeChildren[index2] = tmp;
		nme_doc_swap_children(nmeHandle, index1, index2);
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetMouseChildren():Bool { return nme_doc_get_mouse_children(nmeHandle); }
	private function nmeSetMouseChildren(inVal:Bool):Bool
	{
		nme_doc_set_mouse_children(nmeHandle, inVal);
		return inVal;
	}
	
	
	private function nmeGetNumChildren():Int { return nmeChildren.length; }
	private function nmeGetTabChildren() { return false; }
	private function nmeSetTabChildren(inValue:Bool) { return false; }
	
	
	
	// Native Methods
	
	
	
	private static var nme_create_display_object_container = Loader.load("nme_create_display_object_container", 0);
	private static var nme_doc_add_child = Loader.load("nme_doc_add_child", 2);
	private static var nme_doc_remove_child = Loader.load("nme_doc_remove_child", 2);
	private static var nme_doc_set_child_index = Loader.load("nme_doc_set_child_index", 3);
	private static var nme_doc_get_mouse_children = Loader.load("nme_doc_get_mouse_children", 1);
	private static var nme_doc_set_mouse_children = Loader.load("nme_doc_set_mouse_children", 2);
	private static var nme_doc_swap_children = Loader.load("nme_doc_swap_children", 3);
	
}


#elseif js


import Html5Dom;
import nme.events.Event;
import nme.geom.Matrix;
import nme.geom.Rectangle;
import nme.geom.Point;
import nme.Lib;

class DisplayObjectContainer extends InteractiveObject
{
	var jeashChildren : Array<DisplayObject>;
	var mLastSetupObjs : Array<DisplayObject>;
	public var numChildren(jeashGetNumChildren,null):Int;
	public var mouseChildren:Bool;
	public var tabChildren:Bool;

	public function new()
	{
		jeashChildren = new Array<DisplayObject>();
		mLastSetupObjs = new Array<DisplayObject>();
		mouseChildren = true;
		tabChildren = true;
		super();
		name = "DisplayObjectContainer " +  flash.display.DisplayObject.mNameID++;
	}

	override public function AsContainer() { return this; }

	// @r498
	override public function jeashBroadcast(event:flash.events.Event)
	{
		var i = 0;
		if (jeashChildren.length>0)
			while(true)
			{
				var child = jeashChildren[i];
				child.jeashBroadcast(event);
				if (i>=jeashChildren.length)
					break;
				if (jeashChildren[i]==child)
				{
					i++;
					if (i>=jeashChildren.length)
						break;
				}
			}
		dispatchEvent(event);
	}

	override function BuildBounds()
	{
		//if (mBoundsDirty)
		{
			super.BuildBounds();
			for(obj in jeashChildren)
			{
				if (obj.visible)
				{
					var r = obj.getBounds(this);
					if (r.width!=0 || r.height!=0)
					{
						if (mBoundsRect.width==0 && mBoundsRect.height==0)
							mBoundsRect = r.clone();
						else
							mBoundsRect.extendBounds(r);
					}
				}
			}
		}
	}

	//** FINAL **//	
	override function jeashInvalidateMatrix( ? local : Bool = false) : Void {
		//invalidate children only if they are not already invalidated
		if(mMtxChainDirty==false && mMtxDirty==false)		{				
			for(child in jeashChildren)
				child.jeashInvalidateMatrix();
		}			
		mMtxChainDirty= mMtxChainDirty || !local;	//note that a parent has an invalid matrix 
		mMtxDirty = mMtxDirty || local; 		//invalidate the local matrix
	}

	override function jeashDoAdded(inObj:DisplayObject)
	{
		super.jeashDoAdded(inObj);
		for(child in jeashChildren)
			child.jeashDoAdded(inObj);
	}

	override function jeashDoRemoved(inObj:DisplayObject)
	{
		super.jeashDoRemoved(inObj);
		for(child in jeashChildren)
			child.jeashDoRemoved(inObj);
	}

	override public function GetBackgroundRect()
	{
		var r = super.GetBackgroundRect();
		if (r!=null) r = r.clone();

		for(obj in jeashChildren)
		{
			if (obj.visible)
			{
				var o = obj.GetBackgroundRect();
				if (o!=null)
				{
				var trans = o.transform(obj.mMatrix);
				if (r==null || r.width==0 || r.height==0)
					r = trans;
				else if (trans.width!=0 && trans.height!=0)
					r.extendBounds(trans);
				}
			}
		}
		return r;
	}

	override public function GetFocusObjects(outObjs:Array<InteractiveObject>)
	{
		for(obj in jeashChildren)
			obj.GetFocusObjects(outObjs);
	}

	public override function jeashGetNumChildren() {
		return jeashChildren.length;
	}

	override public function jeashRender(inParentMatrix:Matrix, ?inMask:HTMLCanvasElement) {

		if (!visible) return;

		super.jeashRender(inParentMatrix, inMask);
		for(obj in jeashChildren) {
			if (obj.visible) {
				obj.jeashRender(mFullMatrix, inMask);
			} 
		}

	}

	public function addChild(object:DisplayObject):DisplayObject
	{
		if (object == this) {
			throw "Adding to self";
		}
		if (object.parent==this)
		{
			setChildIndex(object,jeashChildren.length-1);
			return object;
		}

		#if debug
		for(i in 0...jeashChildren.length) {
			if(jeashChildren[i] == object) {
				throw "Internal error: child already existed at index " + i;
			}
		}
		#end

		if (jeashIsOnStage())
			object.jeashAddToStage();

		jeashChildren.push(object);
		object.jeashSetParent(this);

		return object;
	}

	override private function jeashAddToStage()
	{
		super.jeashAddToStage();
		for(i in 0...jeashChildren.length)
			jeashChildren[i].jeashAddToStage();
	}

	override private function jeashInsertBefore(obj:DisplayObject)
	{
		super.jeashInsertBefore(obj);
		for(i in 0...jeashChildren.length)
			jeashChildren[i].jeashAddToStage();
	}

	public function addChildAt( obj : DisplayObject, index : Int )
	{
		if(index > jeashChildren.length || index < 0) {
			throw "Invalid index position " + index;
		}

		if (obj.parent == this)
		{
			setChildIndex(obj, index);
			return;
		}

		if(index == jeashChildren.length)
		{
			jeashChildren.push(obj);
			if (jeashIsOnStage()) obj.jeashAddToStage();
		} else {
			if (jeashIsOnStage()) obj.jeashInsertBefore(jeashChildren[index]);
			jeashChildren.insert(index, obj);
		}
		obj.jeashSetParent(this);
	}

	// @r498
	public function contains(child:DisplayObject)
	{
		if (child==null)
			return false;
		if (this==child)
			return true;
		for(c in jeashChildren)
			if (c==child)
				return true;
		return false;
	}

	// @r498
	public function getChildAt( index : Int ):DisplayObject
	{
		if (index>=0 && index<jeashChildren.length)
			return jeashChildren[index];
		throw "getChildAt : index out of bounds " + index + "/" + jeashChildren.length;
		return null;
	}

	public function getChildByName(inName:String):DisplayObject
	{
		for(i in 0...jeashChildren.length)
			if (jeashChildren[i].name==inName)
				return jeashChildren[i];
		return null;
	}

	public function getChildIndex( child : DisplayObject )
	{
		for ( i in 0...jeashChildren.length )
			if ( jeashChildren[i] == child )
				return i;
		return -1;
	}

	public function removeChild( child : DisplayObject )
	{
		for ( i in 0...jeashChildren.length )
		{
			if ( jeashChildren[i] == child )
			{
				child.jeashSetParent( null );
				#if debug
				if (getChildIndex(child) >= 0) {
					throw "Not removed properly";
				}
				#end
				return;
			}
		}
		throw "removeChild : none found?";
	}

	public function removeChildAt(inI:Int):DisplayObject
	{
		jeashChildren[inI].jeashSetParent(null);
		return jeashChildren[inI];
	}

	public function __removeChild( child : DisplayObject )
	{
		var i = getChildIndex(child);
		if (i>=0)
		{
			jeashChildren.splice( i, 1 );
		}
	}

	public function setChildIndex( child : DisplayObject, index : Int )
	{
		if(index > jeashChildren.length) {
			throw "Invalid index position " + index;
		}

		var s : DisplayObject = null;
		var orig = getChildIndex(child);

		if (orig < 0) {
			var msg = "setChildIndex : object " + child.name + " not found.";
			if(child.parent == this) {
				var realindex = -1;
				for(i in 0...jeashChildren.length) {
					if(jeashChildren[i] == child) {
						realindex = i;
						break;
					}
				}
				if(realindex != -1)
					msg += "Internal error: Real child index was " + Std.string(realindex);
				else
					msg += "Internal error: Child was not in jeashChildren array!";
			}
			throw msg;
		}


		// move down ...
		if (index<orig)
		{
			var i = orig;
			while(i > index) {
				swapChildren(jeashChildren[i], jeashChildren[i-1]);
				i--;
			}
		}
		// move up ...
		else if (orig<index)
		{
			var i = orig;
			while(i < index) {
				swapChildren(jeashChildren[i], jeashChildren[i+1]);
				i++;
			}
		}
	}

	private function jeashSwapSurface(c1:Int, c2:Int)
	{
		if (jeashChildren[c1] == null) throw "Null element at index " + c1 + " length " + jeashChildren.length;
		if (jeashChildren[c2] == null) throw "Null element at index " + c2 + " length " + jeashChildren.length;
		var gfx1 = jeashChildren[c1].jeashGetGraphics();
		var gfx2 = jeashChildren[c2].jeashGetGraphics();
		if (gfx1 != null && gfx2 != null)
			Lib.jeashSwapSurface(gfx1.jeashSurface, gfx2.jeashSurface);
	}

	public function swapChildren( child1 : DisplayObject, child2 : DisplayObject )
	{
		var c1 : Int = -1;
		var c2 : Int = -1;
		var swap : DisplayObject;
		for ( i in 0...jeashChildren.length )
			if ( jeashChildren[i] == child1 ) c1 = i;
			else if  ( jeashChildren[i] == child2 ) c2 = i;
		if ( c1 != -1 && c2 != -1 )
		{
			swap = jeashChildren[c1];
			jeashChildren[c1] = jeashChildren[c2];
			jeashChildren[c2] = swap;
			swap = null;
			jeashSwapSurface(c1, c2);
		}
	}

	public function swapChildrenAt( child1 : Int, child2 : Int )
	{
		var swap : DisplayObject = jeashChildren[child1];
		jeashChildren[child1] = jeashChildren[child2];
		jeashChildren[child2] = swap;
		swap = null;
	}

	override public function jeashGetObjectUnderPoint(point:Point)
	{
		if (!visible) return null;
		var l = jeashChildren.length-1;
		for(i in 0...jeashChildren.length)
		{
			var result = jeashChildren[l-i].jeashGetObjectUnderPoint(point);
			if (result != null)
				return result;
		}

		return super.jeashGetObjectUnderPoint(point);
	}

	// @r551
	public function getObjectsUnderPoint(point:Point)
	{
		var result = new Array<DisplayObject>();
		jeashGetObjectsUnderPoint(point, result);
		return result;
	}

	function jeashGetObjectsUnderPoint(point:Point, stack:Array<DisplayObject>)
	{
		var l = jeashChildren.length-1;
		for(i in 0...jeashChildren.length)
		{
			var result = jeashChildren[l-i].jeashGetObjectUnderPoint(point);
			if (result != null)
				stack.push(result);
		}

		//return super.jeashGetObjectsUnderPoint(point);
	}

	// TODO: check if we need to merge filters with children.
	override public function jeashSetFilters(filters:Array<Dynamic>) {
		super.jeashSetFilters(filters);
		for(obj in jeashChildren)
			obj.jeashSetFilters(filters);
		return filters;
	}

	override private function jeashSetVisible(visible:Bool) {
		super.jeashSetVisible(visible);
		for(i in 0...jeashChildren.length)
			if (jeashChildren[i].jeashIsOnStage())
				jeashChildren[i].jeashSetVisible(visible);
		return visible;
	}
}


#else
typedef DisplayObjectContainer = flash.display.DisplayObjectContainer;
#end