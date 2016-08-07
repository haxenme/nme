package nme.watchos;
import nme.watchos.HaxeLink;

@:cppFileCode("
typedef int (*HxHaxeCall)(int inFunction, int inParam);
void HxSetHaxeCallback( HxHaxeCall inCall );
int HxCall(int inFunction, int inParam)
{
   return ::nme::watchos::App_obj::hxCallback(inFunction, inParam);
}
")
class App
{
   static var theApp:App = null;

   public function new()
   {
      theApp = this;
      HaxeLink.setCallback( cpp.Function.nativeFromStaticFunction(hxCallback) );
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


   function run(inFunc:Int, inParam:Int) : Int
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
      }
      return 0;
   }


   static function hxCallback(func:Int, param:Int) : Int  return theApp.run(func,param);
}

