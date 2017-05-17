package ios.spritekit;

import ios.coregraphics.CGSize;

@:include("SpriteKit/SpriteKit.h")
@:objc
@:native("SKLabelNode")
extern class SKLabelNode extends SKNode
{
   @:native("labelNodeWithFontNamed")
   public static function withFontNamed(font:String):SKLabelNode;

   public var text:cpp.objc.NSString;
   public var fontSize:Float;
   public var fontColor:ios.uikit.UIColor;

}



