package ios.coregraphics;

@:native("cpp::Pointer<CGColorSpace>")
@:include("@CoreGraphics")
extern class CGColorSpace
{
   @:native("CGColorSpaceCreateDeviceRGB")
   public static function createDeviceRGB() : CGColorSpace;

   @:native("CGColorSpaceRelease")
   public static function release(col:CGColorSpace) : Void;

   @:native("CGColorSpaceRetain")
   public static function retain(col:CGColorSpace) : Void;

}

