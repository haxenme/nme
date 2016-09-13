package ios.uikit;


@:objc
@:native("UIImage")
@:include("UIKit/UIKit.h")
extern class UIImage
{

   public static function imageNamed(name:cpp.objc.NSString):UIImage;
   public static function imageWithData(data:cpp.objc.NSData):UIImage;
   public static function imageWithCGImage(image:ios.coregraphics.CGImage):UIImage;
   public function isEqual(other:UIImage):Bool;
}

