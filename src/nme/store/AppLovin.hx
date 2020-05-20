package nme.store;

class AppLovin
{
   static var watcher:String->Void;
   static var afterInterstitial:Void->Void;
   public static var isPreloaded = false;

   function new() {}
   @:keep function onAppLovin(event:String) onEvent(event);

   public static function setWatcher(watcher:String->Void, andPreload:Bool)
   {
      #if android
      androidSetWatcher( new AppLovin(), andPreload );
      #end
   }

   public static function onEvent(e:String)
   {
      trace("AppLovin:" + e);
      switch(e)
      {
         case "onInterstitialHidden":
            if (afterInterstitial!=null)
            {
               var a = afterInterstitial;
               afterInterstitial = null;
               trace("Call " + a);
               a();
            }
         case "onInterstitialPreloaded":
            isPreloaded = true;

         case "onInterstitialPreloadFailed":
            isPreloaded = false;
      }
      if (watcher!=null)
         watcher(e);
   }

   public static function playInterstitial(?inAfterInterstitial:Void->Void)
   {
      #if android
      afterInterstitial = inAfterInterstitial;
      androidPlayInterstitial();
      #else
      if (inAfterInterstitial!=null)
         inAfterInterstitial();
      #end
   }

   public static function playRewarded( )
   {
      #if android
      androidPlayReward();
      #end
   }


   #if android
   static var androidSetWatcher = JNI.createStaticMethod("org/haxe/nme/NmeAppLovin", "setWatcher", "(Lorg/haxe/nme/HaxeObject;Z)V");
   static var androidPlayInterstitial = JNI.createStaticMethod("org/haxe/nme/NmeAppLovin", "playInterstitial", "()V");
   static var androidPlayReward = JNI.createStaticMethod("org/haxe/nme/NmeAppLovin", "playReward", "()V");
   #end
}


