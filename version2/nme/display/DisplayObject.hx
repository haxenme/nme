package nme.display;
import nme.events.Event;
import nme.events.EventPhase;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.filters.BitmapFilter;

class DisplayObject extends nme.events.EventDispatcher, implements IBitmapDrawable
{
   public var graphics(nmeGetGraphics,null) : nme.display.Graphics;
   public var stage(nmeGetStage,null) : nme.display.Stage;
   public var opaqueBackground(nmeGetBG,nmeSetBG) : Null<Int>;
   public var x(nmeGetX,nmeSetX): Float;
   public var y(nmeGetY,nmeSetY): Float;
   public var scaleX(nmeGetScaleX,nmeSetScaleX): Float;
   public var scaleY(nmeGetScaleY,nmeSetScaleY): Float;
   public var rotation(nmeGetRotation,nmeSetRotation): Float;
   public var width(nmeGetWidth,nmeSetWidth): Float;
   public var height(nmeGetHeight,nmeSetHeight): Float;
   public var cacheAsBitmap(nmeGetCacheAsBitmap,nmeSetCacheAsBitmap): Bool;
   public var visible(nmeGetVisible,nmeSetVisible): Bool;
   public var filters(nmeGetFilters,nmeSetFilters): Array<BitmapFilter>;
   public var parent(nmeGetParent,null): DisplayObjectContainer;
   public var scale9Grid(nmeGetScale9Grid,nmeSetScale9Grid): Rectangle;

   var nmeHandle:Dynamic;
   var nmeGraphicsCache:Graphics;
   var nmeParent:DisplayObjectContainer;
   var nmeName:String;
   var nmeFilters:Array<BitmapFilter>;
   var nmeID:Int;
   var nmeScale9Grid:Rectangle;

   public function new(inHandle:Dynamic)
   {
      super(this);
      nmeParent = null;
      nmeHandle = inHandle;
      nmeName = "DisplayObject";
      nmeID = nme_display_object_get_id(nmeHandle);
   }
   public function toString() : String { return nmeName + " " + nmeID; }

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

	function nmeSetFilters(inFilters:Array<BitmapFilter>) : Array<BitmapFilter>
	{
	   if (inFilters==null)
			nmeFilters = null;
		else
		{
			nmeFilters = new Array<BitmapFilter>();
			for(filter in inFilters)
				nmeFilters.push(filter.clone());
		}
		nme_display_object_set_filters(nmeHandle,nmeFilters);
		return inFilters;
	}

	function nmeGetFilters() : Array<BitmapFilter>
	{
	   if (nmeFilters==null) return [];
		var result = new Array<BitmapFilter>();
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
         return;

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
   }

   public function globalToLocal(inLocal:Point)
   {
      var result = inLocal.clone();
      nme_display_object_global_to_local(nmeHandle,result);
      return result;
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
      // TODO:
   }




   static var nme_create_display_object = nme.Loader.load("nme_create_display_object",0);
   static var nme_display_object_get_grapics = nme.Loader.load("nme_display_object_get_graphics",1);
   static var nme_display_object_get_id = nme.Loader.load("nme_display_object_get_id",1);
   static var nme_display_object_get_x = nme.Loader.load("nme_display_object_get_x",1);
   static var nme_display_object_set_x = nme.Loader.load("nme_display_object_set_x",2);
   static var nme_display_object_get_y = nme.Loader.load("nme_display_object_get_y",1);
   static var nme_display_object_set_y = nme.Loader.load("nme_display_object_set_y",2);
   static var nme_display_object_get_scale_x = nme.Loader.load("nme_display_object_get_scale_x",1);
   static var nme_display_object_set_scale_x = nme.Loader.load("nme_display_object_set_scale_x",2);
   static var nme_display_object_get_scale_y = nme.Loader.load("nme_display_object_get_scale_y",1);
   static var nme_display_object_set_scale_y = nme.Loader.load("nme_display_object_set_scale_y",2);
   static var nme_display_object_get_rotation = nme.Loader.load("nme_display_object_get_rotation",1);
   static var nme_display_object_set_rotation = nme.Loader.load("nme_display_object_set_rotation",2);
   static var nme_display_object_get_bg = nme.Loader.load("nme_display_object_get_bg",1);
   static var nme_display_object_set_bg = nme.Loader.load("nme_display_object_set_bg",2);
   static var nme_display_object_get_width = nme.Loader.load("nme_display_object_get_width",1);
   static var nme_display_object_set_width = nme.Loader.load("nme_display_object_set_width",2);
   static var nme_display_object_get_height = nme.Loader.load("nme_display_object_get_height",1);
   static var nme_display_object_set_height = nme.Loader.load("nme_display_object_set_height",2);
   static var nme_display_object_get_cache_as_bitmap = nme.Loader.load("nme_display_object_get_cache_as_bitmap",1);
   static var nme_display_object_set_cache_as_bitmap = nme.Loader.load("nme_display_object_set_cache_as_bitmap",2);
   static var nme_display_object_get_visible = nme.Loader.load("nme_display_object_get_visible",1);
   static var nme_display_object_set_visible = nme.Loader.load("nme_display_object_set_visible",2);
   static var nme_display_object_set_filters = nme.Loader.load("nme_display_object_set_filters",2);

   static var nme_display_object_global_to_local = nme.Loader.load("nme_display_object_global_to_local",2);
   static var nme_display_object_set_scale9_grid = nme.Loader.load("nme_display_object_set_scale9_grid",2);
}
