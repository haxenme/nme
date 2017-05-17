package ios.spritekit;

@:objcProtocol("SKSceneDelegate")
interface SKSceneDelegate
{
   public function update(t:Float, forScene:SKScene):Void;
   public function didEvaluateActionsForScene(scene:SKScene):Void;
   public function didSimulatePhysicsForScene(scene:SKScene):Void;
   public function didApplyConstraintsForScene(scene:SKScene):Void;
   public function didFinishUpdateForScene(scene:SKScene):Void;

}


