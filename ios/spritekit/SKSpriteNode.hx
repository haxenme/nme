package ios.spritekit;

import ios.uikit.UIColor;
import ios.coregraphics.CGSize;
import cpp.objc.NSString;

@:objc
@:native("SKSpriteNode")
@:include("SpriteKit/SpriteKit.h")
extern class SKSpriteNode extends SKNode
{
   @:native("spriteNodeWithColor:size")
   public static function withColor(color:UIColor,size:CGSize):SKSpriteNode;

   @:native("spriteNodeWithImageNamed")
   public static function withImageNamed(name:NSString):SKSpriteNode;

   @:native("spriteNodeWithTexture")
   public static function withTexture(texture:SKTexture):SKSpriteNode;

   @:native("spriteNodeWithTexture:size")
   public static function withTextureSize(texture:SKTexture,size:CGSize):SKSpriteNode;

   @:native("spriteNodeWithImageNamed:normapMap")
   public static function withImageNamedNormalMap(name:NSString,generateNormalMap:Bool):SKSpriteNode;

   @:native("spriteNodeWithTexture:normalMap")
   public static function withTextureNormalMap(texture:SKTexture,generateNormalMap:Bool):SKSpriteNode;

}




