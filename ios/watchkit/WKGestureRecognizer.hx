package ios.watchkit;

import cpp.objc.NSString;
import ios.coregraphics.CGPoint;
import ios.coregraphics.CGRect;

@:objc @:native("WKGestureRecognizer") @:include("WatchKit/WatchKit.h")
extern class WKGestureRecognizer
{
   public static inline var StatePossible = 0;
   public static inline var StateBegan = 1;
   public static inline var StateChanged = 2;
   public static inline var StateEnded = 3;
   public static inline var StateCancelled = 4;
   public static inline var StateFailed = 5;
   public static inline var StateRecognized = 6;


   public var enabled:Bool;
   public var locationInObject(default,null):CGPoint;
   public var objectBounds(default,null):CGRect;
   public var state(default,null):Int;
}




