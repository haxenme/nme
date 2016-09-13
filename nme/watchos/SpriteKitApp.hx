package nme.watchos;

import ios.spritekit.SKScene;


class SpriteKitApp extends App implements ios.spritekit.SKSceneDelegate
{
   public function onUpdate(time:Float) { }

   // SKSceneDelegate
   public function didEvaluateActionsForScene(scene:SKScene):Void { }
   public function didSimulatePhysicsForScene(scene:SKScene):Void { }
   public function didApplyConstraintsForScene(scene:SKScene):Void { }
   public function didFinishUpdateForScene(scene:SKScene):Void { }
   public function update(time:Float, scene:SKScene)
   {
      onUpdate(time);
   }

}

