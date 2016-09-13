package ios.uikit;


@:objc
@:native("UIColor")
@:include("UIKit/UIKit.h")
extern class UIColor
{

   public static var blackColor(default,null):UIColor;
   public static var darkGrayColor(default,null):UIColor;
   public static var lightGrayColor(default,null):UIColor;
   public static var whiteColor(default,null):UIColor;
   public static var grayColor(default,null):UIColor;
   public static var redColor(default,null):UIColor;
   public static var greenColor(default,null):UIColor;
   public static var blueColor(default,null):UIColor;
   public static var cyanColor(default,null):UIColor;
   public static var yellowColor(default,null):UIColor;
   public static var magentaColor(default,null):UIColor;
   public static var orangeColor(default,null):UIColor;
   public static var purpleColor(default,null):UIColor;
   public static var brownColor(default,null):UIColor;
   public static var clearColor(default,null):UIColor;


   @:native("colorWithWhite:alpha")
   public static function withWhite(white:Float, alpha:Float):UIColor;
   @:native("colorWithHue:saturation:brightness:alpha")
   public static function withHue(hue:Float, saturation:Float, brightness:Float,alpha:Float):UIColor;
   @:native("colorWithRed:green:blue:alpha")
   public static function withRed(red:Float, green:Float, blue:Float,alpha:Float):UIColor;
}


