package ios.coregraphics;

@:include("CoreGraphics/CoreGraphics.h")
@:native("CGSize")
@:structAccess
extern class CGSize
{
   public var width:Float;
   public var height:Float;

   @:native("CGSizeMake")
   public static function make(w:Float, h:Float) : CGSize;
}

