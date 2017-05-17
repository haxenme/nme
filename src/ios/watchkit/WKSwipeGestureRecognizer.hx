package ios.watchkit;

import cpp.objc.NSString;

@:objc @:native("WKSwipeGestureRecognizer") @:include("WatchKit/WatchKit.h")
extern class WKSwipeGestureRecognizer extends WKGestureRecognizer
{
   public inline static var DirectionRight = 1 << 0;
   public inline static var DirectionLeft = 1 << 1;
   public inline static var DirectionUp = 1 << 2;
   public inline static var DirectionDown = 1 << 3;

   public var direction:Int;

}



