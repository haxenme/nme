package ios.spritekit;

import ios.coregraphics.CGSize;

@:objc
@:native("SKScene")
@:include("SpriteKit/SpriteKit.h")
extern class SKScene extends SKNode
{
   public var delegate:cpp.objc.Protocol<SKSceneDelegate>;

   @:native("sceneWithSize")
   public static function withSize(size:CGSize):SKScene;

   public var scaleMode:SKSceneScaleMode;

}


