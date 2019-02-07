package nme.app;

#if HXCPP_TELEMETRY
import nme.display.Stage;
#end
import nme.display.StageAlign;
import nme.display.StageDisplayState;
import nme.display.StageQuality;
import nme.display.StageScaleMode;
import nme.events.TextEvent;

@:nativeProperty
class Window 
{
   public var active(default, default):Bool;
   public var align(get, set):StageAlign;
   public var displayState(get, set):StageDisplayState;
   public var dpiScale(get, null):Float;
   public var isOpenGL(get, null):Bool;
   public var quality(get, set):StageQuality;
   public var scaleMode(get, set):StageScaleMode;
   public var title(get, set):String;
   public var x(get, null):Int;
   public var y(get, null):Int;
   public var height(get, null):Int;
   public var width(get, null):Int;
   public var autoClear:Bool;

   // For extennal window management
   public var renderRequest:Void->Bool;
   public var nextWakeHandler:Float->Void;
   public var beginRenderImmediate:Void->Void;
   public var endRenderImmediate:Void->Void;

   // Set this to handle events...
   public var appEventHandler:IAppEventHandler;

   //public var onKey:Int -> Int -> Int -> Void;
   public var onText: AppEvent -> Void;

   public var nmeHandle(default,null):nme.NativeHandle;
   var enterFramePending:Bool;

   public function new(inFrameHandle:Dynamic,inWidth:Int,inHeight:Int)
   {
      appEventHandler = null;
      active = true;
      autoClear = true;
 
      #if android
      var nme_stage_request_render = PrimeLoader.load("nme_stage_request_render", "v");
      renderRequest = function() { nme_stage_request_render(); return false;}
      #else
      renderRequest = null;
      #end
 
      nmeHandle = nme_get_frame_stage(inFrameHandle);

      nme_set_stage_handler(nmeHandle, nmeProcessWindowEvent, inWidth, inHeight);
   }

   public function shouldRenderNow() : Bool
   {
      if (renderRequest==null)
         return true;
      return renderRequest();
   }

   public function setBackground(inBackground:Null<Int>) : Void
   {
      if (inBackground == null)
         nme_display_object_set_bg(nmeHandle, 0);
      else
         nme_display_object_set_bg(nmeHandle, inBackground | 0xff000000);
   }


   public function onNewFrame():Void
   {
      if (shouldRenderNow())
      {
         if (beginRenderImmediate!=null)
            beginRenderImmediate();
         beginRender();
         appEventHandler.onRender(true);
         endRender();
         if (endRenderImmediate!=null)
            endRenderImmediate();
      }
      else
      {
         // On android, we must wait for the redraw before rendering.
         // Set the flag so we don't have more enterframes than render
         enterFramePending = true;
      }
   }


   public function onInvalidFrame():Void
   {
      if (shouldRenderNow())
      {
         if (beginRenderImmediate!=null)
            beginRenderImmediate();
         beginRender();
         appEventHandler.onRender(false);
         endRender();
         if (endRenderImmediate!=null)
            endRenderImmediate();
      }
      else
      {
         // On android, we must wait for the redraw before rendering.
      }
   }


   function nmeProcessWindowEvent(inEvent:Dynamic)
   {
      if (appEventHandler==null)
          return;

      #if HXCPP_TELEMETRY
      var hxt = Application.getHxTelemetry();
      var hxtStack:String = hxt.unwind_stack();
      hxt.start_timing (".event");
      #end
      var event:AppEvent = inEvent;
      try
      {
         #if !(cpp && hxcpp_api_level>=312)
         inEvent.pollTime = haxe.Timer.stamp();
         #end

         switch(event.type)
         {
            case EventId.Poll:
               Application.pollClients(event.pollTime);
   
            case EventId.Char: // Ignore
                //if (onKey != null)
                //     untyped onKey(event.code, event.value, event.flags);
                if (onText != null)
                    untyped onText(event);
                appEventHandler.onText(event, TextEvent.TEXT_INPUT);

            case EventId.KeyDown:
               appEventHandler.onKey(event, EventName.KEY_DOWN);
   
            case EventId.KeyUp:
               appEventHandler.onKey(event, EventName.KEY_UP);
   
            case EventId.MouseMove:
               appEventHandler.onMouse(event, EventName.MOUSE_MOVE, true);
   
            case EventId.MouseDown:
               appEventHandler.onMouse(event, EventName.MOUSE_DOWN, true);
   
            case EventId.MouseClick:
               appEventHandler.onMouse(event, EventName.CLICK, true);
   
            case EventId.MouseUp:
               appEventHandler.onMouse(event, EventName.MOUSE_UP, true);
   
            case EventId.Resize:
               appEventHandler.onResize(event.x, event.y);
               if (shouldRenderNow())
               {
                  if (beginRenderImmediate!=null)
                     beginRenderImmediate();
                  beginRender();
                  appEventHandler.onRender(false);
                  endRender();
                  if (endRenderImmediate!=null)
                     endRenderImmediate();
               }
   
            case EventId.Quit:
               if (Application.onQuit != null)
                  Application.onQuit();
   
            case EventId.Focus:
               appEventHandler.onDisplayObjectFocus(event);
   
            case EventId.ShouldRotate:
               // Removed
   
            case EventId.Redraw:
               beginRender();
               var wasTimed = enterFramePending;
               enterFramePending = false;
               appEventHandler.onRender(wasTimed);
               endRender();
   
            case EventId.TouchBegin:
               appEventHandler.onTouch(event,EventName.TOUCH_BEGIN);
               if ((event.flags & 0x8000) > 0)
                  appEventHandler.onMouse(event, EventName.MOUSE_DOWN, false);
   
            case EventId.TouchMove:
               appEventHandler.onTouch(event,EventName.TOUCH_MOVE);
   
            case EventId.TouchEnd:
               appEventHandler.onTouch(event,EventName.TOUCH_END);
               if ((event.flags & 0x8000) > 0)
                  appEventHandler.onMouse(event, EventName.MOUSE_UP, false);
   
            case EventId.TouchTap:
               appEventHandler.onTouch(event,EventName.TOUCH_TAP);
   
            case EventId.Change:
               appEventHandler.onChange(event);
   
            case EventId.Activate:
               appEventHandler.onActive(true);
   
            case EventId.Deactivate:
               appEventHandler.onActive(false);
   
            case EventId.GotInputFocus:
               appEventHandler.onInputFocus(true);
   
            case EventId.LostInputFocus:
               appEventHandler.onInputFocus(false);
   
            case EventId.JoyAxisMove:
               appEventHandler.onJoystick(event, EventName.AXIS_MOVE);
   
            case EventId.JoyBallMove:
               appEventHandler.onJoystick(event, EventName.BALL_MOVE);
   
            case EventId.JoyHatMove:
               appEventHandler.onJoystick(event, EventName.HAT_MOVE);
   
            case EventId.JoyButtonDown:
               appEventHandler.onJoystick(event, EventName.BUTTON_DOWN);
   
            case EventId.JoyButtonUp:
               appEventHandler.onJoystick(event, EventName.BUTTON_UP);

            case EventId.JoyDeviceAdded:
               appEventHandler.onJoystick(event, EventName.DEVICE_ADDED);

            case EventId.JoyDeviceRemoved:
               appEventHandler.onJoystick(event, EventName.DEVICE_REMOVED);
   
            case EventId.SysWM:
               appEventHandler.onSysMessage(event);
   
            case EventId.RenderContextLost:
               appEventHandler.onContextLost();

            case EventId.Scroll:
               appEventHandler.onScroll(event);
         }


         var nextWake:Float = Application.getNextWake(event.pollTime);
         if (nextWakeHandler!=null)
            nextWakeHandler(nextWake);

         #if (cpp && hxcpp_api_level>=312)
         event.pollTime = nextWake;
         #else
         nme_stage_set_next_wake(nmeHandle,nextWake);
         #end
      }
      catch(e:Dynamic)
      {
         var stack = haxe.CallStack.exceptionStack();
         event.pollTime = 0;
         appEventHandler.onUnhandledException(e,stack);
      }
      #if HXCPP_TELEMETRY
      hxt.end_timing (".event");
      hxt.rewind_stack (hxtStack);
      #end
   }

   public function beginRender()
   {
      nme_stage_begin_render(nmeHandle,autoClear);
   }
   public function endRender()
   {
      nme_stage_end_render(nmeHandle);
   }


   public function get_align():StageAlign 
   {
      var i:Int = nme_stage_get_align(nmeHandle);
      return Type.createEnumIndex(StageAlign, i);
   }

   public function set_align(inMode:StageAlign):StageAlign 
   {
      nme_stage_set_align(nmeHandle, Type.enumIndex(inMode));
      return inMode;
   }

   public function get_displayState():StageDisplayState 
   {
      var i:Int = nme_stage_get_display_state(nmeHandle);
      return Type.createEnumIndex(StageDisplayState, i);
   }

   public function set_displayState(inState:StageDisplayState):StageDisplayState 
   {
      nme_stage_set_display_state(nmeHandle, Type.enumIndex(inState));
      return inState;
   }

   public function get_dpiScale():Float 
   {
      return nme_stage_get_dpi_scale(nmeHandle);
   }



   public function get_isOpenGL():Bool 
   {
      return nme_stage_is_opengl(nmeHandle);
   }

   public function get_quality():StageQuality 
   {
      var i:Int = nme_stage_get_quality(nmeHandle);
      return Type.createEnumIndex(StageQuality, i);
   }

   public function set_quality(inQuality:StageQuality):StageQuality 
   {
      nme_stage_set_quality(nmeHandle, Type.enumIndex(inQuality));
      return inQuality;
   }

   public function get_scaleMode():StageScaleMode 
   {
      var i:Int = nme_stage_get_scale_mode(nmeHandle);
      return Type.createEnumIndex(StageScaleMode, i);
   }

   public function set_scaleMode(inMode:StageScaleMode):StageScaleMode 
   {
      nme_stage_set_scale_mode(nmeHandle, Type.enumIndex(inMode));
      return inMode;
   }

   public function get_x():Int 
   {
      return nme_stage_get_window_x(nmeHandle);
   }

   public function get_y():Int 
   {
      return nme_stage_get_window_y(nmeHandle);
   }



   public function get_height():Int 
   {
      return nme_stage_get_stage_height(nmeHandle);
   }

   public function get_width():Int 
   {
      return nme_stage_get_stage_width(nmeHandle);
   }


   public function resize(width:Int, height:Int):Void
   {
      nme_stage_resize_window(nmeHandle, width, height);
   }


   public function setPosition(x:Int, y:Int):Void
   {
      nme_stage_set_window_position(nmeHandle, x, y);
   }

   public function get_title():String
   {
      return nme_stage_get_title(nmeHandle);
   }

   public function set_title(inTitle:String):String
   {
      nme_stage_set_title(nmeHandle,inTitle);
      return inTitle;
   }



   private static var nme_stage_resize_window = PrimeLoader.load("nme_stage_resize_window", "oiiv");
   private static var nme_stage_is_opengl = PrimeLoader.load("nme_stage_is_opengl", "ob");
   private static var nme_stage_get_stage_width = PrimeLoader.load("nme_stage_get_stage_width", "oi");
   private static var nme_stage_get_stage_height = PrimeLoader.load("nme_stage_get_stage_height", "oi");
   private static var nme_stage_get_dpi_scale = PrimeLoader.load("nme_stage_get_dpi_scale", "od");
   private static var nme_stage_get_scale_mode = PrimeLoader.load("nme_stage_get_scale_mode", "oi");
   private static var nme_stage_set_scale_mode = PrimeLoader.load("nme_stage_set_scale_mode", "oiv");
   private static var nme_stage_get_align = PrimeLoader.load("nme_stage_get_align", "oi");
   private static var nme_stage_set_align = PrimeLoader.load("nme_stage_set_align", "oiv");
   private static var nme_stage_get_quality = PrimeLoader.load("nme_stage_get_quality", "oi");
   private static var nme_stage_set_quality = PrimeLoader.load("nme_stage_set_quality", "oiv");
   private static var nme_stage_get_display_state = PrimeLoader.load("nme_stage_get_display_state", "oi");
   private static var nme_stage_set_display_state = PrimeLoader.load("nme_stage_set_display_state", "oiv");
   //private static var nme_stage_show_cursor = PrimeLoader.load("nme_stage_show_cursor", 2);
   //private static var nme_stage_set_fixed_orientation = PrimeLoader.load("nme_stage_set_fixed_orientation", 1);
   //private static var nme_stage_get_orientation = PrimeLoader.load("nme_stage_get_orientation", 0);
   //private static var nme_stage_get_normal_orientation = PrimeLoader.load("nme_stage_get_normal_orientation", 0);
   private static var nme_stage_set_window_position = PrimeLoader.load("nme_stage_set_window_position", "oiiv");
   private static var nme_stage_get_window_x = PrimeLoader.load("nme_stage_get_window_x", "oi");
   private static var nme_stage_get_window_y = PrimeLoader.load("nme_stage_get_window_y", "oi");
   private static var nme_stage_set_next_wake = PrimeLoader.load("nme_stage_set_next_wake", "odv");
   private static var nme_stage_begin_render = PrimeLoader.load("nme_stage_begin_render", "obv");
   private static var nme_stage_end_render = PrimeLoader.load("nme_stage_end_render", "ov");

   private static var nme_get_frame_stage = PrimeLoader.load("nme_get_frame_stage", "oo");
   private static var nme_display_object_set_bg = Loader.load("nme_display_object_set_bg", 2);
   private static var nme_stage_get_title = PrimeLoader.load("nme_stage_get_title", "os");
   private static var nme_stage_set_title = PrimeLoader.load("nme_stage_set_title", "osv");

   #if (cpp && hxcpp_api_level>=312)
   private static var nme_set_stage_handler = PrimeLoader.load("nme_set_stage_handler_native", "ooiiv");
   #else
   private static var nme_set_stage_handler = PrimeLoader.load("nme_set_stage_handler", "ooiiv");
   #end
}


