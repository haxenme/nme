package ios.spritekit;

@:objc
@:native("SKNode")
extern class SKNode
{
   public var scene(default,null):SKScene;
   public var name:cpp.objc.NSString;

   public var position:ios.coregraphics.CGPoint;
   public function setScale(s:Float):Void;
   public var xScale:Float;
   public var yScale:Float;
   public var zRotation:Float;
   public var alpha:Float;
   public var hidden:Bool;
   public var paused:Bool;
   public var userInteractionEnabled:Bool;

   public function addChild(child:SKNode):Void;
   public function insertChild(child:SKNode, atIndex:Int):Void;
   public function removeFromParent():Void;

}



