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
   return !!(typeof window !== "undefined" && window.__nmeHostingApiReady === true);
});

// SDK init is done by the HTML template before WASM starts; this just registers
// the settings-change listener and fires any requested preload events.
EM_JS(int, nme_crazygames_init, (int preloadInterstitial, int preloadReward), {
   if (!window.__nmeHostingApiReady) {
      return 0;
   }

   window.CrazyGames.SDK.game.addSettingsChangeListener(function(newSettings) {
      Module.ccall("nme_crazygames_on_event", null, ["string"], ["onSettingsChanged"]);
   });

   if (preloadInterstitial) {
      Module.ccall("nme_crazygames_on_event", null, ["string"], ["onInterstitialPreloaded"]);
   }
   if (preloadReward) {
      Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardPreloaded"]);
   }

   return 1;
});

EM_JS(int, nme_crazygames_play_interstitial, (), {
   if (!window.__nmeHostingApiReady) {
      return 0;
   }

   window.CrazyGames.SDK.ad.requestAd("midgame", {
      adStarted: function() {
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoBegan"]);
      },
      adFinished: function() {
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoEnded"]);
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onInterstitialHidden"]);
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onInterstitialPreloaded"]);
      },
      adError: function() {
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoEnded"]);
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onInterstitialFailedToShow"]);
      }
   });

   return 1;
});

EM_JS(int, nme_crazygames_play_reward, (), {
   if (!window.__nmeHostingApiReady) {
      return 0;
   }

   window.CrazyGames.SDK.ad.requestAd("rewarded", {
      adStarted: function() {
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoBegan"]);
      },
      adFinished: function() {
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoEnded"]);
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardVerified"]);
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardHidden"]);
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardPreloaded"]);
      },
      adError: function() {
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onVideoEnded"]);
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardFailed"]);
         Module.ccall("nme_crazygames_on_event", null, ["string"], ["onRewardHidden"]);
      }
   });

   return 1;
});

EM_JS(int, nme_crazygames_get_mute_audio, (), {
   if (!window.__nmeHostingApiReady) return 0;
   var settings = window.CrazyGames.SDK.game.settings;
   return (settings && settings.muteAudio) ? 1 : 0;
});

EM_JS(void, nme_crazygames_report_gameplay_start, (), {
   if (!window.__nmeHostingApiReady) return;
   window.CrazyGames.SDK.game.gameplayStart();
});

EM_JS(void, nme_crazygames_report_gameplay_stop, (), {
   if (!window.__nmeHostingApiReady) return;
   window.CrazyGames.SDK.game.gameplayStop();
});

EM_JS(void, nme_crazygames_happytime, (), {
   if (!window.__nmeHostingApiReady) return;
   window.CrazyGames.SDK.game.happytime();
});

EM_JS(void, nme_crazygames_report_game_completed_percentage, (int pct), {
   if (!window.__nmeHostingApiReady) return;
   window.CrazyGames.SDK.game.reportGameCompletedPercentage(pct);
});

EM_JS(void, nme_crazygames_set_game_context, (const char *json), {
   if (!window.__nmeHostingApiReady) return;
   try {
      window.CrazyGames.SDK.game.setGameContext(JSON.parse(UTF8ToString(json)));
   } catch(e) {}
});

EM_JS(void, nme_crazygames_clear_game_context, (), {
   if (!window.__nmeHostingApiReady) return;
   window.CrazyGames.SDK.game.clearGameContext();
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

   public static function playInterstitial():Bool
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

   public static function getMuteAudio():Bool
   {
      #if emscripten
      return nme_crazygames_get_mute_audio() != 0;
      #else
      return false;
      #end
   }

   public static function reportGameplayStart():Void
   {
      #if emscripten
      nme_crazygames_report_gameplay_start();
      #end
   }

   public static function reportGameplayStop():Void
   {
      #if emscripten
      nme_crazygames_report_gameplay_stop();
      #end
   }

   public static function happytime():Void
   {
      #if emscripten
      nme_crazygames_happytime();
      #end
   }

   public static function reportGameCompletedPercentage(pct:Int):Void
   {
      #if emscripten
      nme_crazygames_report_game_completed_percentage(pct);
      #end
   }

   public static function setGameContext(context:{}):Void
   {
      #if emscripten
      nme_crazygames_set_game_context(haxe.Json.stringify(context));
      #end
   }

   public static function clearGameContext():Void
   {
      #if emscripten
      nme_crazygames_clear_game_context();
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

   @:native("nme_crazygames_get_mute_audio")
   extern static function nme_crazygames_get_mute_audio():Int;

   @:native("nme_crazygames_report_gameplay_start")
   extern static function nme_crazygames_report_gameplay_start():Void;

   @:native("nme_crazygames_report_gameplay_stop")
   extern static function nme_crazygames_report_gameplay_stop():Void;

   @:native("nme_crazygames_happytime")
   extern static function nme_crazygames_happytime():Void;

   @:native("nme_crazygames_report_game_completed_percentage")
   extern static function nme_crazygames_report_game_completed_percentage(pct:Int):Void;

   @:native("nme_crazygames_set_game_context")
   extern static function nme_crazygames_set_game_context(json:cpp.ConstCharStar):Void;

   @:native("nme_crazygames_clear_game_context")
   extern static function nme_crazygames_clear_game_context():Void;
   #end
}
