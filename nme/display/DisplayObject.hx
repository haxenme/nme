package nme.display;
#if (cpp || neko)


import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.EventPhase;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.geom.Transform;
import nme.geom.ColorTransform;
import nme.geom.Point;
import nme.filters.BitmapFilter;
import nme.Loader;


class DisplayObject extends EventDispatcher, implements IBitmapDrawable
{
	
	/**
	 * The opacity of the object, as a percentage value from 0 to 1
	 */
	public var alpha(nmeGetAlpha, nmeSetAlpha):Float;
	
	/**
	 * Adjusts this object blends with other objects on-screen
	 */
	public var blendMode(nmeGetBlendMode, nmeSetBlendMode):BlendMode;
	
	/**
	 * If set to true, NME will render the object using its software renderer,
	 * then it will cache the result. This can improve performance for certain
	 * types of complex objects.
	 */
	public var cacheAsBitmap(nmeGetCacheAsBitmap, nmeSetCacheAsBitmap):Bool;
	
	/**
	 * An array of BitmapFilters being used with this object.
	 * 
	 * If you want to add, remove or change a filter, you need to re-assign
	 * the property, like "displayObject.filters = newFilters;" 
	 */
	public var filters(nmeGetFilters, nmeSetFilters):Array<Dynamic>;
	
	/**
	 * Returns a reference to the nme.display.Graphics interface
	 * for this object. You can use this class to draw primitives
	 * like squares, circles, lines, curves or tiles.
	 */
	public var graphics(nmeGetGraphics, null):Graphics;
	
	/**
	 * The height in pixels for this object
	 */
	public var height(nmeGetHeight, nmeSetHeight):Float;
	
	/**
	 * Define a mask to control how much of this object should
	 * be visible.
	 */
	public var mask(default, nmeSetMask):DisplayObject;
	
	/**
	 * Indicates the current mouse x position, using the coordinate system of
	 * this object.
	 */
	public var mouseX(nmeGetMouseX, null):Float;
	
	/**
	 * Indicates the current mouse y position, using the coordinate system of
	 * this object.
	 */
	public var mouseY(nmeGetMouseY, null):Float;
	
	/**
	 * Get or set the name for this object.
	 */
	public var name(nmeGetName, nmeSetName):String;
	
	/**
	 * @private
	 */
	public var nmeHandle:Dynamic;
	
	/**
	 * Set or change an opaque background color for this object.
	 */
	public var opaqueBackground(nmeGetBG, nmeSetBG):Null <Int>;
	
	/**
	 * If this object has been added to the display list, then this is
	 * the "parent" DisplayObjectContainer. Otherwise this will be
	 * null.
	 */
	public var parent(nmeGetParent, null):DisplayObjectContainer;
	
	/**
	 * Control the rotation of this object, in degrees.
	 */
	public var rotation(nmeGetRotation, nmeSetRotation):Float;
	
	/**
	 * Set a "scale 9" grid to control how the object stretches or
	 * squashes when its scale is changed.
	 */
	public var scale9Grid(nmeGetScale9Grid, nmeSetScale9Grid):Rectangle;
	
	/**
	 * Control the horizontal scale of the object, as a percentage value
	 */
	public var scaleX(nmeGetScaleX, nmeSetScaleX):Float;
	
	/**
	 * Control the vertical scale of the object, as a percentage value
	 */
	public var scaleY(nmeGetScaleY, nmeSetScaleY):Float;
	
	/**
	 * Set a "scroll rect" to control how much of the object should be rendered
	 */
	public var scrollRect(nmeGetScrollRect, nmeSetScrollRect):Rectangle;
	
	/**
	 * If this object has been added to the display list, which has been added
	 * to the stage, this will return the root Stage object. Otherwise, this will
	 * return null.
	 */
	public var stage(nmeGetStage, null):Stage;
	
	/**
	 * Set the matrix and color transform for this object.
	 * 
	 * If you want to change the object's transform, you need to re-assign
	 * the property, like "displayObject.transform = newTransform;" 
	 */
	public var transform(nmeGetTransform, nmeSetTransform):Transform;
	
	/**
	 * Controls whether this object is visible and rendered, or if
	 * it is invisible.
	 * 
	 * An object that has visible set to false will perform faster than
	 * and object that only has its alpha set to 0.
	 */
	public var visible(nmeGetVisible, nmeSetVisible):Bool;
	
	/**
	 * The width in pixels for this object
	 */
	public var width(nmeGetWidth, nmeSetWidth):Float;
	
	/**
	 * The x position for this object, local to its parent
	 */
	public var x(nmeGetX, nmeSetX):Float;
	
	/**
	 * The y position for this object, local to its parent
	 */
	public var y(nmeGetY, nmeSetY):Float;
	
	private var nmeFilters:Array<Dynamic>;
	private var nmeGraphicsCache:Graphics;
	private var nmeID:Int;
	private var nmeParent:DisplayObjectContainer;
	private var nmeScale9Grid:Rectangle;
	private var nmeScrollRect:Rectangle;
	

	public function new(inHandle:Dynamic, inType:String)
	{
		super(this);
		
		nmeParent = null;
		nmeHandle = inHandle;
		nmeID = nme_display_object_get_id(nmeHandle);
		nmeSetName (inType + " " + nmeID);
	}
	
	
	/**
	 * Converts a point from global coordinates to local coordinates.
	 * @param	inGlobal		A point in global coordinates
	 * @return		A point in local coordinates
	 */
	public function globalToLocal(inGlobal:Point):Point
	{
		var result = inGlobal.clone();
		nme_display_object_global_to_local(nmeHandle, result);
		return result;
	}
	
	
	/**
	 * Determines if the specified local coordinate point overlaps the
	 * contents of this object.
	 * 
	 * This method does not check for transparency, so if the object contains
	 * a bitmap image, transparent pixels will return "true" for a hit test.
	 * @param	x		The x coordinate point to test
	 * @param	y		The y coordinate point to test
	 * @param	shapeFlag		Whether to use the exact shape of this object (slower) or a bounding box
	 * @return		Whether the point intersects with the contents of this object
	 */
	public function hitTestPoint(x:Float, y:Float, shapeFlag:Bool = false):Bool
	{
		return nme_display_object_hit_test_point(nmeHandle, x, y, shapeFlag, true);
	}
	
	
	/**
	 * Converts a point from local coordinates to global coordinates.
	 * @param	inGlobal		A point in local coordinates
	 * @return		A point in global coordinates
	 */
	public function localToGlobal(inLocal:Point)
	{
		var result = inLocal.clone();
		nme_display_object_local_to_global(nmeHandle, result);
		return result;
	}
	
	
	private function nmeAsInteractiveObject():InteractiveObject
	{
		return null;
	}
	
	
	/**
	 * @private
	 */
	public function nmeBroadcast(inEvt:Event)
	{
		dispatchEvent(inEvt);
	}
	
	
	/**
	 * @private
	 */
	public function nmeDrawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void
	{
		// --- IBitmapDrawable interface ---
		nme_display_object_draw_to_surface(nmeHandle, inSurface, matrix, colorTransform, blendMode, clipRect);
	}
	
	
	private function nmeFindByID(inID:Int):DisplayObject
	{
		if (nmeID == inID)
			return this;
		return null;
	}
	
	
	private function nmeFireEvent(inEvt:Event)
	{
		var stack:Array<InteractiveObject> = [];
		
		if (nmeParent != null)
			nmeParent.nmeGetInteractiveObjectStack(stack);
		
		var l = stack.length;
		
		if (l > 0)
		{
			// First, the "capture" phase ...
			inEvt.nmeSetPhase(EventPhase.CAPTURING_PHASE);
			stack.reverse();
			
			for (obj in stack)
			{
				inEvt.currentTarget = obj;
				obj.dispatchEvent(inEvt);
				
				if (inEvt.nmeGetIsCancelled())
					return;
				
			}
		}
		
		// Next, the "target"
		inEvt.nmeSetPhase(EventPhase.AT_TARGET);
		inEvt.currentTarget = this;
		dispatchEvent(inEvt);
		
		if (inEvt.nmeGetIsCancelled())
			return;
		
		// Last, the "bubbles" phase
		if (inEvt.bubbles)
		{
			inEvt.nmeSetPhase(EventPhase.BUBBLING_PHASE);
			stack.reverse();
			
			for (obj in stack)
			{
				inEvt.currentTarget = obj;
				obj.dispatchEvent(inEvt);
				
				if (inEvt.nmeGetIsCancelled())
					return;
			}
		}
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetColorTransform():ColorTransform
	{ 
		var trans = new ColorTransform();
		nme_display_object_get_color_transform(nmeHandle, trans, false);
		return trans;
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetConcatenatedColorTransform():ColorTransform
	{
		var trans = new ColorTransform();
		nme_display_object_get_color_transform(nmeHandle, trans, true);
		return trans;
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetConcatenatedMatrix():Matrix
	{
		var mtx = new Matrix();
		nme_display_object_get_matrix(nmeHandle, mtx, true);
		return mtx;
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetInteractiveObjectStack(outStack:Array<InteractiveObject>)
	{
		var io = nmeAsInteractiveObject();
		
		if (io != null)
			outStack.push(io);
		
		if (nmeParent != null)
			nmeParent.nmeGetInteractiveObjectStack(outStack);
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetMatrix():Matrix
	{
		var mtx = new Matrix();
		nme_display_object_get_matrix(nmeHandle, mtx, false);
		return mtx;
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetObjectsUnderPoint(point:Point, result:Array<DisplayObject>)
	{
		if (nme_display_object_hit_test_point(nmeHandle, point.x, point.y, true, false))
			result.push(this);
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetPixelBounds():Rectangle
	{
		var rect = new Rectangle();
		nme_display_object_get_pixel_bounds(nmeHandle, rect);
		return rect;
	}
	
	
	private function nmeOnAdded(inObj:DisplayObject, inIsOnStage:Bool)
	{
		if (inObj == this)
		{
			var evt = new Event(Event.ADDED, true, false);
			evt.target = inObj;
			dispatchEvent(evt);
		}
		
		if (inIsOnStage)
		{
			var evt = new Event(Event.ADDED_TO_STAGE, false, false);
			evt.target = inObj;
			dispatchEvent(evt);
		}
	}
	
	
	private function nmeOnRemoved(inObj:DisplayObject, inWasOnStage:Bool)
	{
		if (inObj == this)
		{
			var evt = new Event(Event.REMOVED, true, false);
			evt.target = inObj;
			dispatchEvent(evt);
		}
		
		if (inWasOnStage)
		{
			var evt = new Event(Event.REMOVED_FROM_STAGE, false, false);
			evt.target = inObj;
			dispatchEvent(evt);
		}
	}
	
	
	/**
	 * @private
	 */
	public function nmeSetColorTransform(inTrans:ColorTransform)
	{
		nme_display_object_set_color_transform(nmeHandle, inTrans);
	}
	
	
	/**
	 * @private
	 */
	public function nmeSetMatrix(inMatrix:Matrix)
	{
		nme_display_object_set_matrix(nmeHandle, inMatrix);
	}
	
	
	/**
	 * @inheritDoc
	 */
	override public function toString():String
	{
		return name;
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetAlpha():Float {	return nme_display_object_get_alpha(nmeHandle); }
	private function nmeSetAlpha(inAlpha:Float):Float
	{
		nme_display_object_set_alpha(nmeHandle, inAlpha);
		return inAlpha;	
	}
   
   
	private function nmeGetBG():Null<Int>
	{
		var i:Int = nme_display_object_get_bg(nmeHandle);
		if ((i& 0x01000000)==0)
			return null;
		
		return i & 0xffffff;
	}
	
	
	private function nmeSetBG(inBG:Null<Int>):Null<Int>
	{	
		if (inBG == null)
			nme_display_object_set_bg(nmeHandle, 0);
		else
			nme_display_object_set_bg(nmeHandle, inBG);
		
		return inBG;
	}
	
	
	private function nmeGetBlendMode():BlendMode
	{	
		var i:Int = nme_display_object_get_blend_mode(nmeHandle);
		return Type.createEnumIndex(BlendMode, i);	
	}
	
	
	private function nmeSetBlendMode(inMode:BlendMode):BlendMode
	{	
		nme_display_object_set_blend_mode(nmeHandle, Type.enumIndex(inMode));
		return inMode;	
	}
	
	
	private function nmeGetCacheAsBitmap():Bool { return nme_display_object_get_cache_as_bitmap(nmeHandle); }
	private function nmeSetCacheAsBitmap(inVal:Bool):Bool
	{
		nme_display_object_set_cache_as_bitmap(nmeHandle,inVal);
		return inVal;
	}
	
	
	private function nmeGetFilters():Array<Dynamic>
	{	
		if (nmeFilters==null) return [];
		
		var result = new Array<Dynamic>();
		
		for (filter in nmeFilters)
			result.push(filter.clone());
		
		return result;
	}
	
	
	private function nmeSetFilters (inFilters:Array<Dynamic>):Array<Dynamic>
	{
		if (inFilters == null)
		{	
			nmeFilters = null;	
		}
		else
		{	
			nmeFilters = new Array<Dynamic>();
			
			for (filter in inFilters)
				nmeFilters.push(filter.clone());
		}
		
		nme_display_object_set_filters(nmeHandle, nmeFilters);
		
		return inFilters;
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetGraphics():Graphics
	{
		if (nmeGraphicsCache == null)
			nmeGraphicsCache = new Graphics(nme_display_object_get_graphics(nmeHandle));
		return nmeGraphicsCache;
	}
	
	
	private function nmeGetHeight():Float { return nme_display_object_get_height(nmeHandle); }
	private function nmeSetHeight(inVal:Float):Float
	{
		nme_display_object_set_height(nmeHandle, inVal);
		return inVal;
	}
	
	
	private function nmeSetMask(inObject:DisplayObject)
	{
		mask = inObject;
		nme_display_object_set_mask(nmeHandle, inObject == null ? null : inObject.nmeHandle);
		return inObject;
	}
	
	
	private function nmeGetMouseX():Float { return nme_display_object_get_mouse_x(nmeHandle); }
	private function nmeGetMouseY():Float { return nme_display_object_get_mouse_y(nmeHandle); }
	
	
	private function nmeGetName():String { return nme_display_object_get_name(nmeHandle); }
	private function nmeSetName(inVal:String):String
	{	
		nme_display_object_set_name(nmeHandle, inVal);
		return inVal;
	}
	
	
	private function nmeGetParent():DisplayObjectContainer { return nmeParent;	}
	
	/**
	 * @private
	 */
	public function nmeSetParent(inParent:DisplayObjectContainer)
	{	
		if (inParent == nmeParent)
			return inParent;
		
		if (nmeParent != null)
			nmeParent.nmeRemoveChildFromArray(this);
		
		if (nmeParent == null && inParent != null)
		{	
			nmeParent = inParent;
			nmeOnAdded(this, (stage != null));	
		}
		else if (nmeParent != null && inParent == null)
		{	
			var was_on_stage = (stage != null);
			nmeParent = inParent;
			nmeOnRemoved(this, was_on_stage);	
		}
		else
		{	
			nmeParent = inParent;	
		}
		
		return inParent;
	}
	
	
	private function nmeGetRotation():Float { return nme_display_object_get_rotation(nmeHandle); }
	private function nmeSetRotation(inVal:Float):Float
	{
		nme_display_object_set_rotation(nmeHandle, inVal);
		return inVal;
	}
	
	
	private function nmeGetScale9Grid():Rectangle { return (nmeScale9Grid == null) ? null : nmeScale9Grid.clone(); }
	private function nmeSetScale9Grid(inRect:Rectangle):Rectangle
	{
		nmeScale9Grid = (inRect == null) ? null : inRect.clone();
		nme_display_object_set_scale9_grid(nmeHandle, nmeScale9Grid);
		return inRect;
	}
	
	
	private function nmeGetScaleX():Float { return nme_display_object_get_scale_x(nmeHandle); }
	private function nmeSetScaleX(inVal:Float):Float
	{	
		nme_display_object_set_scale_x(nmeHandle, inVal);
		return inVal;
	}

	
	private function nmeGetScaleY():Float { return nme_display_object_get_scale_y(nmeHandle); }
	private function nmeSetScaleY(inVal:Float):Float
	{	
		nme_display_object_set_scale_y(nmeHandle, inVal);
		return inVal;
	}
	
	
	private function nmeGetScrollRect():Rectangle { return (nmeScrollRect == null) ? null : nmeScrollRect.clone(); }
	private function nmeSetScrollRect(inRect:Rectangle):Rectangle
	{
		nmeScrollRect = (inRect == null) ? null : inRect.clone();
		nme_display_object_set_scroll_rect(nmeHandle, nmeScrollRect);
		return inRect;
	}
	
	
	/**
	 * @private
	 */
	public function nmeGetStage():Stage
	{	
		if (nmeParent != null)
			return nmeParent.nmeGetStage();
		
		return null;	
	}
	
	
	private function nmeGetTransform():Transform { return new Transform(this); }
	private function nmeSetTransform(inTransform:Transform):Transform
	{	
		nmeSetMatrix(inTransform.matrix);
		nmeSetColorTransform(inTransform.colorTransform);
		return inTransform;
	}
	
	
	private function nmeGetVisible():Bool { return nme_display_object_get_visible(nmeHandle);	}
	private function nmeSetVisible(inVal:Bool):Bool
	{	
		nme_display_object_set_visible(nmeHandle, inVal);
		return inVal;
	}
	
	
	private function nmeGetWidth():Float { return nme_display_object_get_width(nmeHandle); }
	private function nmeSetWidth(inVal:Float):Float
	{	
		nme_display_object_set_width(nmeHandle, inVal);
		return inVal;
	}
	
	
	private function nmeGetX():Float { return nme_display_object_get_x(nmeHandle); }
	private function nmeSetX(inVal:Float):Float
	{	
		nme_display_object_set_x(nmeHandle, inVal);
		return inVal;	
	}
	
	
	private function nmeGetY():Float { return nme_display_object_get_y(nmeHandle); }
	private function nmeSetY(inVal:Float):Float
	{
		nme_display_object_set_y(nmeHandle, inVal);
		return inVal;
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_create_display_object = Loader.load("nme_create_display_object", 0);
	private static var nme_display_object_get_graphics = Loader.load("nme_display_object_get_graphics", 1);
	private static var nme_display_object_draw_to_surface = Loader.load("nme_display_object_draw_to_surface", -1);
	private static var nme_display_object_get_id = Loader.load("nme_display_object_get_id", 1);
	private static var nme_display_object_get_x = Loader.load("nme_display_object_get_x", 1);
	private static var nme_display_object_set_x = Loader.load("nme_display_object_set_x", 2);
	private static var nme_display_object_get_y = Loader.load("nme_display_object_get_y", 1);
	private static var nme_display_object_set_y = Loader.load("nme_display_object_set_y", 2);
	private static var nme_display_object_get_scale_x = Loader.load("nme_display_object_get_scale_x", 1);
	private static var nme_display_object_set_scale_x = Loader.load("nme_display_object_set_scale_x", 2);
	private static var nme_display_object_get_scale_y = Loader.load("nme_display_object_get_scale_y", 1);
	private static var nme_display_object_set_scale_y = Loader.load("nme_display_object_set_scale_y", 2);
	private static var nme_display_object_get_mouse_x = Loader.load("nme_display_object_get_mouse_x", 1);
	private static var nme_display_object_get_mouse_y = Loader.load("nme_display_object_get_mouse_y", 1);
	private static var nme_display_object_get_rotation = Loader.load("nme_display_object_get_rotation", 1);
	private static var nme_display_object_set_rotation = Loader.load("nme_display_object_set_rotation", 2);
	private static var nme_display_object_get_bg = Loader.load("nme_display_object_get_bg", 1);
	private static var nme_display_object_set_bg = Loader.load("nme_display_object_set_bg", 2);
	private static var nme_display_object_get_name = Loader.load("nme_display_object_get_name", 1);
	private static var nme_display_object_set_name = Loader.load("nme_display_object_set_name", 2);
	private static var nme_display_object_get_width = Loader.load("nme_display_object_get_width", 1);
	private static var nme_display_object_set_width = Loader.load("nme_display_object_set_width", 2);
	private static var nme_display_object_get_height = Loader.load("nme_display_object_get_height", 1);
	private static var nme_display_object_set_height = Loader.load("nme_display_object_set_height", 2);
	private static var nme_display_object_get_alpha = Loader.load("nme_display_object_get_alpha", 1);
	private static var nme_display_object_set_alpha = Loader.load("nme_display_object_set_alpha", 2);
	private static var nme_display_object_get_blend_mode = Loader.load("nme_display_object_get_blend_mode", 1);
	private static var nme_display_object_set_blend_mode = Loader.load("nme_display_object_set_blend_mode", 2);
	private static var nme_display_object_get_cache_as_bitmap = Loader.load("nme_display_object_get_cache_as_bitmap", 1);
	private static var nme_display_object_set_cache_as_bitmap = Loader.load("nme_display_object_set_cache_as_bitmap", 2);
	private static var nme_display_object_get_visible = Loader.load("nme_display_object_get_visible", 1);
	private static var nme_display_object_set_visible = Loader.load("nme_display_object_set_visible", 2);
	private static var nme_display_object_set_filters = Loader.load("nme_display_object_set_filters", 2);
	private static var nme_display_object_global_to_local = Loader.load("nme_display_object_global_to_local", 2);
	private static var nme_display_object_local_to_global = Loader.load("nme_display_object_local_to_global", 2);
	private static var nme_display_object_set_scale9_grid = Loader.load("nme_display_object_set_scale9_grid", 2);
	private static var nme_display_object_set_scroll_rect = Loader.load("nme_display_object_set_scroll_rect", 2);
	private static var nme_display_object_set_mask = Loader.load("nme_display_object_set_mask", 2);
	private static var nme_display_object_set_matrix = Loader.load("nme_display_object_set_matrix", 2);
	private static var nme_display_object_get_matrix = Loader.load("nme_display_object_get_matrix", 3);
	private static var nme_display_object_get_color_transform = Loader.load("nme_display_object_get_color_transform", 3);
	private static var nme_display_object_set_color_transform = Loader.load("nme_display_object_set_color_transform", 2);
	private static var nme_display_object_get_pixel_bounds = Loader.load("nme_display_object_get_pixel_bounds", 2);
	private static var nme_display_object_hit_test_point = Loader.load("nme_display_object_hit_test_point", 5);

}


#elseif js


import Html5Dom;

import nme.accessibility.AccessibilityProperties;
import nme.display.Stage;
import nme.display.Graphics;
import nme.events.EventDispatcher;
import nme.events.Event;
import nme.events.EventPhase;
import nme.display.DisplayObjectContainer;
import nme.display.IBitmapDrawable;
import nme.display.InteractiveObject;
import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Transform;
import nme.filters.BitmapFilter;
import nme.display.BitmapData;
import nme.Lib;

typedef BufferData =
{
	var buffer:WebGLBuffer;
	var size:Int;
	var location:GLint;
}

/**
 * @author	Niel Drummond
 * @author	Hugh Sanderson
 * @author	Russell Weir
 */
class DisplayObject extends EventDispatcher, implements IBitmapDrawable
{
	
	public var x(jeashGetX,jeashSetX):Float;
	public var y(jeashGetY,jeashSetY):Float;
	public var scaleX(jeashGetScaleX,jeashSetScaleX):Float;
	public var scaleY(jeashGetScaleY,jeashSetScaleY):Float;
	public var rotation(jeashGetRotation,jeashSetRotation):Float;
	
	public var accessibilityProperties:AccessibilityProperties;
	public var alpha:Float;
	public var name(default,default):String;
	public var cacheAsBitmap:Bool;
	public var width(jeashGetWidth,jeashSetWidth):Float;
	public var height(jeashGetHeight,jeashSetHeight):Float;

	public var visible(jeashGetVisible,jeashSetVisible):Bool;
	public var opaqueBackground(GetOpaqueBackground,SetOpaqueBackground):Null<Int>;
	public var mouseX(jeashGetMouseX, jeashSetMouseX):Float;
	public var mouseY(jeashGetMouseY, jeashSetMouseY):Float;
	public var parent:DisplayObjectContainer;
	public var stage(GetStage,null):Stage;
	
	public var scrollRect(GetScrollRect,SetScrollRect):Rectangle;
	public var mask(GetMask,SetMask):DisplayObject;
	public var filters(jeashGetFilters,jeashSetFilters):Array<Dynamic>;
	public var blendMode : flash.display.BlendMode;
	public var loaderInfo:LoaderInfo;


	// This is used by the swf-code for z-sorting
	public var __swf_depth:Int;

	public var transform(GetTransform,SetTransform):Transform;

	var mBoundsDirty:Bool;
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

	static var mNameID = 0;

	var mScrollRect:Rectangle;
	var mOpaqueBackground:Null<Int>;

	var mMask:DisplayObject;
	var mMaskingObj:DisplayObject;
	var mMaskHandle:Dynamic;
	var jeashFilters:Array<BitmapFilter>;
	
	
	public function new()
	{
		parent = null;
		super(null);
		x = y = 0;
		jeashScaleX = jeashScaleY = 1.0;
		alpha = 1.0;
		rotation = 0.0;
		__swf_depth = 0;
		mMatrix = new Matrix();
		mFullMatrix = new Matrix();
		mMask = null;
		mMaskingObj = null;
		mBoundsRect = new Rectangle();
		mGraphicsBounds = null;
		mMaskHandle = null;
		name = "DisplayObject " + mNameID++;

		visible = true;
	}

	override public function toString() { return name; }

	function jeashDoAdded(inObj:DisplayObject)
	{
		if (inObj==this)
		{
			var evt = new flash.events.Event(flash.events.Event.ADDED, true, false);
			evt.target = inObj;
			dispatchEvent(evt);
		}

		var evt = new flash.events.Event(flash.events.Event.ADDED_TO_STAGE, false, false);
		evt.target = inObj;
		dispatchEvent(evt);
	}

	function jeashDoRemoved(inObj:DisplayObject)
	{
		if (inObj==this)
		{
			var evt = new flash.events.Event(flash.events.Event.REMOVED, true, false);
			evt.target = inObj;
			dispatchEvent(evt);
		}
		var evt = new flash.events.Event(flash.events.Event.REMOVED_FROM_STAGE, false, false);
		evt.target = inObj;
		dispatchEvent(evt);

		var gfx = jeashGetGraphics();
		if (gfx != null)
			Lib.jeashRemoveSurface(gfx.jeashSurface);
	}
	public function DoMouseEnter() {}
	public function DoMouseLeave() {}

	public function jeashSetParent(parent:DisplayObjectContainer)
	{
		if (parent == this.parent)
			return;

		mMtxChainDirty=true;

		if (this.parent != null)
		{
			this.parent.__removeChild(this);
			this.parent.jeashInvalidateBounds();	
		}
		
		if(parent != null)
		{
			parent.jeashInvalidateBounds();
		}

		if (this.parent==null && parent!=null)
		{
			this.parent = parent;
			jeashDoAdded(this);
		}
		else if (this.parent != null && parent==null)
		{
			this.parent = parent;
			jeashDoRemoved(this);
		}
		else{
			this.parent = parent;
		}

	}

	public function GetStage() { return flash.Lib.jeashGetStage(); }
	public function AsContainer() : DisplayObjectContainer { return null; }

	public function GetScrollRect() : Rectangle
	{
		if (mScrollRect==null) return null;
		return mScrollRect.clone();
	}

	public function jeashAsInteractiveObject() : flash.display.InteractiveObject
	{ return null; }

	public function SetScrollRect(inRect:Rectangle)
	{
		mScrollRect = inRect;
		return GetScrollRect();
	}

	public function hitTestObject(obj:DisplayObject)
	{
		return false;
	}

	public function hitTestPoint(x:Float, y:Float, ?shapeFlag:Bool)
	{
		var bounding_box:Bool = shapeFlag==null ? true : !shapeFlag;

		// TODO:
		return true;
	}

	public function localToGlobal( point:Point )
	{
		if ( this.parent == null )
		{
			return new Point( this.x + point.x, this.y + point.y );
		} else {
			point.x = point.x + this.x;
			point.y = point.y + this.y;
			return this.parent.localToGlobal( point );
		}
	}

	function jeashGetMouseX() { return globalToLocal(new Point(stage.mouseX, 0)).x; }
	function jeashSetMouseX(x:Float) { return null; }
	function jeashGetMouseY() { return globalToLocal(new Point(0, stage.mouseY)).y; }
	function jeashSetMouseY(y:Float) { return null; }

	public function GetTransform() { return  new Transform(this); }

	public function SetTransform(trans:Transform)
	{
		mMatrix = trans.matrix.clone();
		return trans;
	}
	
	public function getFullMatrix(?childMatrix:Matrix=null) {
		if(childMatrix==null) {
			return mFullMatrix.clone();
		} else {
			return childMatrix.mult(mFullMatrix);
		}
	}

	public function getBounds(targetCoordinateSpace : DisplayObject) : Rectangle 
	{		
		if(mMtxDirty || mMtxChainDirty)
			jeashValidateMatrix();
		
		if(mBoundsDirty)
		{
			BuildBounds();
		}
		
		var mtx : Matrix = mFullMatrix.clone();
		//perhaps inverse should be stored and updated lazily?
		mtx.concat(targetCoordinateSpace.mFullMatrix.clone().invert());
		var rect : Rectangle = mBoundsRect.transform(mtx);	//transform does cloning
		return rect;
	}

	public function getRect(targetCoordinateSpace : DisplayObject) : Rectangle 
	{
		// TODO
		return null;
	}

	public function globalToLocal(inPos:Point) 
		return mFullMatrix.clone().invert().transformPoint(inPos)
	
	public function jeashGetNumChildren() return 0

	public function jeashGetMatrix() return mMatrix.clone()

	public function jeashSetMatrix(inMatrix:Matrix) {
		mMatrix = inMatrix.clone();
		return inMatrix;
	}

	function jeashGetGraphics() : flash.display.Graphics return null

	public function GetOpaqueBackground() { return mOpaqueBackground; }
	public function SetOpaqueBackground(inBG:Null<Int>)
	{
		mOpaqueBackground = inBG;
		return mOpaqueBackground;
	}

	public function GetBackgroundRect()
	{
		if (mGraphicsBounds==null)
		{
			var gfx = jeashGetGraphics();
			if (gfx!=null)
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
	public function jeashInvalidateBounds():Void{
		//TODO :: adjust so that parent is only invalidated if it's bounds are changed by this change
		mBoundsDirty=true;
		if(parent!=null)
			parent.jeashInvalidateBounds();
	}
	
	/**
	 * Matrices are invalidated when:
	 * - the object is scaled, rotated, translated, or skewed
	 * - an object's parent has its matrices invalidated
	 * ---> 	Invalidates up through children
	 */
	function jeashInvalidateMatrix( ? local : Bool = false):Void {
		mMtxChainDirty= mMtxChainDirty || !local;	//note that a parent has an invalid matrix 
		mMtxDirty = mMtxDirty || local; //invalidate the local matrix
	}
	
	public function jeashValidateMatrix() {
		
		if(mMtxDirty || (mMtxChainDirty && parent!=null)) {
			//validate parent matrix
			if(mMtxChainDirty && parent!=null) {
				parent.jeashValidateMatrix();
			}
			
			//validate local matrix
			if(mMtxDirty) {
				//update matrix if necessary
				//set non scale elements to identity
				mMatrix.b = mMatrix.c = mMatrix.tx = mMatrix.ty = 0;
			
				//set scale
				mMatrix.a=jeashScaleX;
				mMatrix.d=jeashScaleY;
			
				//set rotation if necessary
				var rad = jeashRotation * Math.PI / 180.0;
		
				if(rad!=0.0)
					mMatrix.rotate(rad);
			
				//set translation
				mMatrix.tx=jeashX;
				mMatrix.ty=jeashY;	
			}
			
			
			if (parent!=null)
				mFullMatrix = parent.getFullMatrix(mMatrix);
			else
				mFullMatrix = mMatrix;
			
			mMtxDirty = mMtxChainDirty = false;
		}
	}
	

	public function jeashRender(parentMatrix:Matrix, ?inMask:HTMLCanvasElement) {
		
		var gfx = jeashGetGraphics();

		if (gfx!=null) {
			// Cases when the rendering phase should be skipped
			if (gfx.jeashIsTile || !jeashVisible) return;

			if(mMtxDirty || mMtxChainDirty){
				jeashValidateMatrix();
			}
			
			var m = mFullMatrix.clone();

			if (jeashFilters != null && (gfx.jeashChanged || inMask != null)) {
				gfx.jeashRender(inMask, m);
				for (filter in jeashFilters) {
					filter.jeashApplyFilter(gfx.jeashSurface);
				}
			} else gfx.jeashRender(inMask, m);

			m.tx = m.tx + gfx.jeashExtent.x*m.a + gfx.jeashExtent.y*m.c;
			m.ty = m.ty + gfx.jeashExtent.x*m.b + gfx.jeashExtent.y*m.d;

			if (inMask != null) {
				Lib.jeashDrawToSurface(gfx.jeashSurface, inMask, m, (parent != null ? parent.alpha : 1) * alpha);
			} else {
				Lib.jeashSetSurfaceTransform(gfx.jeashSurface, m);
				Lib.jeashSetSurfaceOpacity(gfx.jeashSurface, (parent != null ? parent.alpha : 1) * alpha);
			}

		} else {
			if(mMtxDirty || mMtxChainDirty){
				jeashValidateMatrix();
			}
		}
	}

	public function drawToSurface(inSurface : Dynamic,
			matrix:flash.geom.Matrix,
			colorTransform:flash.geom.ColorTransform,
			blendMode:BlendMode,
			clipRect:flash.geom.Rectangle,
			smoothing:Bool):Void {
		if (matrix==null) matrix = new Matrix();
		jeashRender(matrix, inSurface);
	}

	public function jeashGetObjectUnderPoint(point:Point):DisplayObject {
		if (!visible) return null;
		var gfx = jeashGetGraphics();
		if (gfx != null) {
			var local = globalToLocal(point);
			switch (stage.jeashPointInPathMode) {
				case USER_SPACE:
					if (local.x < 0 || local.y < 0 || (local.x)*scaleX > width || (local.y)*scaleY > height) return null; 
					if (gfx.jeashHitTest(local.x, local.y))
						return cast this;
				case DEVICE_SPACE:
					if (local.x < 0 || local.y < 0 || (local.x)*scaleX > width || (local.y)*scaleY > height) return null; 
					if (gfx.jeashHitTest((local.x)*scaleX, (local.y)*scaleY))
						return cast this;
			}
		}

		return null;
	}


	// Masking
	public function GetMask() : DisplayObject { return mMask; }

	public function SetMask(inMask:DisplayObject) : DisplayObject
	{
		if (mMask!=null)
			mMask.mMaskingObj = null;
		mMask = inMask;
		if (mMask!=null)
			mMask.mMaskingObj = this;
		return mMask;
	}

	// @r533
	public function jeashSetFilters(filters:Array<Dynamic>) {
		if (filters==null)
			jeashFilters = null;
		else {
			jeashFilters = new Array<BitmapFilter>();
			for(filter in filters) jeashFilters.push(filter.clone());
		}

		return filters;
	}

	// @r533
	public function jeashGetFilters() {
		if (jeashFilters==null) return [];
		var result = new Array<BitmapFilter>();
		for(filter in jeashFilters)
			result.push(filter.clone());
		return result;
	}

	function BuildBounds()
	{
		var gfx = jeashGetGraphics();
		if (gfx==null)
			mBoundsRect = new Rectangle(x,y,0,0);
		else
		{
			mBoundsRect = gfx.jeashExtent.clone();
			gfx.markBoundsClean();
			if (mScale9Grid!=null)
			{
				mBoundsRect.width *= scaleX;
				mBoundsRect.height *= scaleY;
			}
		}
		mBoundsDirty=false;
	}

	function GetScreenBounds()
	{
		if(mBoundsDirty)
			BuildBounds();
		return mBoundsRect.clone();
	}

	public function GetFocusObjects(outObjs:Array<InteractiveObject>) { }
	inline function __BlendIndex():Int
	{
		return blendMode == null ? Graphics.BLEND_NORMAL : Type.enumIndex(blendMode);
	}

	public function jeashGetInteractiveObjectStack(outStack:Array<InteractiveObject>)
	{
		var io = jeashAsInteractiveObject();
		if (io != null)
			outStack.push(io);
		if (this.parent != null)
			this.parent.jeashGetInteractiveObjectStack(outStack);
	}

	// @r551
	public function jeashFireEvent(event:flash.events.Event)
	{
		var stack:Array<InteractiveObject> = [];
		if (this.parent != null)
			this.parent.jeashGetInteractiveObjectStack(stack);
		var l = stack.length;

		if (l>0)
		{
			// First, the "capture" phase ...
			event.jeashSetPhase(EventPhase.CAPTURING_PHASE);
			stack.reverse();
			for(obj in stack)
			{
				event.currentTarget = obj;
				obj.dispatchEvent(event);
				if (event.jeashGetIsCancelled())
					return;
			}
		}

		// Next, the "target"
		event.jeashSetPhase(EventPhase.AT_TARGET);
		event.currentTarget = this;
		dispatchEvent(event);
		if (event.jeashGetIsCancelled())
			return;

		// Last, the "bubbles" phase
		if (event.bubbles)
		{
			event.jeashSetPhase(EventPhase.BUBBLING_PHASE);
			stack.reverse();
			for(obj in stack)
			{
				event.currentTarget = obj;
				obj.dispatchEvent(event);
				if (event.jeashGetIsCancelled())
					return;
			}
		}
	}

	// @533
	public function jeashBroadcast(event:flash.events.Event)
	{
		dispatchEvent(event);
	}

	function jeashAddToStage()
	{
		var gfx = jeashGetGraphics();
		if (gfx != null)
			Lib.jeashAppendSurface(gfx.jeashSurface);
	}

	function jeashInsertBefore(obj:DisplayObject)
	{
		var gfx1 = jeashGetGraphics();
		var gfx2 = obj.jeashIsOnStage() ? obj.jeashGetGraphics() : null;
		if (gfx1 != null)
		{
			if (gfx2 != null )
				Lib.jeashAppendSurface(gfx1.jeashSurface, gfx2.jeashSurface);
			 else 
				Lib.jeashAppendSurface(gfx1.jeashSurface);
		}
	}

	function jeashIsOnStage() {
		var gfx = jeashGetGraphics();
		if (gfx != null)
			return Lib.jeashIsOnStage(gfx.jeashSurface);
		return false;
	}

	function jeashGetVisible() { return jeashVisible; }
	function jeashSetVisible(visible:Bool) {
		var gfx = jeashGetGraphics();
		if (gfx != null)
			if (gfx.jeashSurface != null)
				Lib.jeashSetSurfaceVisible(gfx.jeashSurface, visible);
		jeashVisible = visible;
		return visible;
	}

	public function jeashGetHeight() : Float
	{
		BuildBounds();
		return jeashScaleY * mBoundsRect.height;
	}
	public function jeashSetHeight(inHeight:Float) : Float {
		if(parent!=null)
			parent.jeashInvalidateBounds();
		if(mBoundsDirty)
			BuildBounds();
		var h = mBoundsRect.height;
		if (jeashScaleY*h != inHeight)
		{
			if (h<=0) return 0;
			jeashScaleY = inHeight/h;
			jeashInvalidateMatrix(true);
		}
		return inHeight;
	}

	public function jeashGetWidth() : Float {
		if(mBoundsDirty){
			BuildBounds();
		}
		return jeashScaleX * mBoundsRect.width;
	}

	public function jeashSetWidth(inWidth:Float) : Float {
		if(parent!=null)
			parent.jeashInvalidateBounds();
		if(mBoundsDirty)
			BuildBounds();
		var w = mBoundsRect.width;
		if (jeashScaleX*w != inWidth)
		{
			if (w<=0) return 0;
			jeashScaleX = inWidth/w;
			jeashInvalidateMatrix(true);
		}
		return inWidth;
	}

	public function jeashGetX():Float{
		return jeashX;
	}
	
	public function jeashGetY():Float{
		return jeashY;
	}
	
	public function jeashSetX(n:Float):Float{
		jeashInvalidateMatrix(true);
		jeashX=n;
		if(parent!=null)
			parent.jeashInvalidateBounds();
		return n;
	}

	public function jeashSetY(n:Float):Float{
		jeashInvalidateMatrix(true);
		jeashY=n;
		if(parent!=null)
			parent.jeashInvalidateBounds();
		return n;
	}


	public function jeashGetScaleX() { return jeashScaleX; }
	public function jeashGetScaleY() { return jeashScaleY; }
	public function jeashSetScaleX(inS:Float) { 
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

	public function jeashSetScaleY(inS:Float) { 
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

	private function jeashSetRotation(n:Float):Float{
		if(!mMtxDirty)
			jeashInvalidateMatrix(true);
		if(parent!=null)
			parent.jeashInvalidateBounds();

		jeashRotation = n;
		return n;
	}
	
	private function jeashGetRotation():Float{
		return jeashRotation;
	}


}


#else
typedef DisplayObject = flash.display.DisplayObject;
#end