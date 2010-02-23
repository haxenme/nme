package nme.display;

import nme.events.MouseEvent;
import nme.events.Event;
import nme.geom.Point;

class Stage extends nme.display.DisplayObjectContainer
{
   var nmeMouseOverObjects:Array<InteractiveObject>;
   var focus(nmeGetFocus,nmeSetFocus):InteractiveObject;

   public var frameRate(default,nmeSetFrameRate): Float;

   public var onKey: Int -> Bool -> Int -> Int ->Void; 
   public var onResize: Int -> Int ->Void; 
   public var onQuit: Void ->Void; 


   public function new(inHandle:Dynamic)
   {
      super(inHandle);
      nmeMouseOverObjects = [];
      nme_set_stage_handler(nmeHandle,nmeProcessStageEvent);
      nmeSetFrameRate(100);
   }

   public override function nmeGetStage() : nme.display.Stage
   {
      return this;
   }

   function nmeSetFrameRate(inRate:Float) : Float
   {
      frameRate = inRate;
      nme_set_stage_poll_method( nmeHandle, inRate<=0 ? 0 : (inRate<24 ? 1 : 2) );
      return inRate;
   }

   function nmeGetFocus() : InteractiveObject
   {
      var id = nme_stage_get_focus_id(nmeHandle);
      var obj:DisplayObject = nmeFindByID(id);
      return cast obj;
   }

   function nmeSetFocus(inObject:InteractiveObject) : InteractiveObject
   {
      if (inObject==null)
         nme_stage_set_focus(nmeHandle,null,0);
      else
         nme_stage_set_focus(nmeHandle,inObject.nmeHandle,0);
      return inObject;
   }


   function nmeCheckInOuts(inEvent:MouseEvent,inStack:Array<InteractiveObject>)
   {
      // Exit ...
      var new_n = inStack.length;
      var new_obj:InteractiveObject = new_n>0 ? inStack[new_n-1] : null;
      var old_n = nmeMouseOverObjects.length;
      var old_obj:InteractiveObject = old_n>0 ? inStack[old_n-1] : null;
      if (new_obj!=old_obj)
      {
         // mouseOut/MouseOver goes up the object tree...
         if (old_obj!=null)
            old_obj.nmeFireEvent( inEvent.nmeCreateSimilar(MouseEvent.MOUSE_OUT,new_obj,old_obj) );

         if (new_obj!=null)
            new_obj.nmeFireEvent( inEvent.nmeCreateSimilar(MouseEvent.MOUSE_OVER,old_obj) );

         // rollOver/rollOut goes only over the non-common objects in the tree...
         var common = 0;
         while(common<new_n && common<old_n && inStack[common] == nmeMouseOverObjects[common] )
            common++;

         var rollOut = inEvent.nmeCreateSimilar(MouseEvent.ROLL_OUT,new_obj,old_obj);
         var i = old_n-1;
         while(i>common)
         {
            nmeMouseOverObjects[i].dispatchEvent(rollOut);
            i--;
         }

         var rollOver = inEvent.nmeCreateSimilar(MouseEvent.ROLL_OVER,old_obj);
         var i = new_n-1;
         while(i>common)
         {
            inStack[i].dispatchEvent(rollOver);
            i--;
         }

         nmeMouseOverObjects = inStack;
      }
   }

   function nmeOnMouse(inEvent:Dynamic,inType:String)
   {
      var obj:DisplayObject = nmeFindByID(inEvent.id);
      var stack = new Array<InteractiveObject>();
      obj.nmeGetInteractiveObjectStack(stack);
      if (stack.length>0)
      {
         var obj = stack[0];
         stack.reverse();
         var local = obj.globalToLocal( new Point(inEvent.x, inEvent.y) );
         var evt = MouseEvent.nmeCreate(inType,inEvent,local,obj);
         nmeCheckInOuts(evt,stack);
         obj.nmeFireEvent(evt);
      }
   }

   function nmeRender(inSendEnterFrame:Bool)
   {
      if (inSendEnterFrame)
      {
         nmeBroadcast(new Event(Event.ENTER_FRAME));
      }
      nme_render_stage(nmeHandle);
   }


   function nmeProcessStageEvent(inEvent:Dynamic) : Dynamic
   {
      //trace(inEvent);
      // TODO: timer event?
      nme.Lib.pollTimers();
      switch(Std.int(Reflect.field( inEvent, "type" ) ) )
      {
         case 2: // etChar
            if (onKey!=null)
               untyped onKey(inEvent.code, inEvent.down, inEvent.char, inEvent.flags );

         case 4: // etMouseMove
            nmeOnMouse(inEvent,MouseEvent.MOUSE_MOVE);

         case 5: // etMouseDown
            nmeOnMouse(inEvent,MouseEvent.MOUSE_DOWN);

         case 6: // etMouseClick
            nmeOnMouse(inEvent,MouseEvent.CLICK);

         case 7: // etMouseUp
            nmeOnMouse(inEvent,MouseEvent.MOUSE_UP);

         case 8: // etResize
            if (onResize!=null)
               untyped onResize(inEvent.x, inEvent.y);
            nmeRender(false);

         case 9: // etPoll
            nmeRender(true);

         case 10: // etQuit
            if (onQuit!=null)
               untyped onQuit();

         // TODO: user, sys_wm, sound_finished
      }

      return null;
   }

   static var nme_set_stage_handler = nme.Loader.load("nme_set_stage_handler",2);
   static var nme_set_stage_poll_method = nme.Loader.load("nme_set_stage_poll_method",2);
   static var nme_render_stage = nme.Loader.load("nme_render_stage",1);
   static var nme_stage_get_focus_id = nme.Loader.load("nme_stage_get_focus_id",1);
   static var nme_stage_set_focus = nme.Loader.load("nme_stage_set_focus",3);
}
