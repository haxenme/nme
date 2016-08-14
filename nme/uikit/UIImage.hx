package nme.uikit;


@:objc
@:native("UIImage")
extern class UIImage
{

   public static function imageNamed(name:cpp.NSString):UIImage;
   public static function imageWithData(data:cpp.NSData):UIImage;
   public function isEqual(other:UIImage):Bool;
}

