package ios.coregraphics;

@:include("CoreGraphics/CoreGraphics.h")
@:native("CGRect")
@:structAccess
extern class CGRect
{
   public var origin:CGPoint;
   public var size:CGSize;


   @:native("CGRectMake")
   public static function make(x:Float, y:Float, w:Float, h:Float) : CGRect;
}


