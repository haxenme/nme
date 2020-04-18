package nme.app;

import haxe.Timer;
import nme.app.Application;
import nme.app.FrameTimer;
import haxe.CallStack;

@:nativeProperty
class NmeApplication implements IAppEventHandler implements IPollClient
{
   public var width(default,null):Int;
   public var height(default,null):Int;
   public var fullViewport(default,null):Array<Int>;
   public var window : Window;
   public var frameTimer : FrameTimer;
   public var frameRate(get,set) : Float;

   public function new(inWindow:Window)
   {
      #if androidview
      ApplicationMain.setAndroidViewHaxeObject(this);
      #end
      window = inWindow;
      window.appEventHandler = this;
      width = inWindow.width;
      height = inWindow.width;
      fullViewport = [0,0,width,height];
      createFrameTimer();
   }

   public function createFrameTimer()
   {
      frameTimer = new FrameTimer(window,100);
   }

   public function invalidate()
   {
      if (frameTimer!=null)
         frameTimer.invalidate();
   }

   function get_frameRate() return frameTimer==null ? 0 : frameTimer.fps;
   function set_frameRate(fps:Float) return frameTimer==null ? fps : frameTimer.fps = fps;


   // --- IPollClient -----

   public function onPoll(timestamp:Float):Void
   {
   }

   public function getNextWake(inDefault:Float, timestamp:Float):Float
   {
      return inDefault;
   }

   // --- IAppEventHandler -----

   public function onResize(inWidth:Int, inHeight:Int):Void
   {
      width = inWidth;
      height = inHeight;
      fullViewport = [0,0,width,height];
   }

   public function onText(event:AppEvent, type:String):Void
   {
   }

   public function onRender(inNewFrame:Bool):Void
   {
   }

   public function onContextLost():Void
   {
   }


   public function onKey(event:AppEvent, type:String):Void
   {
   }

   public function onMouse(event:AppEvent, type:String, inFromMouse:Bool):Void
   {
   }

   public function onTouch(event:AppEvent, type:String):Void
   {
   }


   public function onDisplayObjectFocus(event:AppEvent):Void
   {
   }

   public function onInputFocus(acquired:Bool):Void
   {
   }

   public function onRotateRequest(inDirection:Int):Bool
   {
      return true;
   }

   public function onChange(event:AppEvent):Void
   {
   }

   public function onActive(activated:Bool):Void
   {
   }

   public function onJoystick(event:AppEvent, type:String):Void
   {
   }

   public function onSysMessage(event:AppEvent):Void
   {
   }

   public function onAppLink(inEvent:AppEvent):Void
   {
   }

   public function onScroll(event:AppEvent):Void
   {
   }


   public function onDpiChanged(event:AppEvent):Void
   {
   }

   public function onDrop(event:AppEvent):Void
   {
   }

   public function onUnhandledException(exception:Dynamic, stack:Array<StackItem>):Void
   {
      trace("Exception: " + exception+"\n" + haxe.CallStack.toString(stack));
      trace("\n\n\n===Terminating===\n.");
      throw "Unhandled exception:" + exception;
   }
}


