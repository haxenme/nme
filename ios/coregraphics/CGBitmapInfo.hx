package ios.coregraphics;

@:include("CoreGraphics/CoreGraphics.h")
extern class CGBitmapInfo
{
   @:native("kCGBitmapAlphaInfoMask")
   public static var AlphaInfoMask:CGBitmapInfo;
   @:native("kCGBitmapFloatComponents")
   public static var FloatComponents:CGBitmapInfo;
   @:native("kCGBitmapByteOrderMask")
   public static var ByteOrderMask:CGBitmapInfo;
   @:native("kCGBitmapByteOrderDefault")
   public static var ByteOrderDefault:CGBitmapInfo;
   @:native("kCGBitmapByteOrder16Little")
   public static var ByteOrder16Little:CGBitmapInfo;
   @:native("kCGBitmapByteOrder32Little")
   public static var ByteOrder32Little:CGBitmapInfo;
   @:native("kCGBitmapByteOrder16Big")
   public static var ByteOrder16Big:CGBitmapInfo;
   @:native("kCGBitmapByteOrder32Big")
   public static var pByteOrder32Big:CGBitmapInfo;
   @:native("kCGBitmapFloatInfoMask")
   public static var FloatInfoMask:CGBitmapInfo;
}
