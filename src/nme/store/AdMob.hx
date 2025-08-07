package nme.store;

#if ios
@:fileXml('tag="nme-haxe"')
@:cppInclude('./AdMobIos.mm')
#end
class AppLovin
{
   public static function init(preloadInterstitial:Bool, preloadReward:Bool)
   {
      #if android
      androidSetWatcher( AdApi.instance, preloadInterstitial, preloadReward );
      return true;
      #elseif ios
      if (preloadInterstitial)
         loadInterstitialAd();
      if (preloadReward)
         loadRewardedVideo();
      return true;
      #else
      return false;
      #end
   }

   public static function playInterstitial()
   {
      #if android
      androidPlayInterstitial();
      return true;
      #elseif ios
      showInterstitialAd();
      return true;
      #else
      return false;
      #end
   }

   public static function playReward()
   {
      #if android
      androidPlayReward();
      return true;
      #elseif ios
      showRewardedVideo();
      return true;
      #else
      return false;
      #end
   }

   #if android
   static var androidSetWatcher = JNI.createStaticMethod("org/haxe/nme/NmeAdMob", "setWatcher", "(Lorg/haxe/nme/HaxeObject;ZZ)V");
   static var androidPlayInterstitial = JNI.createStaticMethod("org/haxe/nme/NmeAdMob", "playInterstitial", "()V");
   static var androidPlayReward = JNI.createStaticMethod("org/haxe/nme/NmeAdMob", "playReward", "()V");
   #elseif ios
   @:native("loadInterstitialAd")
   extern static function loadInterstitialAd() : Void;
   @:native("loadRewardedVideo")
   extern static function loadRewardedVideo() : Void;
   @:native("showRewardedVideo")
   extern static function showRewardedVideo() : Void;
   @:native("showInterstitialAd")
   extern static function showInterstitialAd() : Void;
   #end
}



