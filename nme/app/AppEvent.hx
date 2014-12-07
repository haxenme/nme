package nme.app;

#if (cpp && hxcpp_api_level>=311)
import nme.native.NativeEvent;

abstract AppEvent(cpp.Pointer<NativeEvent>) from cpp.Pointer<NativeEvent>
{
   public var type(get,never) : Int;
   public var x(get,never) : Int;
   public var y(get,never) : Int;
   public var value(get,never):Int;
   public var code(get,never):Int;
   public var id(get,never):Int;
   public var flags(get,never):Int;
   public var result(get,set):Int;
   public var sx(get,never):Float;
   public var sy(get,never):Float;
   public var deltaX(get,never):Float;
   public var deltaY(get,never):Float;
   public var pollTime(get,set):Float;

   inline function get_type():Int return this.ref.type;
   inline function get_x():Int return this.ref.x;
   inline function get_y():Int return this.ref.y;
   inline function get_value():Int return this.ref.value;
   inline function get_code():Int return this.ref.code;
   inline function get_id():Int return this.ref.id;
   inline function get_flags():Int return this.ref.flags;
   inline function get_result():Int return this.ref.result;
   inline function set_result(inResult:Int):Int return this.ref.result = inResult;
   inline function get_sx():Float return this.ref.scaleX;
   inline function get_sy():Float return this.ref.scaleY;
   inline function get_deltaX():Float return this.ref.deltaX;
   inline function get_deltaY():Float return this.ref.deltaY;
   inline function get_pollTime():Float return this.ref.pollTime;
   inline function set_pollTime(inWake:Float):Float return this.ref.pollTime = inWake;
}

#else
typedef AppEvent =
{
   var type : Int;
   var x : Int;
   var y : Int;
   var value:Int;
   var code:Int;
   var id:Int;
   var flags:Int;
   var result:Int;
   var sx:Float;
   var sy:Float;
   var deltaX:Float;
   var deltaY:Float;
   var pollTime:Float;
}
#end

