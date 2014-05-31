package nme.app;

interface IAppEventHandler
{
   public function onKey(event:AppEvent, type:String):Void;
   public function onMouse(event:AppEvent, type:String, inFromMouse:Bool):Void;
   public function onTouch(event:AppEvent, type:String):Void;
   public function onResize(width:Int, height:Int):Void;
   public function onRender(fromNewFrame:Bool):Void;
   public function onDisplayObjectFocus(event:AppEvent):Void;
   public function onInputFocus(acquired:Bool):Void;
   public function onRotateRequest(inDirection:Int):Bool;
   public function onChange(event:AppEvent):Void;
   public function onActive(activated:Bool):Void;
   public function onJoystick(event:AppEvent, type:String):Void;
   public function onSysMessage(event:AppEvent):Void;
   public function onContextLost():Void;
}


