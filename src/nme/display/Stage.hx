package nme.display;
#if !flash

import haxe.Timer;
import nme.app.Application;
import nme.app.Window;
import nme.app.EventId;
import nme.app.AppEvent;
import nme.app.FrameTimer;
import nme.display.DisplayObjectContainer;
import nme.ui.Keyboard;
import nme.events.TextEvent;
import nme.text.TextField;

#if stage3d
import nme.display.Stage3D;
#end
import nme.media.StageVideo;

import nme.ui.GameInput;
import nme.ui.GamepadButton;
import nme.events.GameInputEvent;
import nme.events.JoystickEvent;
import nme.events.MouseEvent;
import nme.events.FocusEvent;
import nme.events.KeyboardEvent;
import nme.events.SystemEvent;
import nme.events.TouchEvent;
import nme.events.Event;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.Lib;
import nme.media.SoundChannel;
import nme.net.URLLoader;
import nme.Loader;
import nme.Vector;
import nme.events.StageVideoAvailabilityEvent;
import haxe.CallStack;

#if cpp
import cpp.vm.Gc;
#end

@:nativeProperty
class Stage extends DisplayObjectContainer implements nme.app.IPollClient implements nme.app.IAppEventHandler
{
   /**
    * Time, in seconds, we wake up before the frame is due.  We then do a
    * "busy wait" to ensure the frame comes at the right time.  By increasing this number,
    * the frame rate will be more constant, but the busy wait will take more CPU.
    * @private
    */
   public static var nmeEarlyWakeup = 0.005;

   public static inline var OrientationPortrait = 1;
   public static inline var OrientationPortraitUpsideDown = 2;
   public static inline var OrientationLandscapeRight = 3;
   public static inline var OrientationLandscapeLeft = 4;
   public static inline var OrientationFaceUp = 5;
   public static inline var OrientationFaceDown = 6;

   // For setting 'fixed' orientation...
   public static inline var OrientationPortraitAny = 7;
   public static inline var OrientationLandscapeAny = 8;
   public static inline var OrientationAny = 9;

   public static inline var OrientationUseFunction = -1;


   public var window(default,null):Window;

   public var active(get, never):Bool;
   public var align(get, set):StageAlign;
   public var displayState(get, set):StageDisplayState;
   public var dpiScale(get, never):Float;
   public var focus(get, set):InteractiveObject;
   public var frameRate(get, set): Float;
   public var onQuit(get,set):Void -> Void; 
   public var isOpenGL(get, never):Bool;
   // Is this used?  Could not tell where "event.down" is being set, therefore this would appear useless
   //public var onKey:Int -> Bool -> Int -> Int -> Void; 

   // Set for custom exception processing
   public var exceptionHandler:Dynamic->Array<StackItem>->Void;

   public var pauseWhenDeactivated:Bool;
   public var quality(get, set):StageQuality;
   public var scaleMode(get, set):StageScaleMode;
   public var stageFocusRect(get, set):Bool;
   public var stageHeight(get, never):Int;
   public var stageWidth(get, never):Int;
   public var renderRequest(get,set):Void->Bool;
   public var color(get,set):Int;

   var invalid:Bool;

   #if stage3d
   public var stage3Ds:Vector<Stage3D>;
   #end
   public var stageVideos:Vector<StageVideo>;

   private static var efLeftDown = 0x0001;
   private static var efShiftDown = 0x0002;
   private static var efCtrlDown = 0x0004;
   private static var efAltDown = 0x0008;
   private static var efCommandDown = 0x0010;
   private static var efLocationRight = 0x4000;
   private static var efNoNativeClick = 0x10000;
   private static var nmeMouseChanges:Array<String> = [ MouseEvent.MOUSE_OUT, MouseEvent.MOUSE_OVER, MouseEvent.ROLL_OUT, MouseEvent.ROLL_OVER ];
   private static var nmeTouchChanges:Array<String> = [ TouchEvent.TOUCH_OUT, TouchEvent.TOUCH_OVER,   TouchEvent.TOUCH_ROLL_OUT, TouchEvent.TOUCH_ROLL_OVER ];
   private static var sClickEvents = [ "click", "middleClick", "rightClick" ];
   private static var sDownEvents = [ "mouseDown", "middleMouseDown", "rightMouseDown" ];
   private static var sUpEvents = [ "mouseUp", "middleMouseUp", "rightMouseUp" ];

   public static var nmeQuitting = false;

   private var nmeJoyAxisData:Array<Array<Float>>;
   private var nmeDragBounds:Rectangle;
   private var nmeDragObject:Sprite;
   private var nmeDragOffsetX:Float;
   private var nmeDragOffsetY:Float;
   private var nmeFocusOverObjects:Array<InteractiveObject>;
   private var nmeFramePeriod:Float;
   private var nmeLastClickTime:Float;
   private var nmeLastDown:Array<InteractiveObject>;
   private var nmeLastRender:Float;
   private var nmeMouseOverObjects:Array<InteractiveObject>;
   private var nmeTouchInfo:Map<Int,TouchInfo>;
   private var nmeFrameTimer:FrameTimer;
   private var nmeEnterFrameEvent:Event;
   private var nmeRenderEvent:Event;

   #if cpp
   var nmePreemptiveGcFreq:Int;
   var nmePreemptiveGcSince:Int;
   var nmeCollectionLock:cpp.vm.Lock;
   var nmeCollectionAgency:cpp.vm.Thread;
   var nmeFrameAlloc:Array<Int>;
   var nmeLastCurrentMemory:Int;
   var nmeLastPreempt:Bool;
   var nmeFrameMemIndex:Int;
   #end

   public function new(inWindow:Window)
   {
      #if HXCPP_TELEMETRY
      Application.initHxTelemetry();
      #end

      nmeEnterFrameEvent = new Event(Event.ENTER_FRAME);
      nmeRenderEvent = new Event(Event.RENDER);

      window = inWindow;
      invalid = false;
      super(window.nmeHandle, "Stage");

      nmeMouseOverObjects = [];
      nmeFocusOverObjects = [];
      pauseWhenDeactivated = true;

      if (window.appEventHandler==null)
      {
         window.appEventHandler = this;
         Application.addPollClient(this);
         nmeFrameTimer = new FrameTimer(window, Application.initFrameRate);
      }

      nmeLastRender = 0;
      nmeLastDown = [];
      nmeLastClickTime = 0.0;
      nmeTouchInfo = new Map<Int,TouchInfo>();
      nmeJoyAxisData = new Array<Array<Float>>();

      #if stage3d
      stage3Ds = new Vector();
      stage3Ds.push(new Stage3D());
      #end
      stageVideos = new Vector<StageVideo>(1);
      stageVideos[0] = new StageVideo(this);

      #if cpp
      nmePreemptiveGcFreq = 0;
      nmePreemptiveGcSince = 0;
      nmeLastCurrentMemory = 0;
      nmeLastPreempt = false;
      nmeFrameMemIndex = 0;
      #end
   }

   public static dynamic function getOrientation():Int 
   {
      return nme_stage_get_orientation();
   }

   public static dynamic function getNormalOrientation():Int 
   {
      return nme_stage_get_normal_orientation();
   }

   public function invalidate():Void 
   {
      invalid=true;
      if (nmeFrameTimer!=null)
         nmeFrameTimer.invalidate();
   }

   public function isDisplayListDirty() : Bool
   {
      var result:Bool =  nme_stage_check_cache(nmeHandle);
      return result;
   }

   function get_onQuit() return Application.onQuit;
   function set_onQuit(val) { Application.onQuit=val; return val; }

   override public function addEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void 
   {
       super.addEventListener(type, listener, useCapture, priority, useWeakReference);
       if (type==StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY)
          dispatchEvent( new StageVideoAvailabilityEvent(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY,false,false,"available") );
   }

   private function nmeCheckFocusInOuts(inEvent:AppEvent, inStack:Array<InteractiveObject>)
   {
      // Exit ...
      var new_n = inStack.length;
      var new_obj:InteractiveObject = new_n > 0 ? inStack[new_n - 1] : null;
      var old_n = nmeFocusOverObjects.length;
      var old_obj:InteractiveObject = old_n > 0 ? nmeFocusOverObjects[old_n - 1] : null;
      
      if (new_obj != old_obj)
      {
         if (old_obj != null)
         {
            var focusOut = new FocusEvent(FocusEvent.FOCUS_OUT, true, false, new_obj, inEvent.flags > 0, inEvent.code);
            focusOut.target = old_obj;
            old_obj.nmeFireEvent(focusOut);
         }
         
         if (new_obj!=null)
         {
            var focusIn = new FocusEvent(FocusEvent.FOCUS_IN, true, false, old_obj, inEvent.flags > 0, inEvent.code);
         
            focusIn.target = new_obj;
            new_obj.nmeFireEvent(focusIn);
         }
         
         nmeFocusOverObjects = inStack;
      }
   }

   private function nmeCheckInOuts(inEvent:MouseEvent, inStack:Array<InteractiveObject>, ?touchInfo:TouchInfo)
   {
      var prev = touchInfo == null ? nmeMouseOverObjects : touchInfo.touchOverObjects;
      var events = touchInfo == null ? nmeMouseChanges : nmeTouchChanges;

      var new_n = inStack.length;
      var new_obj:InteractiveObject = new_n > 0 ? inStack[new_n - 1] : null;
      var old_n = prev.length;
      var old_obj:InteractiveObject = old_n > 0 ? prev[old_n - 1] : null;

      if (new_obj != old_obj) 
      {
         // mouseOut/MouseOver goes up the object tree...
         if (old_obj != null)
            old_obj.nmeFireEvent(inEvent.nmeCreateSimilar(events[0], new_obj, old_obj));

         if (new_obj != null)
            new_obj.nmeFireEvent(inEvent.nmeCreateSimilar(events[1], old_obj));

         // rollOver/rollOut goes only over the non-common objects in the tree...
         var common = 0;
         while(common < new_n && common < old_n && inStack[common] == prev[common])
            common++;

         var rollOut = inEvent.nmeCreateSimilar(events[2], new_obj, old_obj);
         var i = old_n - 1;
         while(i >= common) 
         {
            prev[i].nmeDispatchEvent(rollOut);
            i--;
         }

         var rollOver = inEvent.nmeCreateSimilar(events[3], old_obj);
         var i = new_n - 1;
         while(i >= common) 
         {
            inStack[i].nmeDispatchEvent(rollOver);
            i--;
         }

         if (touchInfo == null)
            nmeMouseOverObjects = inStack;
         else
            touchInfo.touchOverObjects = inStack;

         return false;
      }

      return true;
   }

   // --- IAppEventHandler ----
   
   public function onText(inEvent:AppEvent, type:String):Void
   {
       var obj:DisplayObject = nmeFindByID(inEvent.id);

       if (obj != null && Std.is(obj, TextField))
       {
           var text:String = null;
           if (inEvent.code>0)
           {
              var u = new haxe.Utf8();
              u.addChar( inEvent.code );
              text = u.toString();
           }
           else
           {
              text = inEvent.text;
           }
           var evt = new TextEvent(type, true, true, text);
           evt.target = obj;
           obj.nmeFireEvent(evt);

           if (evt.nmeGetIsCancelled())
               inEvent.result = 1;
       }
   }

   public function onKey(inEvent:AppEvent, type:String):Void
   {
      var stack = new Array<InteractiveObject>();
      var obj:DisplayObject = nmeFindByID(inEvent.id);

      if (obj != null)
         obj.nmeGetInteractiveObjectStack(stack);

      if (stack.length > 0) 
      {
         var value = inEvent.value;

         // This messes with function keys on SDL - why is this here?
         //if (value >= 96 && value <= 122) value -= 32;

         var obj = stack[0];
         var flags:Int = inEvent.flags;
         var evt = new KeyboardEvent(type, true, true, inEvent.code, value,
                    ((flags & efLocationRight) == 0) ? 1 : 0,
                    (flags & efCtrlDown) != 0,
                    (flags & efAltDown) != 0,
                    (flags & efShiftDown) !=0,
                    (flags & efCtrlDown) != 0,
                    (flags & efCommandDown) != 0);
         obj.nmeFireEvent(evt);

         if (evt.nmeGetIsCancelled())
            inEvent.result = 1;

         #if (windows || linux || mac)
         if (inEvent.result != -1 && type == KeyboardEvent.KEY_DOWN) 
         {
            #if mac
            if (flags & efCtrlDown > 0 && flags & efCommandDown > 0 && flags & efShiftDown==0 && inEvent.code == Keyboard.F ) 
            #else
            if (flags & efAltDown > 0 && inEvent.code == Keyboard.ENTER ) 
            #end
            {
               if (displayState == StageDisplayState.NORMAL) 
                  displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
               else 
                  displayState = StageDisplayState.NORMAL;
            }
         }
         #end
      }
   }

   public function onMouse(inEvent:AppEvent, inType:String, inFromMouse):Void
   {
      var type = inType;
      var button:Int = inEvent.value;

      if (!inFromMouse)
         button = 0;

      var wheel = 0;

      if (inType == MouseEvent.MOUSE_DOWN) 
      {
         if (button > 2)
            return;
         type = sDownEvents[button];

      }
      else if (inType == MouseEvent.MOUSE_UP) 
      {
         if (button > 2) 
         {
            type = MouseEvent.MOUSE_WHEEL;
            wheel = button == 3 ? 1 : -1;

         }
         else 
            type = sUpEvents[button];
      }

      if (nmeDragObject != null)
         nmeDrag(new Point(inEvent.x, inEvent.y));

      var stack = new Array<InteractiveObject>();
      var obj:DisplayObject = nmeFindByID(inEvent.id);

      if (obj != null)
         obj.nmeGetInteractiveObjectStack(stack);

      var local:Point = null;
      if (stack.length > 0) 
      {
         var obj = stack[0];
         stack.reverse();
         local = obj.globalToLocal(new Point(inEvent.x, inEvent.y));
         var evt = MouseEvent.nmeCreate(type, inEvent, local, obj);
         evt.delta = wheel;
         if (inFromMouse)
            nmeCheckInOuts(evt, stack);
         obj.nmeFireEvent(evt);

      }
      else 
      {
         //trace("No obj?");
         local = new Point(inEvent.x, inEvent.y);
         var evt = MouseEvent.nmeCreate(type, inEvent, local, null);
         evt.delta = wheel;
         if (inFromMouse)
            nmeCheckInOuts(evt, stack);
      }

      var click_obj = stack.length > 0 ? stack[ stack.length - 1] : this;
      if (inType == MouseEvent.MOUSE_DOWN && button < 3) 
      {
         nmeLastDown[button] = click_obj;

      }
      else if (inType == MouseEvent.MOUSE_UP && button < 3) 
      {
         if (click_obj == nmeLastDown[button]) 
         {
            var evt = MouseEvent.nmeCreate(sClickEvents[button], inEvent, local, click_obj);
            click_obj.nmeFireEvent(evt);

            if (button == 0 && click_obj.doubleClickEnabled) 
            {
               var now = inEvent.pollTime;
               if (now - nmeLastClickTime < 0.25) 
               {
                  var evt = MouseEvent.nmeCreate(MouseEvent.DOUBLE_CLICK, inEvent, local, click_obj);
                  click_obj.nmeFireEvent(evt);
               }

               nmeLastClickTime = now;
            }
         }

         nmeLastDown[button] = null;
      }
   }

   public function onUnhandledException(exception:Dynamic, stack:Array<StackItem>):Void
   {
      if (exceptionHandler!=null)
         exceptionHandler(exception,stack);
      else
      {
         trace("Exception: " + exception+"\n" + haxe.CallStack.toString(stack));
         trace("\n\n\n===Terminating===\n.");
         throw "Unhandled exception:" + exception;
      }
   }
 

   public function onTouch(inEvent:AppEvent, inType:String):Void
   {
      if (inType==TouchEvent.TOUCH_TAP)
         return;

      if (inType==TouchEvent.TOUCH_BEGIN)
      {
         var touchInfo = new TouchInfo();
         nmeTouchInfo.set(inEvent.value, touchInfo);
         nmeOnTouch(inEvent, TouchEvent.TOUCH_BEGIN, touchInfo);
         return;
      }

      var touchInfo = nmeTouchInfo.get(inEvent.value);
      nmeOnTouch(inEvent, inType, touchInfo);

      if (inType==TouchEvent.TOUCH_END)
         nmeTouchInfo.remove(inEvent.value);
   }

   public function onResize(width:Int, height:Int):Void
   {
      var evt = new Event(Event.RESIZE);
      nmeDispatchEvent(evt);
   }

   public function onRender(inFrameDue:Bool)
   {
      #if HXCPP_TELEMETRY
      var hxt = Application.getHxTelemetry();
      hxt.advance_frame();
      #end

      if (inFrameDue)
         nmeBroadcast(nmeEnterFrameEvent);

      if (invalid)
      {
         invalid = false;
         nmeBroadcast(nmeRenderEvent);
      }

      #if cpp
      var rendered = false;
      if (nmeCollectionAgency!=null && nmePreemptiveGcFreq!=0)
      {
         nmePreemptiveGcSince++;
         var preempt = nmePreemptiveGcSince>=nmePreemptiveGcFreq;

         #if (hxcpp_api_level >= 310)
         // Smart preemptive
         if (nmePreemptiveGcFreq<0)
         {
            if (nmeFrameAlloc==null)
               nmeFrameAlloc = [];

            var current = Gc.memInfo(Gc.MEM_INFO_CURRENT);
            if (nmeLastCurrentMemory>0)
            {
               var frameAlloc = current - nmeLastCurrentMemory;
               if (frameAlloc>=0)
               {
                  nmeFrameAlloc[nmeFrameMemIndex++] = frameAlloc;
                  if (nmeFrameMemIndex>10)
                     nmeFrameMemIndex = 0;
               }
               else if (!nmeLastPreempt)
               {
                  //trace("Missed alloc!");
               }
            }
            nmeLastCurrentMemory = current;

            if (nmeFrameAlloc.length>0)
            {
               var sum = 0;
               for(f in nmeFrameAlloc)
                  sum += f;

               var reserved =Gc.memInfo(Gc.MEM_INFO_RESERVED);
               preempt = sum * 1.2 /nmeFrameAlloc.length + current > reserved;
            }
            else
               preempt = false;
         }
         #end

         nmeLastPreempt = preempt;
         if (preempt)
         {
            //trace("preempt");
            nmePreemptiveGcSince = 0;
            rendered = true;
            nme_set_render_gc_free(true);
            Gc.enterGCFreeZone();
            nmeCollectionLock.release();
            #if HXCPP_TELEMETRY
            var stack:String = hxt.unwind_stack();
            hxt.start_timing (".render");
            #end
            nme_render_stage(nmeHandle);
            #if HXCPP_TELEMETRY
            hxt.end_timing (".render");
            hxt.rewind_stack (stack);
            #end
            Gc.exitGCFreeZone();
            nme_set_render_gc_free(false);
         }
         else
         {
            //trace("frame");
         }
      }
      if (!rendered)
      #end
      {
         #if HXCPP_TELEMETRY
         var stack:String = hxt.unwind_stack();
         hxt.start_timing (".render");
         #end
         nme_render_stage(nmeHandle);
         #if HXCPP_TELEMETRY
         hxt.end_timing (".render");
         hxt.rewind_stack (stack);
         #end
      }
   }

   public function onDisplayObjectFocus(inEvent:AppEvent):Void
   {
      var stack = new Array<InteractiveObject>();
      var obj:DisplayObject = nmeFindByID(inEvent.id);

      if (obj != null)
         obj.nmeGetInteractiveObjectStack(stack);

      if (stack.length > 0 && (inEvent.value == 1 || inEvent.value == 2)) 
      {
         var obj = stack[0];
         var evt = new FocusEvent(
                     inEvent.value == 1 ?  FocusEvent.MOUSE_FOCUS_CHANGE : FocusEvent.KEY_FOCUS_CHANGE,
                     true, true, nmeFocusOverObjects.length == 0 ? null : nmeFocusOverObjects[0],
                     inEvent.flags > 0, inEvent.code);
         obj.nmeFireEvent(evt);

         if (evt.nmeGetIsCancelled()) 
         {
            inEvent.result = 1;
            return;
         }
      }
      stack.reverse();

      nmeCheckFocusInOuts(inEvent, stack);
   }

   public function onInputFocus(acquired:Bool):Void
   {
      var evt = new Event(acquired ? FocusEvent.FOCUS_IN : FocusEvent.FOCUS_OUT);
      nmeDispatchEvent(evt);
   }

   public function onRotateRequest(inDirection:Int):Bool
   {
       return shouldRotateInterface(inDirection);
   }

   public function onChange(inEvent:AppEvent):Void
   {
      var obj:DisplayObject = nmeFindByID(inEvent.id);
      if (obj != null)
         obj.nmeFireEvent(new Event(Event.CHANGE));
   }

   public function onScroll(inEvent:AppEvent):Void
   {
      var obj:DisplayObject = nmeFindByID(inEvent.id);
      if (obj != null)
         obj.nmeFireEvent(new Event(Event.SCROLL));
   }

   public function onActive(inActive:Bool):Void
   {
      // trace("nmeSetActive : " + inActive);
      if (inActive != active) 
      {
         window.active = inActive;
         if (!active)
            nmeLastRender = Timer.stamp();

         var evt = new Event(inActive ? Event.ACTIVATE : Event.DEACTIVATE);
         nmeBroadcast(evt);
         //if (inActive)
         //   nmePollTimers();
      }
   }

   private inline function axismap( code:Int )
   {
      #if openfl_legacy
      switch(code)
      {
         case 3: code = 4;
         case 2: code = 3;
         case 4: code = 2;
      }
      #end
      return code;
   }
   private inline function buttonmap( code:Int )
   {
      #if openfl_legacy
      switch(code)
      {
         case  9: code = GamepadButton.LEFT_SHOULDER;
         case  4: code = GamepadButton.BACK;
         case  8: code = GamepadButton.RIGHT_STICK;
         case 10: code = GamepadButton.RIGHT_SHOULDER;
         case  6: code = GamepadButton.START;
         case  7: code = GamepadButton.LEFT_STICK;
      }
      #end
      return code;
   }

   public function onJoystick(inEvent:AppEvent, inType:String):Void
   {
      var data:Array<Float> = null;
      var user = inEvent.value;
      var isGamePad:Bool = inEvent.y>0;
      if(inEvent.flags > 0)
      {
         ///is axis move event
         if(inEvent.flags==1)
         {         
            if(nmeJoyAxisData[user]==null)
               nmeJoyAxisData[user] = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];

            data = nmeJoyAxisData[user];
            data[ inEvent.code ] = inEvent.sx;
            data[ inEvent.code+1 ] = inEvent.sy;
         }
         else if(inEvent.flags==3)
         { 
            //isGamePad
            if(nmeJoyAxisData[user]==null)
               nmeJoyAxisData[user] = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];

            data = nmeJoyAxisData[user];
            data[ axismap(inEvent.code) ] = inEvent.sx;
            data[ axismap(inEvent.code+1) ] = inEvent.sy;
         }
         else if(inEvent.flags==2)
         {
            if(nmeJoyAxisData[user]!=null)
               for(d in nmeJoyAxisData[user])
                  d = 0.0;
         }
      }
      #if openfl_legacy
      if(isGamePad && StringTools.startsWith(inType,"button"))
      {
         //map sdl controller to legacy xinput
         var evt:JoystickEvent = new JoystickEvent(inType, false, false, inEvent.id, buttonmap(inEvent.code),
                                                inEvent.value, inEvent.sx, inEvent.sy, data, isGamePad);
         nmeDispatchEvent(evt);
      }
      else
      #end
      {
         var evt:JoystickEvent = new JoystickEvent(inType, false, false, inEvent.id, inEvent.code,
                                                   inEvent.value, inEvent.sx, inEvent.sy, data, isGamePad);
         nmeDispatchEvent(evt);
      }

      if(GameInput.hasInstances())
      {
         if(inType == JoystickEvent.DEVICE_ADDED)
         {
            GameInput.nmeGamepadConnect(user);
         }
         else if(inType == JoystickEvent.DEVICE_REMOVED)
         {
            GameInput.nmeGamepadDisconnect(user);
         }
         else if(inType == JoystickEvent.AXIS_MOVE)
         {
            GameInput.nmeGamepadAxisMove(user, inEvent.code, inEvent.sx);
            GameInput.nmeGamepadAxisMove(user, inEvent.code+1, inEvent.sy);
         }
         else if(inType == JoystickEvent.BUTTON_DOWN)
         {
            GameInput.nmeGamepadButton(user, inEvent.code, 1);
         }
         else if(inType == JoystickEvent.BUTTON_UP)
         {
            GameInput.nmeGamepadButton(user, inEvent.code, 0);
         }
         else if(inType == JoystickEvent.HAT_MOVE)
         {
            GameInput.nmeGamepadButton(user, GamepadButton.DPAD_UP, inEvent.sy>0.0?1:0);
            GameInput.nmeGamepadButton(user, GamepadButton.DPAD_DOWN, inEvent.sy<0.0?1:0);
            GameInput.nmeGamepadButton(user, GamepadButton.DPAD_LEFT, inEvent.sx<0.0?1:0);
            GameInput.nmeGamepadButton(user, GamepadButton.DPAD_RIGHT, inEvent.sx>0.0?1:0);
         }
      }
   }

   public function onSysMessage(inEvent:AppEvent):Void
   {
      var evt = new SystemEvent(SystemEvent.SYSTEM, false, false, inEvent.value);
      nmeDispatchEvent(evt);
   }

   public function onContextLost():Void
   {
      var evt = new Event(Event.CONTEXT3D_LOST);
      nmeBroadcast(evt);
   }


   // -------------------------


   private function nmeDrag(inMouse:Point)
   {
      var p = nmeDragObject.parent;
      if (p != null)
         inMouse = p.globalToLocal(inMouse);

      var x = inMouse.x + nmeDragOffsetX;
      var y = inMouse.y + nmeDragOffsetY;

      if (nmeDragBounds != null) 
      {
         if (x < nmeDragBounds.x) x = nmeDragBounds.x;
         else if (x > nmeDragBounds.right) x = nmeDragBounds.right;

         if (y < nmeDragBounds.y) y = nmeDragBounds.y;
         else if (y > nmeDragBounds.bottom) y = nmeDragBounds.bottom;
      }

      nmeDragObject.x = x;
      nmeDragObject.y = y;
   }

/*
   private function nmeNextFrameDue(inOtherTimers:Float, inTimestamp:Float)
   {
      if (!active && pauseWhenDeactivated)
         return inOtherTimers;

      if (frameRate > 0) 
      {
         var next = nmeLastRender + nmeFramePeriod - inTimestamp - nmeEarlyWakeup;
         if (next < inOtherTimers)
            return next;
      }

      return inOtherTimers;
   }
*/

   override private function set_opaqueBackground(inBG:Null<Int>):Null<Int> 
   {
      window.setBackground(inBG);
      if (inBG == null)
         DisplayObject.nme_display_object_set_bg(nmeHandle, 0);
      else
         DisplayObject.nme_display_object_set_bg(nmeHandle, inBG | 0xff000000);

      return inBG;
   }

   private function set_color(inColor:Int):Int
   {
      set_opaqueBackground(inColor);
      return inColor;
   }
 

   private function get_color():Int
   {
      var col = opaqueBackground;
      return col==null ? 0 : col;
   }



   function nmeOnTouch(inEvent:AppEvent, inType:String, touchInfo:TouchInfo)
   {
      var stack = new Array<InteractiveObject>();
      var obj:DisplayObject = nmeFindByID(inEvent.id);

      if (obj != null)
         obj.nmeGetInteractiveObjectStack(stack);

      if (stack.length > 0) 
      {
         var obj = stack[0];
         stack.reverse();
         var local = obj.globalToLocal(new Point(inEvent.x, inEvent.y));
         var evt = TouchEvent.nmeCreate(inType, inEvent, local, obj, inEvent.sx, inEvent.sy);
         evt.touchPointID = inEvent.value;
         evt.isPrimaryTouchPoint =(inEvent.flags & 0x8000) > 0;
         //if (evt.isPrimaryTouchPoint)
         nmeCheckInOuts(evt, stack, touchInfo);
         obj.nmeFireEvent(evt);

         if (evt.isPrimaryTouchPoint && inType == TouchEvent.TOUCH_MOVE) 
         {
            if (nmeDragObject != null)
               nmeDrag(new Point(inEvent.x, inEvent.y));

            var evt = MouseEvent.nmeCreate(MouseEvent.MOUSE_MOVE, inEvent, local, obj);
            obj.nmeFireEvent(evt);
         }
      }
      else 
      {
         //trace("No object?");
         var evt = TouchEvent.nmeCreate(inType, inEvent, new Point(inEvent.x, inEvent.y), null, inEvent.sx, inEvent.sy);
         evt.touchPointID = inEvent.value;
         evt.isPrimaryTouchPoint =(inEvent.flags & 0x8000) > 0;
         //if (evt.isPrimaryTouchPoint)
         nmeCheckInOuts(evt, stack, touchInfo);
      }
   }

   // -- IPollCient ----
   public function onPoll(inTimestamp:Float)
   {
      //trace("poll");
      SoundChannel.nmePollComplete();
      URLLoader.nmePollData();
   }

   public function getNextWake(inDefaultWake:Float, inTimestamp:Float) : Float
   {
      var wake = inDefaultWake;

      if (wake>0.001 && SoundChannel.nmeDynamicSoundCount > 0)
         wake = 0.001;

      if (wake > 0.02 && (SoundChannel.nmeCompletePending() || URLLoader.nmeLoadPending())) 
      {
         wake =(active || !pauseWhenDeactivated) ? 0.020 : 0.500;
      }

      return wake;
   }

   // ------------------


   /** @private */ public function nmeStartDrag(sprite:Sprite, lockCenter:Bool, bounds:Rectangle):Void {
      nmeDragBounds =(bounds == null) ? null : bounds.clone();
      nmeDragObject = sprite;

      if (nmeDragObject != null) 
      {
         if (lockCenter) 
         {
            nmeDragOffsetX = -nmeDragObject.width / 2;
            nmeDragOffsetY = -nmeDragObject.height / 2;

         } else 
         {
            var mouse = new Point(mouseX, mouseY);
            var p = nmeDragObject.parent;
            if (p != null)
               mouse = p.globalToLocal(mouse);

            nmeDragOffsetX = nmeDragObject.x - mouse.x;
            nmeDragOffsetY = nmeDragObject.y - mouse.y;
         }
      }
   }

   public function nmeStopDrag(sprite:Sprite):Void
   {
      nmeDragBounds = null;
      nmeDragObject = null;
   }

   public function setPreemtiveGcFrequency(inFrames:Int)
   {
      #if cpp
      #if !(hxcpp_api_level>=310)
      if (inFrames<0)
         inFrames = 0;
      #end
      nmePreemptiveGcSince = 0;
      nmePreemptiveGcFreq = inFrames;
      if (nmeCollectionLock==null && inFrames!=0)
      {
         nmeCollectionLock = new cpp.vm.Lock();
         nmeCollectionAgency = cpp.vm.Thread.create( function() {
           while(true)
           {
              nmeCollectionLock.wait();
              Gc.run(false);
           }
           } );
      }
      #end
   }
   public function setSmartPreemtiveGc()
   {
      setPreemtiveGcFrequency(-1);
   }

   public static function setFixedOrientation(inOrientation:Int):Void
   {
      Application.setFixedOrientation(inOrientation);
   }


   // Ignored - use Application.setFixedOrientation instead.
   public static dynamic function shouldRotateInterface(inOrientation:Int):Bool { return true; }

   public function showCursor(inShow:Bool) 
   {
      nme_stage_show_cursor(nmeHandle, inShow);
   }

   // Getters & Setters
   private function get_focus():InteractiveObject 
   {
      var id = nme_stage_get_focus_id(nmeHandle);
      var obj:DisplayObject = nmeFindByID(id);
      return cast obj;
   }

   private function set_focus(inObject:InteractiveObject):InteractiveObject 
   {
      if (inObject == null)
         nme_stage_set_focus(nmeHandle, null, 0);
      else
         nme_stage_set_focus(nmeHandle, inObject.nmeHandle, 0);
      return inObject;
   }

   private function set_frameRate(inRate:Float):Float 
   {
      if (nmeFrameTimer!=null)
      {
        nmeFrameTimer.fps = inRate;
      }
      return inRate;
   }
   private function get_frameRate():Float return nmeFrameTimer==null ? 0 : nmeFrameTimer.fps;


   private override function get_stage():Stage 
   {
      return this;
   }

   public function resize(width:Int, height:Int):Void window.resize(width,height);

   private function get_stageFocusRect():Bool { return nme_stage_get_focus_rect(nmeHandle); }
   private function set_stageFocusRect(inVal:Bool):Bool 
   {
      nme_stage_set_focus_rect(nmeHandle, inVal);
      return inVal;
   }
   private function get_active():Bool return window.active;
   private function get_align():StageAlign return window.get_align();
   private function set_align(inMode:StageAlign):StageAlign return window.set_align(inMode);
   private function get_displayState():StageDisplayState return window.get_displayState();
   private function set_displayState(inState:StageDisplayState):StageDisplayState return window.set_displayState(inState);
   private function get_dpiScale():Float return window.get_dpiScale();
   private function get_quality():StageQuality return window.get_quality();
   private function set_quality(inQuality:StageQuality) return window.set_quality(inQuality);
   private function get_scaleMode():StageScaleMode return window.get_scaleMode();
   private function set_scaleMode(inMode:StageScaleMode) return window.set_scaleMode(inMode);
   private function get_stageHeight():Int return window.height;
   private function get_stageWidth():Int return window.width;
   private function get_isOpenGL():Bool return window.get_isOpenGL();
   private function get_renderRequest():Void->Bool return window.renderRequest;
   private function set_renderRequest(f:Void->Bool):Void->Bool return window.renderRequest = f;

   // Native Methods
   private static var nme_render_stage = Loader.load("nme_render_stage", 1);
   private static var nme_set_render_gc_free = Loader.load("nme_set_render_gc_free", 1);
   private static var nme_stage_get_focus_id = Loader.load("nme_stage_get_focus_id", 1);
   private static var nme_stage_set_focus = Loader.load("nme_stage_set_focus", 3);
   private static var nme_stage_get_focus_rect = Loader.load("nme_stage_get_focus_rect", 1);
   private static var nme_stage_set_focus_rect = Loader.load("nme_stage_set_focus_rect", 2);
   private static var nme_stage_resize_window = Loader.load("nme_stage_resize_window", 3);
   private static var nme_stage_show_cursor = Loader.load("nme_stage_show_cursor", 2);
  
   private static var nme_stage_get_orientation = Loader.load("nme_stage_get_orientation", 0);
   private static var nme_stage_get_normal_orientation = Loader.load("nme_stage_get_normal_orientation", 0);
   private static var nme_stage_check_cache = Loader.load("nme_stage_check_cache", 1);
}

class TouchInfo 
{
   public var touchOverObjects:Array<InteractiveObject>;

   public function new() 
   {
      touchOverObjects = [];
   }
}

#else
typedef Stage = flash.display.Stage;
#end
