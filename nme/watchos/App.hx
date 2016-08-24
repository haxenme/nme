package nme.watchos;
import nme.watchos.HaxeLink;

#if nme_spritekit
import ios.spritekit.SKScene;
import cpp.NativeArc;
#end

@:cppFileCode("
typedef int (*HxHaxeCall)(int inFunction, int inParam, double inDParam, void *inPtrParam);
void HxSetHaxeCallback( HxHaxeCall inCall );
")
class App
{
   static var theApp:App = null;

   public function new()
   {
      theApp = this;
      var callback = cpp.Function.fromStaticFunction(App.hxCallback);
      HaxeLink.setCallback( callback );
   }

   public function onAwake()
   {
      trace("onAwake");
   }

   public function willActivate()
   {
      trace("willActivate");
   }

   public function didActivate()
   {
      trace("didActivate");
   }

   public function applicationDidFinishLaunching()
   {
      trace("applicationDidFinishLaunching");
   }

   public function applicationDidBecomeActive()
   {
      trace("applicationDidBecomeActive");
   }

   public function applicationWillResignActive()
   {
      trace("applicationWillResignActive");
   }

   public function onButton(buttonId:Int)
   {
      trace('buttonId $buttonId');
   }


   #if nme_spritekit
   public function updateScene(scene:SKScene, time:Float) : Void { }
   public function didEvaluateActionsForScene(scene:SKScene) : Void { }
   public function didSimulatePhysicsForScene(scene:SKScene) : Void { }
   public function didApplyConstraintsForScene(scene:SKScene) : Void { }
   public function didFinishUpdateForScene(scene:SKScene) : Void { }
   #end


   function run(inFunc:Int, inParam:Int, dParam:Float, pParam:cpp.RawPointer<cpp.Void> ) : Int
   {
      switch(inFunc)
      {
         case HaxeLink.onAwake:  onAwake();
         case HaxeLink.willActivate: willActivate();
         case HaxeLink.didActivate: didActivate();
         case HaxeLink.applicationDidFinishLaunching: applicationDidFinishLaunching();
         case HaxeLink.applicationDidBecomeActive: applicationDidBecomeActive();
         case HaxeLink.applicationWillResignActive: applicationWillResignActive();
         case HaxeLink.onButton: onButton(inParam);


         #if nme_spritekit
         case HaxeLink.updateScene: updateScene( NativeArc.bridgeTransfer(pParam), dParam );
         case HaxeLink.didEvaluateActionsForScene: didEvaluateActionsForScene( NativeArc.bridgeTransfer(pParam) );
         case HaxeLink.didSimulatePhysicsForScene: didSimulatePhysicsForScene( NativeArc.bridgeTransfer(pParam) );
         case HaxeLink.didApplyConstraintsForScene: didApplyConstraintsForScene( NativeArc.bridgeTransfer(pParam) );
         case HaxeLink.didFinishUpdateForScene: didFinishUpdateForScene( NativeArc.bridgeTransfer(pParam) );
         #end
      }
      return 0;
   }


   static function hxCallback(func:Int, iParam:Int, dParam:Float, pParam:cpp.RawPointer<cpp.Void> ) : Int  return theApp.run(func,iParam,dParam, pParam);
}

