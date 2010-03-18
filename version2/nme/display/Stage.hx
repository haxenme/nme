package nme.display;

import nme.events.MouseEvent;
import nme.events.FocusEvent;
import nme.events.KeyboardEvent;
import nme.events.Event;
import nme.geom.Point;

class Stage extends nme.display.DisplayObjectContainer
{
   var nmeMouseOverObjects:Array<InteractiveObject>;
   var nmeFocusOverObjects:Array<InteractiveObject>;
   var focus(nmeGetFocus,nmeSetFocus):InteractiveObject;
   public var stageFocusRect(nmeGetStageFocusRect,nmeSetStageFocusRect):Bool;

   public var frameRate(default,nmeSetFrameRate): Float;

   public var onKey: Int -> Bool -> Int -> Int ->Void; 
   public var onResize: Int -> Int ->Void; 
   public var onQuit: Void ->Void; 


   public function new(inHandle:Dynamic)
   {
      super(inHandle);
      nmeMouseOverObjects = [];
      nmeFocusOverObjects = [];
      nme_set_stage_handler(nmeHandle,nmeProcessStageEvent);
      nmeSetFrameRate(100);
   }

   public override function nmeGetStage() : nme.display.Stage
   {
      return this;
   }

   public static var OrientationPortrait = 1;
   public static var OrientationPortraitUpsideDown = 2;
   public static var OrientationLandscapeLeft = 3;
   public static var OrientationLandscapeRight = 4;
   public static var OrientationFaceUp = 5;
   public static var OrientationFaceDown = 6;

   public static dynamic function shouldRotateInterface(inOrientation:Int) : Bool
   {
      return inOrientation==OrientationPortrait;
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

   function nmeGetStageFocusRect() : Bool { return nme_stage_get_focus_rect(nmeHandle); }
   function nmeSetStageFocusRect(inVal:Bool) : Bool {
      nme_stage_set_focus_rect(nmeHandle,inVal);
      return inVal;
   }


   function nmeCheckInOuts(inEvent:MouseEvent,inStack:Array<InteractiveObject>)
   {
      // Exit ...
      var new_n = inStack.length;
      var new_obj:InteractiveObject = new_n>0 ? inStack[new_n-1] : null;
      var old_n = nmeMouseOverObjects.length;
      var old_obj:InteractiveObject = old_n>0 ? nmeMouseOverObjects[old_n-1] : null;
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
         while(i>=common)
         {
            nmeMouseOverObjects[i].dispatchEvent(rollOut);
            i--;
         }

         var rollOver = inEvent.nmeCreateSimilar(MouseEvent.ROLL_OVER,old_obj);
         var i = new_n-1;
         while(i>=common)
         {
            inStack[i].dispatchEvent(rollOver);
            i--;
         }

         nmeMouseOverObjects = inStack;
      }
   }

   function nmeOnMouse(inEvent:Dynamic,inType:String)
   {
      var stack = new Array<InteractiveObject>();
      var obj:DisplayObject = nmeFindByID(inEvent.id);
      if (obj!=null)
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
      else
      {
         var evt = MouseEvent.nmeCreate(inType,inEvent, new Point(inEvent.x,inEvent.y),null);
         nmeCheckInOuts(evt,stack);
      }
   }


  function nmeCheckFocusInOuts(inEvent:Dynamic,inStack:Array<InteractiveObject>)
  {

      // Exit ...
      var new_n = inStack.length;
      var new_obj:InteractiveObject = new_n>0 ? inStack[new_n-1] : null;
      var old_n = nmeFocusOverObjects.length;
      var old_obj:InteractiveObject = old_n>0 ? nmeFocusOverObjects[old_n-1] : null;

      if (new_obj!=old_obj)
      {
         // focusOver/focusOut goes only over the non-common objects in the tree...
         var common = 0;
         while(common<new_n && common<old_n && inStack[common] == nmeFocusOverObjects[common] )
            common++;

         var focusOut = new FocusEvent( FocusEvent.FOCUS_OUT, false, false,
               new_obj,
               inEvent.flags>0,
               inEvent.code );

         var i = old_n-1;
         while(i>=common)
         {
            nmeFocusOverObjects[i].dispatchEvent(focusOut);
            i--;
         }

         var focusIn = new FocusEvent( FocusEvent.FOCUS_IN, false, false,
               old_obj,
               inEvent.flags>0,
               inEvent.code );
         var i = new_n-1;
         while(i>=common)
         {
            inStack[i].dispatchEvent(focusIn);
            i--;
         }

         nmeFocusOverObjects = inStack;
      }
   }



   function nmeOnFocus(inEvent:Dynamic)
   {
      var stack = new Array<InteractiveObject>();
      var obj:DisplayObject = nmeFindByID(inEvent.id);
      if (obj!=null)
         obj.nmeGetInteractiveObjectStack(stack);
      if (stack.length>0 && (inEvent.value==1 || inEvent.value==2) )
      {
         var obj = stack[0];
         var evt = new FocusEvent(
               inEvent.value==1? FocusEvent.MOUSE_FOCUS_CHANGE : FocusEvent.KEY_FOCUS_CHANGE,
               true, true,
               nmeFocusOverObjects.length==0 ? null : nmeFocusOverObjects[0],
               inEvent.flags>0,
               inEvent.code );

         obj.nmeFireEvent(evt);
         if (evt.nmeGetIsCancelled())
         {
            inEvent.result = 1;
            return;
         }
      }

      stack.reverse();

      nmeCheckFocusInOuts(inEvent,stack);
   }



   static var efLeftDown  =  0x0001;
   static var efShiftDown =  0x0002;
   static var efCtrlDown  =  0x0004;
   static var efAltDown   =  0x0008;
   static var efCommandDown = 0x0010;
   static var efLocationRight = 0x4000;


   function nmeOnKey(inEvent:Dynamic,inType:String)
   {
      var stack = new Array<InteractiveObject>();
      var obj:DisplayObject = nmeFindByID(inEvent.id);
      if (obj!=null)
         obj.nmeGetInteractiveObjectStack(stack);
      if (stack.length>0)
      {
         var obj = stack[0];
         var flags:Int = inEvent.flags;
         var evt = new KeyboardEvent(
               inType,
               true, true,
               inEvent.code,
               inEvent.value,
               ((flags & efLocationRight)==0) ? 1 : 0,
               (flags & efCtrlDown)!=0,
               (flags & efAltDown)!=0,
               (flags & efShiftDown)!=0 );
               

         obj.nmeFireEvent(evt);
         if (evt.nmeGetIsCancelled())
            inEvent.result = 1;
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
		nme.media.SoundChannel.nmePollComplete();
      var type:Int = Std.int(Reflect.field( inEvent, "type" ) );
      switch(type)
      {
         case 2: // etChar
            if (onKey!=null)
               untyped onKey(inEvent.code, inEvent.down, inEvent.char, inEvent.flags );

         case 1: // etKeyDown
            nmeOnKey(inEvent,KeyboardEvent.KEY_DOWN);

         case 3: // etKeyUp
            nmeOnKey(inEvent,KeyboardEvent.KEY_UP);

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

         case 11: // etFocus
            nmeOnFocus(inEvent);

         case 12: // etShouldRotate
            if (shouldRotateInterface(inEvent.value))
               inEvent.result = 2;

         // TODO: user, sys_wm, sound_finished
      }

      return null;
   }

   static var nme_set_stage_handler = nme.Loader.load("nme_set_stage_handler",2);
   static var nme_set_stage_poll_method = nme.Loader.load("nme_set_stage_poll_method",2);
   static var nme_render_stage = nme.Loader.load("nme_render_stage",1);
   static var nme_stage_get_focus_id = nme.Loader.load("nme_stage_get_focus_id",1);
   static var nme_stage_set_focus = nme.Loader.load("nme_stage_set_focus",3);
   static var nme_stage_get_focus_rect = nme.Loader.load("nme_stage_get_focus_rect",1);
   static var nme_stage_set_focus_rect = nme.Loader.load("nme_stage_set_focus_rect",2);
}
