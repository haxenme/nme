package nme.display;
#if (!flash)

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
import nme.utils.ByteArray;
import nme.PrimeLoader;
import nme.NativeHandle;

@:nativeProperty
class DisplayObject extends EventDispatcher implements IBitmapDrawable 
{
   public var alpha(get, set):Float;
   public var blendMode(get, set):BlendMode;
   public var cacheAsBitmap(get, set):Bool;
   public var pedanticBitmapCaching(get, set):Bool;
   public var pixelSnapping(get, set):PixelSnapping;
   public var filters(get, set):Array<Dynamic>;
   public var graphics(get, null):Graphics;
   public var height(get, set):Float;
   public var hitEnabled(get,set):Bool;
   public var loaderInfo:LoaderInfo;
   public var mask(default, set):DisplayObject;
   public var mouseX(get, null):Float;
   public var mouseY(get, null):Float;
   public var name(get, set):String;
   public var opaqueBackground(get, set):Null <Int>;
   public var parent(get, null):DisplayObjectContainer;
   public var rotation(get, set):Float;
   public var scale9Grid(get, set):Rectangle;
   public var scaleX(get, set):Float;
   public var scaleY(get, set):Float;
   public var scrollRect(get, set):Rectangle;
   public var stage(get, null):Stage;
   public var transform(get, set):Transform;
   public var visible(get, set):Bool;
   public var width(get, set):Float;
   public var x(get, set):Float;
   public var y(get, set):Float;

   /** @private */ public var nmeHandle:NativeHandle;
   /** @private */   private var nmeFilters:Array<Dynamic>;
   /** @private */   private var nmeGraphicsCache:Graphics;
   /** @private */   private var nmeID:Int;
   /** @private */   private var nmeParent:DisplayObjectContainer;
   /** @private */   private var nmeScale9Grid:Rectangle;
   /** @private */   private var nmeScrollRect:Rectangle;
   public function new(inHandle:NativeHandle, inType:String) 
   {
      nmeHandle = inHandle;
      if (nmeParent!=null)
          nme_doc_add_child(nmeParent.nmeHandle, nmeHandle);
      nmeID = nme_display_object_get_id(nmeHandle);

      super(this);
      if (inType!=null)
         this.name = inType + " " + nmeID;
   }

   override public function dispatchEvent(event:Event):Bool 
   {
      var result = nmeDispatchEvent(event);

      if (event.nmeGetIsCancelled())
         return true;

      if (event.bubbles && parent != null) 
      {
         parent.dispatchEvent(event);
      }

      return result;
   }


   private function get_hitEnabled():Bool { return nme_display_object_get_hit_enabled(nmeHandle); }
   private function set_hitEnabled(inVal:Bool):Bool 
   {
      nme_display_object_set_hit_enabled(nmeHandle, inVal);
      return inVal;
   }

   public function getBounds(targetCoordinateSpace:DisplayObject):Rectangle 
   {
      var result = new Rectangle();
      nme_display_object_get_bounds(nmeHandle, targetCoordinateSpace.nmeHandle, result, true);
      return result;
   }

   public function getRect(targetCoordinateSpace:DisplayObject):Rectangle 
   {
      var result = new Rectangle();
      nme_display_object_get_bounds(nmeHandle, targetCoordinateSpace.nmeHandle, result, false);
      return result;
   }

   public function globalToLocal(inGlobal:Point):Point 
   {
      var result = inGlobal.clone();
      nme_display_object_global_to_local(nmeHandle, result);
      return result;
   }

   public function hitTestObject(object:DisplayObject):Bool 
   {
      if (object != null && object.parent != null && parent != null) 
      {
         var currentMatrix = transform.concatenatedMatrix;
         var targetMatrix = object.transform.concatenatedMatrix;

         var xPoint = new Point(1, 0);
         var yPoint = new Point(0, 1);

         var currentWidth = width * currentMatrix.deltaTransformPoint(xPoint).length;
         var currentHeight = height * currentMatrix.deltaTransformPoint(yPoint).length;
         var targetWidth = object.width * targetMatrix.deltaTransformPoint(xPoint).length;
         var targetHeight = object.height * targetMatrix.deltaTransformPoint(yPoint).length;

         var currentRect = new Rectangle(currentMatrix.tx, currentMatrix.ty, currentWidth, currentHeight);
         var targetRect = new Rectangle(targetMatrix.tx, targetMatrix.ty, targetWidth, targetHeight);

         return currentRect.intersects(targetRect);
      }

      return false;
   }

   public function hitTestPoint(x:Float, y:Float, shapeFlag:Bool = false):Bool 
   {
      return nme_display_object_hit_test_point(nmeHandle, x, y, shapeFlag, true);
   }

   public function localToGlobal(inLocal:Point) 
   {
      var result = inLocal.clone();
      nme_display_object_local_to_global(nmeHandle, result);
      return result;
   }

   public function encodeDisplay(inFlags:Int = 0):ByteArray
   {
      return nme_display_object_encode(nmeHandle, inFlags);
   }

   // By default, fresh IDs will be allocated to avoid conflicts in display list
   static inline var DISPLAY_KEEP_ID = 0x0001;
   public static function decodeDisplay(inBytes:ByteArray,inFlags=0) : DisplayObject
   {
      var handle = nme_display_object_decode(inBytes,inFlags);
      // TODO - correct haxe type, with haxe children
      return new DisplayObject(handle,null);
   }

   /** @private */ private function nmeAsInteractiveObject():InteractiveObject {
      return null;
   }

   /** @private */ public function nmeBroadcast(inEvt:Event) {
      nmeDispatchEvent(inEvt);
   }

   /** @private */ public function nmeDispatchEvent(inEvt:Event):Bool {
      if (inEvt.target == null) 
      {
         inEvt.target = this;
      }

      inEvt.currentTarget = this;
      return super.dispatchEvent(inEvt);
   }

   /** @private */ public function nmeDrawToSurface(inSurface:Dynamic, matrix:Matrix, colorTransform:ColorTransform, blendMode:String, clipRect:Rectangle, smoothing:Bool):Void {
      // --- IBitmapDrawable interface ---
      nme_display_object_draw_to_surface(nmeHandle, inSurface, matrix, colorTransform, 0/*blendMode*/, clipRect);
   }

   /** @private */ private function nmeFindByID(inID:Int):DisplayObject {
      if (nmeID == inID)
         return this;
      return null;
   }

   /** @private */ private function nmeFireEvent(inEvt:Event) {
      var stack:Array<InteractiveObject> = [];

      if (nmeParent != null)
         nmeParent.nmeGetInteractiveObjectStack(stack);

      var l = stack.length;

      if (l > 0) 
      {
         // First, the "capture" phase ...
         inEvt.nmeSetPhase(EventPhase.CAPTURING_PHASE);
         stack.reverse();

         for(obj in stack) 
         {
            inEvt.currentTarget = obj;
            obj.nmeDispatchEvent(inEvt);

            if (inEvt.nmeGetIsCancelled())
               return;
         }
      }

      // Next, the "target"
      inEvt.nmeSetPhase(EventPhase.AT_TARGET);
      inEvt.currentTarget = this;
      nmeDispatchEvent(inEvt);

      if (inEvt.nmeGetIsCancelled())
         return;

      // Last, the "bubbles" phase
      if (inEvt.bubbles) 
      {
         inEvt.nmeSetPhase(EventPhase.BUBBLING_PHASE);
         stack.reverse();

         for(obj in stack) 
         {
            inEvt.currentTarget = obj;
            obj.nmeDispatchEvent(inEvt);

            if (inEvt.nmeGetIsCancelled())
               return;
         }
      }
   }

   /** @private */ public function nmeGetColorTransform():ColorTransform {
      var trans = new ColorTransform();
      nme_display_object_get_color_transform(nmeHandle, trans, false);
      return trans;
   }

   /** @private */ public function nmeGetConcatenatedColorTransform():ColorTransform {
      var trans = new ColorTransform();
      nme_display_object_get_color_transform(nmeHandle, trans, true);
      return trans;
   }

   /** @private */ public function nmeGetConcatenatedMatrix():Matrix {
      var mtx = new Matrix();
      nme_display_object_get_matrix(nmeHandle, mtx, true);
      return mtx;
   }

   /** @private */ public function nmeGetInteractiveObjectStack(outStack:Array<InteractiveObject>) {
      var io = nmeAsInteractiveObject();

      if (io != null)
         outStack.push(io);

      if (nmeParent != null)
         nmeParent.nmeGetInteractiveObjectStack(outStack);
   }

   /** @private */ public function nmeGetMatrix():Matrix {
      var mtx = new Matrix();
      nme_display_object_get_matrix(nmeHandle, mtx, false);
      return mtx;
   }

   /** @private */ public function nmeGetObjectsUnderPoint(point:Point, result:Array<DisplayObject>) {
      if (nme_display_object_hit_test_point(nmeHandle, point.x, point.y, true, false))
         result.push(this);
   }

   /** @private */ public function nmeGetPixelBounds():Rectangle {
      var rect = new Rectangle();
      nme_display_object_get_pixel_bounds(nmeHandle, rect);
      return rect;
   }

   /** @private */ private function nmeOnAdded(inObj:DisplayObject, inIsOnStage:Bool) {
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

   /** @private */ private function nmeOnRemoved(inObj:DisplayObject, inWasOnStage:Bool) {
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

   /** @private */ public function nmeSetColorTransform(inTrans:ColorTransform) {
      nme_display_object_set_color_transform(nmeHandle, inTrans);
   }

   /** @private */ public function nmeSetMatrix(inMatrix:Matrix) {
      nme_display_object_set_matrix(nmeHandle, inMatrix);
   }

   /** @private */ public function nmeSetParent(inParent:DisplayObjectContainer) {
      if (inParent == nmeParent)
         return inParent;

      if (nmeParent != null)
         nmeParent.nmeRemoveChildFromArray(this);

      if (nmeHandle==null)
      {
         // Main object being added
         nmeParent = inParent;
      }
      else if (nmeParent == null && inParent != null) 
      {
         nmeParent = inParent;
         nmeOnAdded(this,(stage != null));
      }
      else if (nmeParent != null && inParent == null) 
      {
         var was_on_stage =(stage != null);
         nmeParent = inParent;
         nmeOnRemoved(this, was_on_stage);

      } else 
      {
         nmeParent = inParent;
      }

      return inParent;
   }

   public override function toString():String 
   {
      return name;
   }

   // Getters & Setters
   private function get_alpha():Float { return nme_display_object_get_alpha(nmeHandle); }
   private function set_alpha(inAlpha:Float):Float 
   {
      nme_display_object_set_alpha(nmeHandle, inAlpha);
      return inAlpha;
   }

   private function get_opaqueBackground():Null<Int> 
   {
      var i:Int = nme_display_object_get_bg(nmeHandle);
      if ((i& 0x01000000)==0)
         return null;

      return i & 0xffffff;
   }

   private function set_opaqueBackground(inBG:Null<Int>):Null<Int> 
   {
      if (inBG == null)
         nme_display_object_set_bg(nmeHandle, 0);
      else
         nme_display_object_set_bg(nmeHandle, inBG);

      return inBG;
   }

   private function get_blendMode():BlendMode 
   {
      var i:Int = nme_display_object_get_blend_mode(nmeHandle);
      return Type.createEnumIndex(BlendMode, i);
   }

   private function set_blendMode(inMode:BlendMode):BlendMode 
   {
      nme_display_object_set_blend_mode(nmeHandle, Type.enumIndex(inMode));
      return inMode;
   }

   private function get_cacheAsBitmap():Bool { return nme_display_object_get_cache_as_bitmap(nmeHandle); }
   private function set_cacheAsBitmap(inVal:Bool):Bool 
   {
      nme_display_object_set_cache_as_bitmap(nmeHandle, inVal);
      return inVal;
   }

   private function get_pedanticBitmapCaching():Bool { return nme_display_object_get_pedantic_bitmap_caching(nmeHandle); }
   private function set_pedanticBitmapCaching(inVal:Bool):Bool 
   {
      nme_display_object_set_pedantic_bitmap_caching(nmeHandle, inVal);
      return inVal;
   }

   private function get_pixelSnapping():PixelSnapping 
   {
      var val:Int = nme_display_object_get_pixel_snapping(nmeHandle);
      return Type.createEnumIndex(PixelSnapping, val);
   }

   private function set_pixelSnapping(inVal:PixelSnapping):PixelSnapping 
   {
      if (inVal == null) 
      {
         nme_display_object_set_pixel_snapping(nmeHandle, 0);

      } else 
      {
         nme_display_object_set_pixel_snapping(nmeHandle, Type.enumIndex(inVal));
      }

      return inVal;
   }

   private function get_filters():Array<Dynamic> 
   {
      if (nmeFilters == null) return [];

      var result = new Array<Dynamic>();

      for(filter in nmeFilters)
         result.push(filter.clone());

      return result;
   }

   private function set_filters(inFilters:Array<Dynamic>):Array<Dynamic> 
   {
      if (inFilters == null) 
      {
         nmeFilters = null;

      } else 
      {
         nmeFilters = new Array<Dynamic>();

         for(filter in inFilters)
            nmeFilters.push(filter.clone());
      }

      nme_display_object_set_filters(nmeHandle, nmeFilters);

      return inFilters;
   }

   private function get_graphics():Graphics 
   {
      if (nmeGraphicsCache == null)
         nmeGraphicsCache = new Graphics(nme_display_object_get_graphics(nmeHandle));

      return nmeGraphicsCache;
   }

   private function get_height():Float { return nme_display_object_get_height(nmeHandle); }
   private function set_height(inVal:Float):Float 
   {
      nme_display_object_set_height(nmeHandle, inVal);
      return inVal;
   }

   private function set_mask(inObject:DisplayObject) 
   {
      mask = inObject;
      nme_display_object_set_mask(nmeHandle, inObject == null ? null : inObject.nmeHandle);
      return inObject;
   }

   private function get_mouseX():Float { return nme_display_object_get_mouse_x(nmeHandle); }
   private function get_mouseY():Float { return nme_display_object_get_mouse_y(nmeHandle); }

   private function get_name():String { return nme_display_object_get_name(nmeHandle); }
   private function set_name(inVal:String):String 
   {
      nme_display_object_set_name(nmeHandle, inVal);
      return inVal;
   }

   private function get_parent():DisplayObjectContainer { return nmeParent;   }

   private function get_rotation():Float { return nme_display_object_get_rotation(nmeHandle); }
   private function set_rotation(inVal:Float):Float 
   {
      nme_display_object_set_rotation(nmeHandle, inVal);
      return inVal;
   }

   private function get_scale9Grid():Rectangle { return(nmeScale9Grid == null) ? null : nmeScale9Grid.clone(); }
   private function set_scale9Grid(inRect:Rectangle):Rectangle 
   {
      nmeScale9Grid =(inRect == null) ? null : inRect.clone();
      nme_display_object_set_scale9_grid(nmeHandle, nmeScale9Grid);
      return inRect;
   }

   private function get_scaleX():Float { return nme_display_object_get_scale_x(nmeHandle); }
   private function set_scaleX(inVal:Float):Float 
   {
      nme_display_object_set_scale_x(nmeHandle, inVal);
      return inVal;
   }

   private function get_scaleY():Float { return nme_display_object_get_scale_y(nmeHandle); }
   private function set_scaleY(inVal:Float):Float 
   {
      nme_display_object_set_scale_y(nmeHandle, inVal);
      return inVal;
   }

   private function get_scrollRect():Rectangle { return(nmeScrollRect == null) ? null : nmeScrollRect.clone(); }
   private function set_scrollRect(inRect:Rectangle):Rectangle 
   {
      nmeScrollRect =(inRect == null) ? null : inRect.clone();
      nme_display_object_set_scroll_rect(nmeHandle, nmeScrollRect);
      return inRect;
   }

   private function get_stage():Stage 
   {
      if (nmeParent != null)
         return nmeParent.stage;

      return null;
   }

   private function get_transform():Transform { return new Transform(this); }
   private function set_transform(inTransform:Transform):Transform 
   {
      nmeSetMatrix(inTransform.matrix);
      nmeSetColorTransform(inTransform.colorTransform);
      return inTransform;
   }

   private function get_visible():Bool { return nme_display_object_get_visible(nmeHandle);   }
   private function set_visible(inVal:Bool):Bool 
   {
      nme_display_object_set_visible(nmeHandle, inVal);
      return inVal;
   }

   private function get_width():Float { return nme_display_object_get_width(nmeHandle); }
   private function set_width(inVal:Float):Float 
   {
      nme_display_object_set_width(nmeHandle, inVal);
      return inVal;
   }

   private function get_x():Float { return nme_display_object_get_x(nmeHandle); }
   private function set_x(inVal:Float):Float 
   {
      nme_display_object_set_x(nmeHandle, inVal);
      return inVal;
   }

   private function get_y():Float { return nme_display_object_get_y(nmeHandle); }
   private function set_y(inVal:Float):Float 
   {
      nme_display_object_set_y(nmeHandle, inVal);
      return inVal;
   }


   // Native Methods
   private static var nme_create_display_object = PrimeLoader.load("nme_create_display_object", "o");
   private static var nme_display_object_get_graphics = PrimeLoader.load("nme_display_object_get_graphics", "oo");
   private static var nme_display_object_draw_to_surface = PrimeLoader.load("nme_display_object_draw_to_surface", "ooooiov");
   private static var nme_display_object_get_id = PrimeLoader.load("nme_display_object_get_id", "oi");
   private static var nme_display_object_get_x = PrimeLoader.load("nme_display_object_get_x", "od");
   private static var nme_display_object_set_x = PrimeLoader.load("nme_display_object_set_x", "odv");
   private static var nme_display_object_get_y = PrimeLoader.load("nme_display_object_get_y", "od");
   private static var nme_display_object_set_y = PrimeLoader.load("nme_display_object_set_y", "odv");
   private static var nme_display_object_get_scale_x = PrimeLoader.load("nme_display_object_get_scale_x", "od");
   private static var nme_display_object_set_scale_x = PrimeLoader.load("nme_display_object_set_scale_x", "odv");
   private static var nme_display_object_get_scale_y = PrimeLoader.load("nme_display_object_get_scale_y", "od");
   private static var nme_display_object_set_scale_y = PrimeLoader.load("nme_display_object_set_scale_y", "odv");
   private static var nme_display_object_get_mouse_x = PrimeLoader.load("nme_display_object_get_mouse_x", "od");
   private static var nme_display_object_get_mouse_y = PrimeLoader.load("nme_display_object_get_mouse_y", "od");
   private static var nme_display_object_get_rotation = PrimeLoader.load("nme_display_object_get_rotation", "od");
   private static var nme_display_object_set_rotation = PrimeLoader.load("nme_display_object_set_rotation", "odv");
   private static var nme_display_object_get_bg = PrimeLoader.load("nme_display_object_get_bg", "oi");
   private static var nme_display_object_set_bg = PrimeLoader.load("nme_display_object_set_bg", "oiv");
   //private static var nme_display_object_get_name = PrimeLoader.load("nme_display_object_get_name", "os");
   private static var nme_display_object_get_name = nme.Loader.load("nme_display_object_get_name", 1);
   //private static var nme_display_object_set_name = PrimeLoader.load("nme_display_object_set_name", "osv");
   private static var nme_display_object_set_name = nme.Loader.load("nme_display_object_set_name", 2);
   private static var nme_display_object_get_width = PrimeLoader.load("nme_display_object_get_width", "od");
   private static var nme_display_object_set_width = PrimeLoader.load("nme_display_object_set_width", "odv");
   private static var nme_display_object_get_height = PrimeLoader.load("nme_display_object_get_height", "od");
   private static var nme_display_object_set_height = PrimeLoader.load("nme_display_object_set_height", "odv");
   private static var nme_display_object_get_alpha = PrimeLoader.load("nme_display_object_get_alpha", "od");
   private static var nme_display_object_set_alpha = PrimeLoader.load("nme_display_object_set_alpha", "odv");
   private static var nme_display_object_get_blend_mode = PrimeLoader.load("nme_display_object_get_blend_mode", "oi");
   private static var nme_display_object_set_blend_mode = PrimeLoader.load("nme_display_object_set_blend_mode", "oiv");
   private static var nme_display_object_get_cache_as_bitmap = PrimeLoader.load("nme_display_object_get_cache_as_bitmap", "ob");
   private static var nme_display_object_set_cache_as_bitmap = PrimeLoader.load("nme_display_object_set_cache_as_bitmap", "obv");
   private static var nme_display_object_get_pedantic_bitmap_caching = PrimeLoader.load("nme_display_object_get_pedantic_bitmap_caching", "ob");
   private static var nme_display_object_set_pedantic_bitmap_caching = PrimeLoader.load("nme_display_object_set_pedantic_bitmap_caching", "obv");
   private static var nme_display_object_get_pixel_snapping = PrimeLoader.load("nme_display_object_get_pixel_snapping", "oi");
   private static var nme_display_object_set_pixel_snapping = PrimeLoader.load("nme_display_object_set_pixel_snapping", "oiv");
   private static var nme_display_object_get_visible = PrimeLoader.load("nme_display_object_get_visible", "ob");
   private static var nme_display_object_set_visible = PrimeLoader.load("nme_display_object_set_visible", "obv");
   private static var nme_display_object_set_filters = PrimeLoader.load("nme_display_object_set_filters", "oov");
   private static var nme_display_object_global_to_local = PrimeLoader.load("nme_display_object_global_to_local", "oov");
   private static var nme_display_object_local_to_global = PrimeLoader.load("nme_display_object_local_to_global", "oov");
   private static var nme_display_object_set_scale9_grid = PrimeLoader.load("nme_display_object_set_scale9_grid", "oov");
   private static var nme_display_object_set_scroll_rect = PrimeLoader.load("nme_display_object_set_scroll_rect", "oov");
   private static var nme_display_object_set_mask = PrimeLoader.load("nme_display_object_set_mask", "oov");
   private static var nme_display_object_set_matrix = PrimeLoader.load("nme_display_object_set_matrix", "oov");
   private static var nme_display_object_get_matrix = PrimeLoader.load("nme_display_object_get_matrix", "oobv");
   private static var nme_display_object_get_color_transform = PrimeLoader.load("nme_display_object_get_color_transform", "oobv");
   private static var nme_display_object_set_color_transform = PrimeLoader.load("nme_display_object_set_color_transform", "oov");
   private static var nme_display_object_get_pixel_bounds = PrimeLoader.load("nme_display_object_get_pixel_bounds", "oov");
   private static var nme_display_object_get_bounds = PrimeLoader.load("nme_display_object_get_bounds", "ooobv");
   private static var nme_display_object_hit_test_point = PrimeLoader.load("nme_display_object_hit_test_point", "oddbbb");
   private static var nme_display_object_get_hit_enabled = PrimeLoader.load("nme_display_object_get_hit_enabled", "ob");
   private static var nme_display_object_set_hit_enabled = PrimeLoader.load("nme_display_object_set_hit_enabled", "obv");
   private static var nme_doc_add_child = PrimeLoader.load("nme_doc_add_child", "oov");
   private static var nme_display_object_encode = nme.PrimeLoader.load("nme_display_object_encode", "oio");
   private static var nme_display_object_decode = nme.PrimeLoader.load("nme_display_object_decode", "oio");
}

#else
typedef DisplayObject = flash.display.DisplayObject;
#end
