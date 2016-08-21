package ios.coregraphics;

@:include("@CoreGraphics")
@:native("CGPoint")
@:structAccess
extern class CGPoint
{
   public var x:Float;
   public var y:Float;


   @:native("CGPointMake")
   public static function make(x:Float, x:Float) : CGPoint;
}



