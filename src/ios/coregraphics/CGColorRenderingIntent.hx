package ios.coregraphics;

@:include("CoreGraphics/CoreGraphics.h")
extern class CGColorRenderingIntent
{
   @:native("kCGRenderingIntentDefault")
   public static var Default:CGColorRenderingIntent;
   @:native("kCGRenderingIntentAbsoluteColorimetric")
   public static var AbsoluteColorimetric:CGColorRenderingIntent;
   @:native("kCGRenderingIntentRelativeColorimetric")
   public static var RelativeColorimetric:CGColorRenderingIntent;
   @:native("kCGRenderingIntentPerceptual")
   public static var Perceptual:CGColorRenderingIntent;
   @:native("kCGRenderingIntentSaturation")
   public static var IntentSaturation:CGColorRenderingIntent;
}

