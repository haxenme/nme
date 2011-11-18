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


class DisplayObject extends EventDispatcher, implements IBitmapDrawable
{
   public var graphics(nmeGetGraphics,null) : nme.display.Graphics;
   public var stage(nmeGetStage,null) : nme.display.Stage;
   public var opaqueBackground(nmeGetBG,nmeSetBG) : Null<Int>;
   public var x(nmeGetX,nmeSetX): Float;
   public var y(nmeGetY,nmeSetY): Float;
   public var scaleX(nmeGetScaleX,nmeSetScaleX): Float;
   public var scaleY(nmeGetScaleY,nmeSetScaleY): Float;
   public var mouseX(nmeGetMouseX,null): Float;
   public var mouseY(nmeGetMouseY,null): Float;
   public var rotation(nmeGetRotation,nmeSetRotation): Float;
   public var width(nmeGetWidth,nmeSetWidth): Float;
   public var height(nmeGetHeight,nmeSetHeight): Float;
   public var cacheAsBitmap(nmeGetCacheAsBitmap,nmeSetCacheAsBitmap): Bool;
   public var visible(nmeGetVisible,nmeSetVisible): Bool;
   public var filters(nmeGetFilters,nmeSetFilters): Array<Dynamic>;
   public var parent(nmeGetParent,null): DisplayObjectContainer;
   public var scale9Grid(nmeGetScale9Grid,nmeSetScale9Grid): Rectangle;
   public var scrollRect(nmeGetScrollRect,nmeSetScrollRect): Rectangle;
   public var name(nmeGetName,nmeSetName): String;
   public var mask(default,nmeSetMask): DisplayObject;
   public var transform(nmeGetTransform,nmeSetTransform): Transform;
   public var alpha(nmeGetAlpha,nmeSetAlpha): Float;
   public var blendMode(nmeGetBlendMode,nmeSetBlendMode): BlendMode;

   public var nmeHandle:Dynamic;
   var nmeGraphicsCache:Graphics;
   var nmeParent:DisplayObjectContainer;
   var nmeFilters:Array<Dynamic>;
   var nmeID:Int;
   var nmeScale9Grid:Rectangle;
   var nmeScrollRect:Rectangle;

   public function new(inHandle:Dynamic,inType:String)
   {
      super(this);
      nmeParent = null;
      nmeHandle = inHandle;
      nmeID = nme_display_object_get_id(nmeHandle);
      nmeSetName(inType + " " + nmeID);
   }
   override public function toString() : String { return name; }

   public function nmeGetGraphics() : nme.display.Graphics
   {
      if (nmeGraphicsCache==null)
         nmeGraphicsCache = new nme.display.Graphics( nme_display_object_get_grapics(nmeHandle) );
      return nmeGraphicsCache;
   }

   function nmeGetParent() : DisplayObjectContainer { return nmeParent; }

   public function nmeGetStage() : nme.display.Stage
   {
      if (nmeParent!=null)
         return nmeParent.nmeGetStage();
      return null;
   }

   function nmeFindByID(inID:Int) : DisplayObject
   {
      if (nmeID==inID)
         return this;
      return null;
   }

   function nmeGetX() : Float { return nme_display_object_get_x(nmeHandle); }
   function nmeSetX(inVal:Float) : Float
   {
      nme_display_object_set_x(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetY() : Float { return nme_display_object_get_y(nmeHandle); }
   function nmeSetY(inVal:Float) : Float
   {
      nme_display_object_set_y(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetScaleX() : Float { return nme_display_object_get_scale_x(nmeHandle); }
   function nmeSetScaleX(inVal:Float) : Float
   {
      nme_display_object_set_scale_x(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetScaleY() : Float { return nme_display_object_get_scale_y(nmeHandle); }
   function nmeSetScaleY(inVal:Float) : Float
   {
      nme_display_object_set_scale_y(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetMouseX() : Float { return nme_display_object_get_mouse_x(nmeHandle); }
   function nmeGetMouseY() : Float { return nme_display_object_get_mouse_y(nmeHandle); }

   function nmeGetRotation() : Float { return nme_display_object_get_rotation(nmeHandle); }
   function nmeSetRotation(inVal:Float) : Float
   {
      nme_display_object_set_rotation(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetCacheAsBitmap() : Bool { return nme_display_object_get_cache_as_bitmap(nmeHandle); }
   function nmeSetCacheAsBitmap(inVal:Bool) : Bool
   {
      nme_display_object_set_cache_as_bitmap(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetVisible() : Bool { return nme_display_object_get_visible(nmeHandle); }
   function nmeSetVisible(inVal:Bool) : Bool
   {
      nme_display_object_set_visible(nmeHandle,inVal);
      return inVal;
   }


   function nmeGetWidth() : Float { return nme_display_object_get_width(nmeHandle); }
   function nmeSetWidth(inVal:Float) : Float
   {
      nme_display_object_set_width(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetHeight() : Float { return nme_display_object_get_height(nmeHandle); }
   function nmeSetHeight(inVal:Float) : Float
   {
      nme_display_object_set_height(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetName() : String { return nme_display_object_get_name(nmeHandle); }
   function nmeSetName(inVal:String) : String
   {
      nme_display_object_set_name(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetBlendMode() : BlendMode
   {
      var i:Int = nme_display_object_get_blend_mode(nmeHandle);
      return Type.createEnumIndex( BlendMode, i );
   }
   function nmeSetBlendMode(inMode:BlendMode) : BlendMode
   {
      nme_display_object_set_blend_mode(nmeHandle, Type.enumIndex(inMode) );
      return inMode;
   }

   function nmeGetScale9Grid() : Rectangle
   {
      return (nmeScale9Grid==null) ? null : nmeScale9Grid.clone();
   }

   function nmeSetScale9Grid(inRect:Rectangle) : Rectangle
   {
      nmeScale9Grid = (inRect==null) ? null : inRect.clone();
      nme_display_object_set_scale9_grid(nmeHandle,nmeScale9Grid);
      return inRect;
   }

   function nmeGetScrollRect() : Rectangle
   {
      return (nmeScrollRect==null) ? null : nmeScrollRect.clone();
   }

   function nmeSetScrollRect(inRect:Rectangle) : Rectangle
   {
      nmeScrollRect = (inRect==null) ? null : inRect.clone();
      nme_display_object_set_scroll_rect(nmeHandle,nmeScrollRect);
      return inRect;
   }

   function nmeSetMask(inObject:DisplayObject)
   {
      mask = inObject;
      nme_display_object_set_mask(nmeHandle, inObject==null ? null : inObject.nmeHandle );
      return inObject;
   }

   function nmeSetBG(inBG:Null<Int>) : Null<Int>
   {
      if (inBG==null)
         nme_display_object_set_bg(nmeHandle,0);
      else
         nme_display_object_set_bg(nmeHandle,inBG);
      return inBG;
   }

   function nmeGetBG() : Null<Int>
   {
      var i:Int = nme_display_object_get_bg(nmeHandle);
      if ((i& 0x01000000)==0)
         return null;
      return i & 0xffffff;
   }

   function nmeSetFilters(inFilters:Array<Dynamic>) : Array<Dynamic>
   {
      if (inFilters==null)
         nmeFilters = null;
      else
      {
         nmeFilters = new Array<Dynamic>();
         for(filter in inFilters)
            nmeFilters.push(filter.clone());
      }
      nme_display_object_set_filters(nmeHandle,nmeFilters);
      return inFilters;
   }

   function nmeGetFilters() : Array<Dynamic>
   {
      if (nmeFilters==null) return [];
      var result = new Array<Dynamic>();
      for(filter in nmeFilters)
         result.push(filter.clone());
      return result;
   }

   function nmeOnAdded(inObj:DisplayObject,inIsOnStage:Bool)
   {
      if (inObj==this)
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

   function nmeOnRemoved(inObj:DisplayObject,inWasOnStage:Bool)
   {
      if (inObj==this)
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

   public function nmeSetParent(inParent:DisplayObjectContainer)
   {
      if (inParent == nmeParent)
         return inParent;

      if (nmeParent != null)
         nmeParent.nmeRemoveChildFromArray(this);

      if (nmeParent==null && inParent!=null)
      {
         nmeParent = inParent;
         nmeOnAdded(this,stage!=null);
      }
      else if (nmeParent!=null && inParent==null)
      {
         var was_on_stage = stage!=null;
         nmeParent = inParent;
         nmeOnRemoved(this,was_on_stage);
      }
      else
         nmeParent = inParent;

      return inParent;
   }


   public function nmeGetMatrix() : Matrix
   {
      var mtx = new Matrix();
      nme_display_object_get_matrix(nmeHandle,mtx,false);
      return mtx;
   }
   public function nmeGetConcatenatedMatrix() : Matrix
   {
      var mtx = new Matrix();
      nme_display_object_get_matrix(nmeHandle,mtx,true);
      return mtx;
   }
   public function nmeSetMatrix(inMatrix:Matrix)
   {
      nme_display_object_set_matrix(nmeHandle,inMatrix);
   }

   public function nmeGetColorTransform() : ColorTransform
   { 
      var trans = new ColorTransform();
      nme_display_object_get_color_transform(nmeHandle,trans,false);
      return trans;
   }
   public function nmeGetConcatenatedColorTransform() : ColorTransform
   { 
      var trans = new ColorTransform();
      nme_display_object_get_color_transform(nmeHandle,trans,true);
      return trans;
   }

   public function nmeSetColorTransform( inTrans : ColorTransform )
   {
      nme_display_object_set_color_transform(nmeHandle,inTrans);
   }

   public function nmeGetPixelBounds() : Rectangle
   { 
      var rect = new Rectangle();
      nme_display_object_get_pixel_bounds(nmeHandle,rect);
      return rect;
   }
   function nmeGetTransform() : Transform
   {
      return new Transform(this);
   }
   function nmeSetTransform(inTransform : Transform) : Transform
   {
      nmeSetMatrix(inTransform.matrix);
      nmeSetColorTransform(inTransform.colorTransform);
      return inTransform;
   }
   function nmeGetAlpha() : Float
   {
      return nme_display_object_get_alpha(nmeHandle);
   }
   function nmeSetAlpha(inAlpha:Float) : Float
   {
      nme_display_object_set_alpha(nmeHandle,inAlpha);
      return inAlpha;
   }

   public function globalToLocal(inGlobal:Point)
   {
      var result = inGlobal.clone();
      nme_display_object_global_to_local(nmeHandle,result);
      return result;
   }

   public function localToGlobal(inLocal:Point)
   {
      var result = inLocal.clone();
      nme_display_object_local_to_global(nmeHandle,result);
      return result;
   }



	public function hitTestPoint(x:Float, y:Float, shapeFlag:Bool = false):Bool
	{
		return nme_display_object_hit_test_point(nmeHandle,x,y,shapeFlag,true);
	}


	public function nmeGetObjectsUnderPoint(point:Point,result:Array<DisplayObject>)
	{
		if (nme_display_object_hit_test_point(nmeHandle,point.x,point.y,true,false))
			result.push(this);
	}


   // Events

   function nmeAsInteractiveObject() : InteractiveObject { return null; }

   public function nmeGetInteractiveObjectStack(outStack:Array<InteractiveObject>)
   {
      var io = nmeAsInteractiveObject();
      if (io!=null)
         outStack.push(io);
      if (nmeParent!=null)
         nmeParent.nmeGetInteractiveObjectStack(outStack);
   }

   public function nmeBroadcast(inEvt:Event)
   {
      dispatchEvent(inEvt);
   }

   function nmeFireEvent(inEvt:Event)
   {
      var stack:Array<InteractiveObject> = [];
      if (nmeParent!=null)
         nmeParent.nmeGetInteractiveObjectStack(stack);
      var l = stack.length;

      if (l>0)
      {
         // First, the "capture" phase ...
         inEvt.nmeSetPhase(EventPhase.CAPTURING_PHASE);
         stack.reverse();
         for(obj in stack)
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
         for(obj in stack)
         {
            inEvt.currentTarget = obj;
            obj.dispatchEvent(inEvt);
            if (inEvt.nmeGetIsCancelled())
               return;
         }
      }
   }

   // --- IBitmapDrawable interface ---
   public function nmeDrawToSurface(inSurface : Dynamic,
               matrix:nme.geom.Matrix,
               colorTransform:nme.geom.ColorTransform,
               blendMode:String,
               clipRect:nme.geom.Rectangle,
               smoothing:Bool):Void
   {
      nme_display_object_draw_to_surface(nmeHandle, inSurface, matrix,
         colorTransform, blendMode, clipRect );
   }



   static var nme_create_display_object = nme.Loader.load("nme_create_display_object",0);
   static var nme_display_object_get_grapics = nme.Loader.load("nme_display_object_get_graphics",1);
   static var nme_display_object_draw_to_surface = nme.Loader.load("nme_display_object_draw_to_surface",-1);
   static var nme_display_object_get_id = nme.Loader.load("nme_display_object_get_id",1);
   static var nme_display_object_get_x = nme.Loader.load("nme_display_object_get_x",1);
   static var nme_display_object_set_x = nme.Loader.load("nme_display_object_set_x",2);
   static var nme_display_object_get_y = nme.Loader.load("nme_display_object_get_y",1);
   static var nme_display_object_set_y = nme.Loader.load("nme_display_object_set_y",2);
   static var nme_display_object_get_scale_x = nme.Loader.load("nme_display_object_get_scale_x",1);
   static var nme_display_object_set_scale_x = nme.Loader.load("nme_display_object_set_scale_x",2);
   static var nme_display_object_get_scale_y = nme.Loader.load("nme_display_object_get_scale_y",1);
   static var nme_display_object_set_scale_y = nme.Loader.load("nme_display_object_set_scale_y",2);
   static var nme_display_object_get_mouse_x = nme.Loader.load("nme_display_object_get_mouse_x",1);
   static var nme_display_object_get_mouse_y = nme.Loader.load("nme_display_object_get_mouse_y",1);
   static var nme_display_object_get_rotation = nme.Loader.load("nme_display_object_get_rotation",1);
   static var nme_display_object_set_rotation = nme.Loader.load("nme_display_object_set_rotation",2);
   static var nme_display_object_get_bg = nme.Loader.load("nme_display_object_get_bg",1);
   static var nme_display_object_set_bg = nme.Loader.load("nme_display_object_set_bg",2);
   static var nme_display_object_get_name = nme.Loader.load("nme_display_object_get_name",1);
   static var nme_display_object_set_name = nme.Loader.load("nme_display_object_set_name",2);
   static var nme_display_object_get_width = nme.Loader.load("nme_display_object_get_width",1);
   static var nme_display_object_set_width = nme.Loader.load("nme_display_object_set_width",2);
   static var nme_display_object_get_height = nme.Loader.load("nme_display_object_get_height",1);
   static var nme_display_object_set_height = nme.Loader.load("nme_display_object_set_height",2);
   static var nme_display_object_get_alpha = nme.Loader.load("nme_display_object_get_alpha",1);
   static var nme_display_object_set_alpha = nme.Loader.load("nme_display_object_set_alpha",2);
   static var nme_display_object_get_blend_mode = nme.Loader.load("nme_display_object_get_blend_mode",1);
   static var nme_display_object_set_blend_mode = nme.Loader.load("nme_display_object_set_blend_mode",2);
   static var nme_display_object_get_cache_as_bitmap = nme.Loader.load("nme_display_object_get_cache_as_bitmap",1);
   static var nme_display_object_set_cache_as_bitmap = nme.Loader.load("nme_display_object_set_cache_as_bitmap",2);
   static var nme_display_object_get_visible = nme.Loader.load("nme_display_object_get_visible",1);
   static var nme_display_object_set_visible = nme.Loader.load("nme_display_object_set_visible",2);
   static var nme_display_object_set_filters = nme.Loader.load("nme_display_object_set_filters",2);

   static var nme_display_object_global_to_local = nme.Loader.load("nme_display_object_global_to_local",2);
   static var nme_display_object_local_to_global = nme.Loader.load("nme_display_object_local_to_global",2);
   static var nme_display_object_set_scale9_grid = nme.Loader.load("nme_display_object_set_scale9_grid",2);
   static var nme_display_object_set_scroll_rect = nme.Loader.load("nme_display_object_set_scroll_rect",2);
   static var nme_display_object_set_mask = nme.Loader.load("nme_display_object_set_mask",2);

   static var nme_display_object_set_matrix = nme.Loader.load("nme_display_object_set_matrix",2);
   static var nme_display_object_get_matrix = nme.Loader.load("nme_display_object_get_matrix",3);
   static var nme_display_object_get_color_transform = nme.Loader.load("nme_display_object_get_color_transform",3);
   static var nme_display_object_set_color_transform = nme.Loader.load("nme_display_object_set_color_transform",2);
   static var nme_display_object_get_pixel_bounds = nme.Loader.load("nme_display_object_get_pixel_bounds",2);
   static var nme_display_object_hit_test_point = nme.Loader.load("nme_display_object_hit_test_point",5);


}


#else
typedef DisplayObject = flash.display.DisplayObject;
#end