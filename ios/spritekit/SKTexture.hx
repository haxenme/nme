package ios.spritekit;

import ios.uikit.UIColor;
import ios.uikit.UIImage;
import ios.coregraphics.CGSize;
import ios.coregraphics.CGImage;
import ios.coregraphics.CGRect;
import cpp.objc.NSString;

@:objc
@:native("SKTexture")
@:include("SpriteKit/SKTexture.h")
extern class SKTexture
{

   @:native("textureWithImageNamed")
   public static function withImageNamed(name:NSString):SKTexture;

   @:native("textureWithImage")
   public static function withImage(image:UIImage):SKTexture;

   @:native("textureWithCGImage")
   public static function withCGImage(image:CGImage):SKTexture;

   @:native("textureWithRect:inTexture")
   public static function withRect(rect:CGRect, inTexture:SKTexture):SKTexture;

   public var filteringMode:SKTextureFilteringMode;
   public var size:CGSize;

}





