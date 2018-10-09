package nme.watchos;

import ios.spritekit.SKScene;
import ios.spritekit.SKSceneDelegate;


class SpriteKitApp extends App implements SKSceneDelegate
{
   static var asSKDelegate: cpp.objc.Protocol<SKSceneDelegate>;

   public function asSKSceneDelegate()
   {
      // Keep strong reference
      asSKDelegate = this;
      return asSKDelegate;
   }
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

