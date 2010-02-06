package nme.display;
import nme.events.Event;
import nme.events.EventPhase;
import nme.geom.Point;

class DisplayObject extends nme.events.EventDispatcher
{
   public var graphics(nmeGetGraphics,null) : nme.display.Graphics;
   public var stage(nmeGetStage,null) : nme.display.Stage;
   public var x(nmeGetX,nmeSetX): Float;
   public var y(nmeGetY,nmeSetY): Float;

   var nmeHandle:Dynamic;
   var nmeParent:DisplayObjectContainer;
   var nmeName:String;
   var nmeID:Int;

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
      return new nme.display.Graphics( nme_display_object_get_grapics(nmeHandle) );
   }

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

   public function nmeGetX() : Float
   {
      return nme_display_object_get_x(nmeHandle);
   }

   public function nmeSetX(inVal:Float) : Float
   {
      nme_display_object_set_x(nmeHandle,inVal);
      return inVal;
   }

   public function nmeGetY() : Float
   {
      return nme_display_object_get_y(nmeHandle);
   }

   public function nmeSetY(inVal:Float) : Float
   {
      nme_display_object_set_y(nmeHandle,inVal);
      return inVal;
   }




   function nmeOnAdded(inObj:DisplayObject)
   {
      if (inObj==this)
      {
         var evt = new Event(Event.ADDED, true, false);
         evt.target = inObj;
         dispatchEvent(evt);
      }

      var evt = new Event(Event.ADDED_TO_STAGE, false, false);
      evt.target = inObj;
      dispatchEvent(evt);
   }

   function nmeOnRemoved(inObj:DisplayObject)
   {
      if (inObj==this)
      {
         var evt = new Event(Event.REMOVED, true, false);
         evt.target = inObj;
         dispatchEvent(evt);
      }
      var evt = new Event(Event.REMOVED_FROM_STAGE, false, false);
      evt.target = inObj;
      dispatchEvent(evt);
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
         nmeOnAdded(this);
      }
      else if (nmeParent!=null && inParent==null)
      {
         nmeParent = inParent;
         nmeOnRemoved(this);
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




   static var nme_create_display_object = nme.Loader.load("nme_create_display_object",0);
   static var nme_display_object_get_grapics = nme.Loader.load("nme_display_object_get_graphics",1);
   static var nme_display_object_get_id = nme.Loader.load("nme_display_object_get_id",1);
   static var nme_display_object_get_x = nme.Loader.load("nme_display_object_get_x",1);
   static var nme_display_object_set_x = nme.Loader.load("nme_display_object_set_x",2);
   static var nme_display_object_get_y = nme.Loader.load("nme_display_object_get_y",1);
   static var nme_display_object_set_y = nme.Loader.load("nme_display_object_set_y",2);

   static var nme_display_object_global_to_local = nme.Loader.load("nme_display_object_global_to_local",2);
}
