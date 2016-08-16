package ios.uikit;


@:objc
@:native("UIImage")
@:include("@UIKit")
extern class UIImage
{

   public static function imageNamed(name:cpp.NSString):UIImage;
   public static function imageWithData(data:cpp.NSData):UIImage;
   public static function imageWithCGImage(image:ios.coreGraphics.CGImage):UIImage;
   public function isEqual(other:UIImage):Bool;
}

