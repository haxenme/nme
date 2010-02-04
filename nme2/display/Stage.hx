package nme2.display;

import nme2.events.MouseEvent;
import nme2.events.Event;
import nme2.geom.Point;

class Stage extends nme2.display.DisplayObjectContainer
{
   var nmeMouseOverObjects:Array<InteractiveObject>;

   public var onKey: Int -> Bool -> Int -> Int ->Void; 
   public var onMouseButton: Int -> Int -> Int -> Bool -> Int ->Void; 
   public var onResize: Int -> Int ->Void; 
   public var onRender: Void ->Void; 
   public var onQuit: Void ->Void; 


   public function new(inHandle:Dynamic)
   {
      super(inHandle);
      nmeMouseOverObjects = [];
      nme_set_stage_handler(nmeHandle,nmeProcessStageEvent);
   }

   override function nmeGetStage() : nme2.display.Stage
   {
      return this;
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
            nmeMouseOverObjects[i].dispatchEvent(rollOver);
            i--;
         }

         nmeMouseOverObjects = inStack;
      }
   }

   function nmeOnMouseMove(inEvent:Dynamic)
   {
      var obj:DisplayObject = nmeFindByID(inEvent.id);
      var stack = new Array<InteractiveObject>();
      obj.nmeGetInteractiveObjectStack(stack);
      if (stack.length>0)
      {
         var obj = stack[0];
         stack.reverse();
         var local = obj.globalToLocal( new Point(inEvent.x, inEvent.y) );
         var move = MouseEvent.nmeCreate(MouseEvent.MOUSE_MOVE,inEvent,local,obj);
         nmeCheckInOuts(move,stack);
         obj.nmeFireEvent(move);
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
      nme2.Manager.pollTimers();
      switch(Std.int(Reflect.field( inEvent, "type" ) ) )
      {
         case 1: // KEY
            if (onKey!=null)
               untyped onKey(inEvent.code, inEvent.down, inEvent.char, inEvent.flags );

         case 2: // MOUSE_MOVE
            nmeOnMouseMove(inEvent);

         case 3: // MOUSE_BUTTON
            if (onMouseButton!=null)
               onMouseButton(inEvent.button, inEvent.x, inEvent.y, inEvent.down, inEvent.flags);
         case 4: // RESIZE
            if (onResize!=null)
               untyped onResize(inEvent.x, inEvent.y);
            nme_render_stage(nmeHandle);

         case 5: // RENDER
            nmeRender(true);

         case 6: // QUIT
            if (onQuit!=null)
               untyped onQuit();

         // TODO: user, sys_wm, sound_finished
      }

      return null;
   }

   static var nme_set_stage_handler = nme2.Loader.load("nme_set_stage_handler",2);
   static var nme_render_stage = nme2.Loader.load("nme_render_stage",1);
}
