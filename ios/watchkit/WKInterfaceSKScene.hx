package ios.watchkit;
import ios.spritekit.SKScene;

import cpp.objc.NSString;

@:objc
extern class WKInterfaceSKScene
{
   public var preferredFramesPerSecond:Float;
   public var paused:Bool;
   public var scene(default,null):SKScene;

   //@:overload
   public function presentScene(scene:SKScene):Void;
}


