package nme.app;
import haxe.CallStack;

@:nativeProperty
interface IAppEventHandler
{
   public function onRender(inTimed:Bool):Void;
   public function onText(event:AppEvent, type:String):Void;
   public function onKey(event:AppEvent, type:String):Void;
   public function onMouse(event:AppEvent, type:String, inFromMouse:Bool):Void;
   public function onTouch(event:AppEvent, type:String):Void;
   public function onResize(width:Int, height:Int):Void;
   public function onDisplayObjectFocus(event:AppEvent):Void;
   public function onInputFocus(acquired:Bool):Void;
   public function onChange(event:AppEvent):Void;
   public function onActive(activated:Bool):Void;
   public function onJoystick(event:AppEvent, type:String):Void;
   public function onSysMessage(event:AppEvent):Void;
   public function onAppLink(event:AppEvent):Void;
   public function onContextLost():Void;
   public function onScroll(event:AppEvent):Void;
   public function onUnhandledException(exception:Dynamic, stack:Array<StackItem>):Void;
}


