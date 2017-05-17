package ios.spritekit;

import ios.coregraphics.CGSize;

@:objc
@:native("SKColor")
extern class SKColor
{
   @:natice("labelNodeWithFontNamed")
   public static function withFontNamed(font:String):SKLabelNode;

   public var text:NSString;
   public var fontSize:Float;
   public var fontColor:SKColor;

}




