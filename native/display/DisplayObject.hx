package native.display;


import native.events.Event;
import native.events.EventDispatcher;
import native.events.EventPhase;
import native.geom.Point;
import native.geom.Rectangle;
import native.geom.Matrix;
import native.geom.Transform;
import native.geom.ColorTransform;
import native.geom.Point;
import native.filters.BitmapFilter;
import native.Loader;


class DisplayObject extends EventDispatcher, implements IBitmapDrawable {
	
	
	public var alpha (get_alpha, set_alpha):Float;
	public var blendMode (get_blendMode, set_blendMode):BlendMode;
	public var cacheAsBitmap (get_cacheAsBitmap, set_cacheAsBitmap):Bool;
	public var pedanticBitmapCaching (get_pedanticBitmapCaching, set_pedanticBitmapCaching):Bool;
	public var pixelSnapping (get_pixelSnapping, set_pixelSnapping):PixelSnapping;
	public var filters (get_filters, set_filters):Array<Dynamic>;
	public var graphics (get_graphics, null):Graphics;
	public var height (get_height, set_height):Float;
	public var mask (default, set_mask):DisplayObject;
	public var mouseX (get_mouseX, null):Float;
	public var mouseY (get_mouseY, null):Float;
	public var name (get_name, set_name):String;
	public var opaqueBackground (get_opaqueBackground, set_opaqueBackground):Null <Int>;
	public var parent (get_parent, null):DisplayObjectContainer;
	public var rotation (get_rotation, set_rotation):Float;
	public var scale9Grid (get_scale9Grid, set_scale9Grid):Rectangle;
	public var scaleX (get_scaleX, set_scaleX):Float;
	public var scaleY (get_scaleY, set_scaleY):Float;
	public var scrollRect (get_scrollRect, set_scrollRect):Rectangle;
	public var stage (get_stage, null):Stage;
	public var transform (get_transform, set_transform):Transform;
	public var visible (get_visible, set_visible):Bool;
	public var width (get_width, set_width):Float;
	public var x (get_x, set_x):Float;
	public var y (get_y, set_y):Float;
	
	/** @private */ public var nmeHandle:Dynamic;
	
	/** @private */	private var nmeFilters:Array<Dynamic>;
	/** @private */	private var nmeGraphicsCache:Graphics;
	/** @private */	private var nmeID:Int;
	/** @private */	private var nmeParent:DisplayObjectContainer;
	/** @private */	private var nmeScale9Grid:Rectangle;
	/** @private */	private var nmeScrollRect:Rectangle;
	

	public function new (inHandle:Dynamic, inType:String) {
		
		super (this);
		
		nmeParent = null;
		nmeHandle = inHandle;
		nmeID = nme_display_object_get_id (nmeHandle);
		this.name = inType + " " + nmeID;
		
	}
	
	
	override public function dispatchEvent (event:Event):Bool {
		
		var result = nmeDispatchEvent (event);
		
		if (event.nmeGetIsCancelled ())
			return true;
		
		if (event.bubbles && parent != null) {
			
			parent.dispatchEvent (event);
			
		}
		
		return result;
		
	}
	
	
	public function getBounds (targetCoordinateSpace:DisplayObject):Rectangle {
		
		var result = new Rectangle ();
		nme_display_object_get_bounds (nmeHandle, targetCoordinateSpace.nmeHandle, result, true);
		return result;
		
	}
	
	
	public function getRect (targetCoordinateSpace:DisplayObject):Rectangle {
		
		var result = new Rectangle ();
		nme_display_object_get_bounds (nmeHandle, targetCoordinateSpace.nmeHandle, result, false);
		return result;
		
	}
	
	
	public function globalToLocal (inGlobal:Point):Point {
		
		var result = inGlobal.clone ();
		nme_display_object_global_to_local (nmeHandle, result);
		return result;
		
	}
	
	
	public function hitTestObject (object:DisplayObject):Bool {
		
		if (object != null && object.parent != null && parent != null) {
			
			var currentMatrix = transform.concatenatedMatrix;
			var targetMatrix = object.transform.concatenatedMatrix;
			
			var xPoint = new Point (1, 0);
			var yPoint = new Point (0, 1);
			
			var currentWidth = width * currentMatrix.deltaTransformPoint (xPoint).length;
			var currentHeight = height * currentMatrix.deltaTransformPoint (yPoint).length;
			var targetWidth = object.width * targetMatrix.deltaTransformPoint (xPoint).length;
			var targetHeight = object.height * targetMatrix.deltaTransformPoint (yPoint).length;
			
			var currentRect = new Rectangle (currentMatrix.tx, currentMatrix.ty, currentWidth, currentHeight);
			var targetRect = new Rectangle (targetMatrix.tx, targetMatrix.ty, targetWidth, targetHeight);
			
			return currentRect.intersects (targetRect);
			
		}
		
		return false;
		
	}
	
	
	public function hitTestPoint (x:Float, y:Float, shapeFlag:Bool = false):Bool {
		
		return nme_display_object_hit_test_point(nmeHandle, x, y, shapeFlag, true);
		
	}
	
	
	public function localToGlobal (inLocal:Point) {
		
		var result = inLocal.clone ();
		nme_display_object_local_to_global (nmeHandle, result);
		return result;
		
	}
	
	
	/** @private */ private function nmeAsInteractiveObject ():InteractiveObject {
		
		return null;
		
	}
	
	
	/** @private */ public function nmeBroadcast (inEvt:Event) {
		
		nmeDispatchEvent (inEvt);
		
	}
	
	
	/** @private */ public function nmeDispatchEvent (inEvt:Event):Bool {
		
		if (inEvt.target == null) {
			
			inEvt.target = this;
			
		}
		
		inEvt.currentTarget = this;
		return super.dispatchEvent (inEvt);
		
	}
	
	
	/** @private */ public function nmeDrawToSurface (inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void {
		
		// --- IBitmapDrawable interface ---
		nme_display_object_draw_to_surface (nmeHandle, inSurface, matrix, colorTransform, blendMode, clipRect);
		
	}
	
	
	/** @private */ private function nmeFindByID (inID:Int):DisplayObject {
		
		if (nmeID == inID)
			return this;
		return null;
		
	}
	
	
	/** @private */ private function nmeFireEvent (inEvt:Event) {
		
		var stack:Array<InteractiveObject> = [];
		
		if (nmeParent != null)
			nmeParent.nmeGetInteractiveObjectStack(stack);
		
		var l = stack.length;
		
		if (l > 0) {
			
			// First, the "capture" phase ...
			inEvt.nmeSetPhase (EventPhase.CAPTURING_PHASE);
			stack.reverse ();
			
			for (obj in stack) {
				
				inEvt.currentTarget = obj;
				obj.nmeDispatchEvent (inEvt);
				
				if (inEvt.nmeGetIsCancelled ())
					return;
				
			}
			
		}
		
		// Next, the "target"
		inEvt.nmeSetPhase (EventPhase.AT_TARGET);
		inEvt.currentTarget = this;
		nmeDispatchEvent (inEvt);
		
		if (inEvt.nmeGetIsCancelled ())
			return;
		
		// Last, the "bubbles" phase
		if (inEvt.bubbles) {
			
			inEvt.nmeSetPhase (EventPhase.BUBBLING_PHASE);
			stack.reverse ();
			
			for (obj in stack) {
				
				inEvt.currentTarget = obj;
				obj.nmeDispatchEvent (inEvt);
				
				if (inEvt.nmeGetIsCancelled ())
					return;
				
			}
			
		}
		
	}
	
	
	/** @private */ public function nmeGetColorTransform ():ColorTransform {
		
		var trans = new ColorTransform ();
		nme_display_object_get_color_transform (nmeHandle, trans, false);
		return trans;
		
	}
	
	
	/** @private */ public function nmeGetConcatenatedColorTransform ():ColorTransform {
		
		var trans = new ColorTransform ();
		nme_display_object_get_color_transform (nmeHandle, trans, true);
		return trans;
		
	}
	
	
	/** @private */ public function nmeGetConcatenatedMatrix ():Matrix {
		
		var mtx = new Matrix ();
		nme_display_object_get_matrix (nmeHandle, mtx, true);
		return mtx;
		
	}
	
	
	/** @private */ public function nmeGetInteractiveObjectStack (outStack:Array<InteractiveObject>) {
		
		var io = nmeAsInteractiveObject ();
		
		if (io != null)
			outStack.push (io);
		
		if (nmeParent != null)
			nmeParent.nmeGetInteractiveObjectStack (outStack);
		
	}
	
	
	/** @private */ public function nmeGetMatrix ():Matrix {
		
		var mtx = new Matrix ();
		nme_display_object_get_matrix (nmeHandle, mtx, false);
		return mtx;
		
	}
	
	
	/** @private */ public function nmeGetObjectsUnderPoint (point:Point, result:Array<DisplayObject>) {
		
		if (nme_display_object_hit_test_point (nmeHandle, point.x, point.y, true, false))
			result.push (this);
		
	}
	
	
	/** @private */ public function nmeGetPixelBounds ():Rectangle {
		
		var rect = new Rectangle ();
		nme_display_object_get_pixel_bounds (nmeHandle, rect);
		return rect;
		
	}
	
	
	/** @private */ private function nmeOnAdded (inObj:DisplayObject, inIsOnStage:Bool) {
		
		if (inObj == this) {
			
			var evt = new Event (Event.ADDED, true, false);
			evt.target = inObj;
			dispatchEvent (evt);
			
		}
		
		if (inIsOnStage) {
			
			var evt = new Event (Event.ADDED_TO_STAGE, false, false);
			evt.target = inObj;
			dispatchEvent (evt);
			
		}
		
	}
	
	
	/** @private */ private function nmeOnRemoved (inObj:DisplayObject, inWasOnStage:Bool) {
		
		if (inObj == this) {
			
			var evt = new Event (Event.REMOVED, true, false);
			evt.target = inObj;
			dispatchEvent (evt);
			
		}
		
		if (inWasOnStage) {
			
			var evt = new Event (Event.REMOVED_FROM_STAGE, false, false);
			evt.target = inObj;
			dispatchEvent (evt);
			
		}
		
	}
	
	
	/** @private */ public function nmeSetColorTransform (inTrans:ColorTransform) {
		
		nme_display_object_set_color_transform (nmeHandle, inTrans);
		
	}
	
	
	/** @private */ public function nmeSetMatrix (inMatrix:Matrix) {
		
		nme_display_object_set_matrix (nmeHandle, inMatrix);
		
	}
	
	
	/** @private */ public function nmeSetParent (inParent:DisplayObjectContainer) {
		
		if (inParent == nmeParent)
			return inParent;
		
		if (nmeParent != null)
			nmeParent.nmeRemoveChildFromArray (this);
		
		if (nmeParent == null && inParent != null) {
			
			nmeParent = inParent;
			nmeOnAdded (this, (stage != null));
			
		} else if (nmeParent != null && inParent == null) {
			
			var was_on_stage = (stage != null);
			nmeParent = inParent;
			nmeOnRemoved (this, was_on_stage);
			
		} else {
			
			nmeParent = inParent;
			
		}
		
		return inParent;
		
	}
	
	
	public override function toString ():String {
		
		return name;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_alpha ():Float { return nme_display_object_get_alpha (nmeHandle); }
	private function set_alpha (inAlpha:Float):Float {
		
		nme_display_object_set_alpha (nmeHandle, inAlpha);
		return inAlpha;
		
	}
   
	
	private function get_opaqueBackground ():Null<Int> {
		
		var i:Int = nme_display_object_get_bg (nmeHandle);
		if ((i& 0x01000000)==0)
			return null;
		
		return i & 0xffffff;
		
	}
	
	
	private function set_opaqueBackground (inBG:Null<Int>):Null<Int> {
		
		if (inBG == null)
			nme_display_object_set_bg (nmeHandle, 0);
		else
			nme_display_object_set_bg (nmeHandle, inBG);
		
		return inBG;
		
	}
	
	
	private function get_blendMode ():BlendMode {
		
		var i:Int = nme_display_object_get_blend_mode (nmeHandle);
		return Type.createEnumIndex (BlendMode, i);
		
	}
	
	
	private function set_blendMode (inMode:BlendMode):BlendMode {
		
		nme_display_object_set_blend_mode (nmeHandle, Type.enumIndex (inMode));
		return inMode;
		
	}
	
	
	private function get_cacheAsBitmap ():Bool { return nme_display_object_get_cache_as_bitmap (nmeHandle); }
	private function set_cacheAsBitmap (inVal:Bool):Bool {
		
		nme_display_object_set_cache_as_bitmap (nmeHandle, inVal);
		return inVal;
		
	}
	
	private function get_pedanticBitmapCaching ():Bool { return nme_display_object_get_pedantic_bitmap_caching (nmeHandle); }
	private function set_pedanticBitmapCaching (inVal:Bool):Bool {
		
		nme_display_object_set_pedantic_bitmap_caching (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_pixelSnapping ():PixelSnapping {
		
		var val:Int = nme_display_object_get_pixel_snapping (nmeHandle);
		return Type.createEnumIndex (PixelSnapping, val);
		
	}
	
	
	private function set_pixelSnapping (inVal:PixelSnapping):PixelSnapping {
		
		if (inVal == null) {
			
			nme_display_object_set_pixel_snapping(nmeHandle, 0);
			
		} else {
			
			nme_display_object_set_pixel_snapping(nmeHandle, Type.enumIndex(inVal));
			
		}
		
		return inVal;
		
	}
	
	
	private function get_filters ():Array<Dynamic> {
		
		if (nmeFilters == null) return [];
		
		var result = new Array<Dynamic> ();
		
		for (filter in nmeFilters)
			result.push (filter.clone ());
		
		return result;
		
	}
	
	
	private function set_filters (inFilters:Array<Dynamic>):Array<Dynamic> {
		
		if (inFilters == null) {
			
			nmeFilters = null;
			
		} else {
			
			nmeFilters = new Array<Dynamic> ();
			
			for (filter in inFilters)
				nmeFilters.push (filter.clone ());
			
		}
		
		nme_display_object_set_filters (nmeHandle, nmeFilters);
		
		return inFilters;
		
	}
	
	
	private function get_graphics ():Graphics {
		
		if (nmeGraphicsCache == null)
			nmeGraphicsCache = new Graphics (nme_display_object_get_graphics (nmeHandle));
		
		return nmeGraphicsCache;
		
	}
	
	
	private function get_height ():Float { return nme_display_object_get_height (nmeHandle); }
	private function set_height (inVal:Float):Float {
		
		nme_display_object_set_height (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function set_mask (inObject:DisplayObject) {
		
		mask = inObject;
		nme_display_object_set_mask (nmeHandle, inObject == null ? null : inObject.nmeHandle);
		return inObject;
		
	}
	
	
	private function get_mouseX ():Float { return nme_display_object_get_mouse_x (nmeHandle); }
	private function get_mouseY ():Float { return nme_display_object_get_mouse_y (nmeHandle); }
	
	
	private function get_name ():String { return nme_display_object_get_name (nmeHandle); }
	private function set_name (inVal:String):String {
		
		nme_display_object_set_name (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_parent ():DisplayObjectContainer { return nmeParent;	}
	
	
	private function get_rotation ():Float { return nme_display_object_get_rotation (nmeHandle); }
	private function set_rotation (inVal:Float):Float {
		
		nme_display_object_set_rotation (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_scale9Grid ():Rectangle { return (nmeScale9Grid == null) ? null : nmeScale9Grid.clone (); }
	private function set_scale9Grid (inRect:Rectangle):Rectangle {
		
		nmeScale9Grid = (inRect == null) ? null : inRect.clone ();
		nme_display_object_set_scale9_grid (nmeHandle, nmeScale9Grid);
		return inRect;
		
	}
	
	
	private function get_scaleX ():Float { return nme_display_object_get_scale_x (nmeHandle); }
	private function set_scaleX (inVal:Float):Float {
		
		nme_display_object_set_scale_x (nmeHandle, inVal);
		return inVal;
		
	}

	
	private function get_scaleY ():Float { return nme_display_object_get_scale_y (nmeHandle); }
	private function set_scaleY (inVal:Float):Float {
		
		nme_display_object_set_scale_y (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_scrollRect ():Rectangle { return (nmeScrollRect == null) ? null : nmeScrollRect.clone (); }
	private function set_scrollRect (inRect:Rectangle):Rectangle {
		
		nmeScrollRect = (inRect == null) ? null : inRect.clone ();
		nme_display_object_set_scroll_rect (nmeHandle, nmeScrollRect);
		return inRect;
		
	}
	
	
	private function get_stage ():Stage {
		
		if (nmeParent != null)
			return nmeParent.stage;
		
		return null;
		
	}
	
	
	private function get_transform ():Transform { return new Transform (this); }
	private function set_transform (inTransform:Transform):Transform {
		
		nmeSetMatrix (inTransform.matrix);
		nmeSetColorTransform (inTransform.colorTransform);
		return inTransform;
		
	}
	
	
	private function get_visible ():Bool { return nme_display_object_get_visible (nmeHandle);	}
	private function set_visible (inVal:Bool):Bool {
		
		nme_display_object_set_visible (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_width ():Float { return nme_display_object_get_width (nmeHandle); }
	private function set_width (inVal:Float):Float {
		
		nme_display_object_set_width (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_x ():Float { return nme_display_object_get_x (nmeHandle); }
	private function set_x (inVal:Float):Float {
		
		nme_display_object_set_x (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	private function get_y ():Float { return nme_display_object_get_y (nmeHandle); }
	private function set_y (inVal:Float):Float {
		
		nme_display_object_set_y (nmeHandle, inVal);
		return inVal;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_create_display_object = Loader.load ("nme_create_display_object", 0);
	private static var nme_display_object_get_graphics = Loader.load ("nme_display_object_get_graphics", 1);
	private static var nme_display_object_draw_to_surface = Loader.load ("nme_display_object_draw_to_surface", -1);
	private static var nme_display_object_get_id = Loader.load ("nme_display_object_get_id", 1);
	private static var nme_display_object_get_x = Loader.load ("nme_display_object_get_x", 1);
	private static var nme_display_object_set_x = Loader.load ("nme_display_object_set_x", 2);
	private static var nme_display_object_get_y = Loader.load ("nme_display_object_get_y", 1);
	private static var nme_display_object_set_y = Loader.load ("nme_display_object_set_y", 2);
	private static var nme_display_object_get_scale_x = Loader.load ("nme_display_object_get_scale_x", 1);
	private static var nme_display_object_set_scale_x = Loader.load ("nme_display_object_set_scale_x", 2);
	private static var nme_display_object_get_scale_y = Loader.load ("nme_display_object_get_scale_y", 1);
	private static var nme_display_object_set_scale_y = Loader.load ("nme_display_object_set_scale_y", 2);
	private static var nme_display_object_get_mouse_x = Loader.load ("nme_display_object_get_mouse_x", 1);
	private static var nme_display_object_get_mouse_y = Loader.load ("nme_display_object_get_mouse_y", 1);
	private static var nme_display_object_get_rotation = Loader.load ("nme_display_object_get_rotation", 1);
	private static var nme_display_object_set_rotation = Loader.load ("nme_display_object_set_rotation", 2);
	private static var nme_display_object_get_bg = Loader.load ("nme_display_object_get_bg", 1);
	private static var nme_display_object_set_bg = Loader.load ("nme_display_object_set_bg", 2);
	private static var nme_display_object_get_name = Loader.load ("nme_display_object_get_name", 1);
	private static var nme_display_object_set_name = Loader.load ("nme_display_object_set_name", 2);
	private static var nme_display_object_get_width = Loader.load ("nme_display_object_get_width", 1);
	private static var nme_display_object_set_width = Loader.load ("nme_display_object_set_width", 2);
	private static var nme_display_object_get_height = Loader.load ("nme_display_object_get_height", 1);
	private static var nme_display_object_set_height = Loader.load ("nme_display_object_set_height", 2);
	private static var nme_display_object_get_alpha = Loader.load ("nme_display_object_get_alpha", 1);
	private static var nme_display_object_set_alpha = Loader.load ("nme_display_object_set_alpha", 2);
	private static var nme_display_object_get_blend_mode = Loader.load ("nme_display_object_get_blend_mode", 1);
	private static var nme_display_object_set_blend_mode = Loader.load ("nme_display_object_set_blend_mode", 2);
	private static var nme_display_object_get_cache_as_bitmap = Loader.load ("nme_display_object_get_cache_as_bitmap", 1);
	private static var nme_display_object_set_cache_as_bitmap = Loader.load ("nme_display_object_set_cache_as_bitmap", 2);
	private static var nme_display_object_get_pedantic_bitmap_caching = Loader.load ("nme_display_object_get_pedantic_bitmap_caching", 1);
	private static var nme_display_object_set_pedantic_bitmap_caching = Loader.load ("nme_display_object_set_pedantic_bitmap_caching", 2);
	private static var nme_display_object_get_pixel_snapping = Loader.load ("nme_display_object_get_pixel_snapping", 1);
	private static var nme_display_object_set_pixel_snapping = Loader.load ("nme_display_object_set_pixel_snapping", 2);
	private static var nme_display_object_get_visible = Loader.load ("nme_display_object_get_visible", 1);
	private static var nme_display_object_set_visible = Loader.load ("nme_display_object_set_visible", 2);
	private static var nme_display_object_set_filters = Loader.load ("nme_display_object_set_filters", 2);
	private static var nme_display_object_global_to_local = Loader.load ("nme_display_object_global_to_local", 2);
	private static var nme_display_object_local_to_global = Loader.load ("nme_display_object_local_to_global", 2);
	private static var nme_display_object_set_scale9_grid = Loader.load ("nme_display_object_set_scale9_grid", 2);
	private static var nme_display_object_set_scroll_rect = Loader.load ("nme_display_object_set_scroll_rect", 2);
	private static var nme_display_object_set_mask = Loader.load ("nme_display_object_set_mask", 2);
	private static var nme_display_object_set_matrix = Loader.load ("nme_display_object_set_matrix", 2);
	private static var nme_display_object_get_matrix = Loader.load ("nme_display_object_get_matrix", 3);
	private static var nme_display_object_get_color_transform = Loader.load ("nme_display_object_get_color_transform", 3);
	private static var nme_display_object_set_color_transform = Loader.load ("nme_display_object_set_color_transform", 2);
	private static var nme_display_object_get_pixel_bounds = Loader.load ("nme_display_object_get_pixel_bounds", 2);
	private static var nme_display_object_get_bounds = Loader.load ("nme_display_object_get_bounds", 4);
	private static var nme_display_object_hit_test_point = Loader.load ("nme_display_object_hit_test_point", 5);
	
	
}