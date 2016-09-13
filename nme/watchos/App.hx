package nme.watchos;


class App
{
   public static var instance(default,null):App;

   public function new()
   {
      instance = this;
   }


   // From ExtensionDelegate
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



   // From InterfaceController...
   // public static function setInterfaceController(controller:ios.watchkit.InterfaceController)

   public function onAwake()
   {
      trace("onAwake");
   }

   public function willActivate()
   {
      trace("willActivate");
   }


   public function didDeactivate()
   {
      trace("didDeactivate");
   }


   public function onButton(buttonId:Int)
   {
      trace('buttonId $buttonId');
   }


}

