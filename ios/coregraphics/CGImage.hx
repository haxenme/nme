package ios.coregraphics;

@:native("cpp::Pointer<CGImage>")
@:include("CoreGraphics/CoreGraphics.h")
extern class CGImage
{
   @:native("CGImageCreate")
   public static function create(width:Int, height:Int, bitsPerComponent:Int, bitsPerPixel:Int, bytesPerRow:Int, space:CGColorSpace,
                   bitmapInfo:CGBitmapInfo, provider:CGDataProvider, decode:cpp.ConstPointer<cpp.Float32>, shouldInterpolate:Bool,
                   intent:CGColorRenderingIntent ) : CGImage;

   @:native("CGImageRelease")
   public static function release(image:CGImage):Void;

   @:native("CGImageRetain")
   public static function retain(image:CGImage):Void;

}

