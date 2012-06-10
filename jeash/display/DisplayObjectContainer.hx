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
		numChildren = 0;
		tabChildren = true;
		super();
		name = "DisplayObjectContainer " +  jeash.display.DisplayObject.mNameID++;
	}

	override public function AsContainer() { return this; }

	// @r498
	override public function jeashBroadcast(event:jeash.events.Event) {
		for (child in jeashChildren)
			child.jeashBroadcast(event);
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

	public override function jeashGetNumChildren() {
		return jeashChildren.length;
	}

	override public function jeashRender(inMatrix:Matrix, inMask:HTMLCanvasElement, ?clipRect:Rectangle) {

		if (!visible) return;

		super.jeashRender(inMatrix, inMask, clipRect);
		for(obj in jeashChildren) {
			if (obj.visible) {
				if (clipRect != null) {
					var rect = new Rectangle();

					if(obj.mMtxDirty || obj.mMtxChainDirty){
						obj.jeashValidateMatrix();
					}

					rect.topLeft = obj.globalToLocal(clipRect.topLeft);
					rect.bottomRight = obj.globalToLocal(clipRect.bottomRight);
					obj.jeashRender(null, inMask, rect);
				} else {
					obj.jeashRender(null, inMask, null);
				}
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

	public function swapChildren( child1 : DisplayObject, child2 : DisplayObject ) {
		var c1 : Int = -1;
		var c2 : Int = -1;
		var swap : DisplayObject;
		for ( i in 0...jeashChildren.length )
			if ( jeashChildren[i] == child1 ) c1 = i;
			else if  ( jeashChildren[i] == child2 ) c2 = i;
		if ( c1 != -1 && c2 != -1 ) {
			swap = jeashChildren[c1];
			jeashChildren[c1] = jeashChildren[c2];
			jeashChildren[c2] = swap;
			swap = null;
			jeashSwapSurface(c1, c2);
			child1.jeashUnifyChildrenWithDOM();
			child2.jeashUnifyChildrenWithDOM();
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
				return mouseChildren ? result : this;
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
