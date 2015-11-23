package nme.native;

import nme.native.Include;


@:structAccess
@:include("nme/Event.h")
@:native("nme::Event")
extern class NativeEvent
{
   public var type : Int;
   public var x : Int;
   public var y : Int;
   public var value:Int;
   public var code:Int;
   public var id:Int;
   public var flags:Int;
   public var result:Int;
   public var scaleX:Float;
   public var scaleY:Float;
   public var deltaX:Float;
   public var deltaY:Float;
   public var pollTime:Float;
   public var utf8Text:cpp.RawConstPointer<cpp.Char>;
   public var utf8Length:Int;
}


