package nme.store;

#if ios
@:fileXml('tag="nme-haxe"')
@:cppInclude('./AdMobIos.mm')
#end
class AdMob
{
   public static function init(preloadInterstitial:Bool, preloadReward:Bool)
   {
      trace("NME AdMob init preloadInterstitial=" + preloadInterstitial + " preloadReward=" + preloadReward);
      #if android
      androidSetWatcher( AdApi.instance, preloadInterstitial, preloadReward );
      return true; // SDK is present; ad availability signaled via onInterstitialPreloaded/Failed events
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

   public static function isValid():Bool
   {
      #if android
      return true;
      #elseif ios
      return true;
      #else
      return false;
      #end
   }

   public static function playInterstitial()
   {
      trace("NME AdMob playInterstitial");
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
      trace("NME AdMob playReward");
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

   public static function retryInterstitialLoad() {
      trace("NME AdMob retryInterstitialLoad");
      #if android
      androidRetryInterstitialLoad();
      #end
   }

   public static function retryRewardBackground() {
      trace("NME AdMob retryRewardBackground");
      #if android
      androidRetryRewardBackground();
      #end
   }

   public static function requestRewardLoad() {
      trace("NME AdMob requestRewardLoad");
      #if android
      androidRetryRewardLoad();
      #end
   }

   #if android
   static var androidSetWatcher = JNI.createStaticMethod("org/haxe/nme/NmeAdMob", "setWatcher", "(Lorg/haxe/nme/HaxeObject;ZZ)Z");
   static var androidPlayInterstitial = JNI.createStaticMethod("org/haxe/nme/NmeAdMob", "playInterstitial", "()V");
   static var androidPlayReward = JNI.createStaticMethod("org/haxe/nme/NmeAdMob", "playReward", "()V");
   static var androidRetryInterstitialLoad = JNI.createStaticMethod("org/haxe/nme/NmeAdMob", "retryInterstitialLoad", "()V");
   static var androidRetryRewardLoad = JNI.createStaticMethod("org/haxe/nme/NmeAdMob", "retryRewardLoad", "()V");
   static var androidRetryRewardBackground = JNI.createStaticMethod("org/haxe/nme/NmeAdMob", "retryRewardBackground", "()V");
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



