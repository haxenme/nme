package nme.store;

#if emscripten
@:cppFileCode('
#include <emscripten.h>
#include <nme/store/AdApi.h>

extern "C" {
EMSCRIPTEN_KEEPALIVE void nme_crazygames_on_event(const char *eventName)
{
   ::nme::store::AdApi_obj::onEvent(::String(eventName));
}
}

EM_JS(int, nme_crazygames_is_valid, (), {
   return !!(typeof window !== "undefined" &&
             window.CrazyGames &&
             window.CrazyGames.SDK &&
             typeof window.CrazyGames.SDK.init === "function");
});

EM_JS(int, nme_crazygames_is_ready, (), {
   return !!(typeof window !== "undefined" && window.__nmeCrazyGamesReady === true);
});

EM_JS(int, nme_crazygames_init, (int preloadInterstitial, int preloadReward), {
   if (!nme_crazygames_is_valid()) {
      return 0;
   }

   if (typeof window !== "undefined") {
      if (window.__nmeCrazyGamesInitPromise) {
         return 1;
      }

      window.__nmeCrazyGamesReady = false;

      window.__nmeCrazyGamesInitPromise = Promise.resolve(window.CrazyGames.SDK.init()).then(function() {
         window.__nmeCrazyGamesReady = true;

         if (preloadInterstitial) {
            if (typeof Module !== "undefined" && Module.ccall) {
               Module.ccall("nme_crazygames_on_event", null, ["string"], ["onInterstitialPreloaded"]);
            }
         }
         if (preloadReward) {
            if (typeof Module !== "undefined" && Module.ccall) {
               Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardPreloaded"]);
            }
         }

      }).catch(function(e) {
         window.__nmeCrazyGamesInitPromise = null;
         window.__nmeCrazyGamesReady = false;
      });
   }

   return 1;
});

EM_JS(int, nme_crazygames_play_interstitial, (), {
   if (!nme_crazygames_is_ready()) {
      return 0;
   }

   var ad = window.CrazyGames.SDK.ad;
   ad.requestAd("midgame", {
      adStarted: function() {
         if (typeof Module !== "undefined" && Module.ccall) {
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoBegan"]);
         }
      },
      adFinished: function() {
         if (typeof Module !== "undefined" && Module.ccall) {
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoEnded"]);
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onInterstitialHidden"]);
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onInterstitialPreloaded"]);
         }
      },
      adError: function() {
         if (typeof Module !== "undefined" && Module.ccall) {
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoEnded"]);
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onInterstitialFailedToShow"]);
         }
      }
   });

   return 1;
});

EM_JS(int, nme_crazygames_play_reward, (), {
   if (!nme_crazygames_is_ready()) {
      return 0;
   }

   var ad = window.CrazyGames.SDK.ad;
   ad.requestAd("rewarded", {
      adStarted: function() {
         if (typeof Module !== "undefined" && Module.ccall) {
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoBegan"]);
         }
      },
      adFinished: function() {
         if (typeof Module !== "undefined" && Module.ccall) {
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoEnded"]);
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardVerified"]);
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardHidden"]);
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardPreloaded"]);
         }
      },
      adError: function() {
         if (typeof Module !== "undefined" && Module.ccall) {
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoEnded"]);
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardFailed"]);
            Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardHidden"]);
         }
      }
   });

   return 1;
});
')
#end
class CrazyGames
{
   public static function init(preloadInterstitial:Bool, preloadReward:Bool):Bool
   {
      #if emscripten
      return nme_crazygames_init(preloadInterstitial, preloadReward) != 0;
      #else
      return false;
      #end
   }

   public static function isValid():Bool
   {
      #if emscripten
      return nme_crazygames_is_valid() != 0;
      #else
      return false;
      #end
   }

   public static function playInterstitial(andThen:Void->Void):Bool
   {
      #if emscripten
      return nme_crazygames_play_interstitial() != 0;
      #else
      return false;
      #end
   }

   public static function playReward():Bool
   {
      #if emscripten
      return nme_crazygames_play_reward() != 0;
      #else
      return false;
      #end
   }

   #if emscripten
   @:native("nme_crazygames_init")
   extern static function nme_crazygames_init(preloadInterstitial:Bool, preloadReward:Bool):Int;

   @:native("nme_crazygames_is_valid")
   extern static function nme_crazygames_is_valid():Int;

   @:native("nme_crazygames_is_ready")
   extern static function nme_crazygames_is_ready():Int;

   @:native("nme_crazygames_play_interstitial")
   extern static function nme_crazygames_play_interstitial():Int;

   @:native("nme_crazygames_play_reward")
   extern static function nme_crazygames_play_reward():Int;
   #end
}
