package org.haxe.nme;
import com.applovin.sdk.AppLovinSdk;
import com.applovin.sdk.AppLovinSdkConfiguration;
import com.applovin.sdk.AppLovinAdRewardListener;
import com.applovin.sdk.AppLovinAdVideoPlaybackListener;
import com.applovin.sdk.AppLovinAdDisplayListener;
import com.applovin.sdk.AppLovinAd;
import com.applovin.adview.AppLovinIncentivizedInterstitial;
import com.applovin.adview.AppLovinInterstitialAd;
import com.applovin.adview.AppLovinInterstitialAdDialog;
import com.applovin.sdk.AppLovinAdLoadListener;
import com.applovin.sdk.AppLovinAdSize;
import org.haxe.nme.HaxeObject;

import android.content.Context;
import java.util.Map;
import android.util.Log;

class NmeAppLovin
{
   static GameActivity sGameActivity;
   static AppLovinIncentivizedInterstitial myIncent;
   static AppLovinAd loadedAd;
   static AppLovinInterstitialAdDialog adDialog;
   static HaxeObject watcher;
   static boolean preloadOnInit = false;
   static boolean isInit = false;
   static final String TAG = "NmeAppLovin";

   public static void initializeSdk(GameActivity inGameActivity)
   {
      Log.d(TAG,"initializeSdk");

      sGameActivity = inGameActivity;
      AppLovinSdk.initializeSdk(sGameActivity.mContext,
        new AppLovinSdk.SdkInitializationListener()
        {
            @Override
            public void onSdkInitialized(final AppLovinSdkConfiguration config)
            {
                isInit = true;
                Log.d(TAG,"initializeSdk done pre=" + preloadOnInit);
                if (preloadOnInit)
                {
                   preloadAsync();
                   preloadRewardAsync();
                }
            }
      });
      //isInit = true;
   }

   public static void setWatcher(final HaxeObject inWatcher, final boolean andPreload)
   {
      Log.d(TAG,"setWatcher");
      watcher = inWatcher;
      if (andPreload)
      {
         GameActivity.queueRunnable( new Runnable() {
         @Override public void run() {
            preloadOnInit = true;
            if (isInit)
               Log.d(TAG,"setWatcher done init=" + isInit);
               preloadOnInit = false;
               preloadAsync();
               preloadRewardAsync();
         } } );
      }
   }

   public static void playInterstitial( )
   {
      GameActivity.queueRunnable( new Runnable() {
         @Override public void run() {
             playInterstitialAsync();
         } } );
   }

   public static void playReward( )
   {
      GameActivity.queueRunnable( new Runnable() {
         @Override public void run() {
            playRewardAsync();
         } } );
   }

   static void send(final String message)
   {
       GameActivity.sendHaxe( new Runnable() {
         @Override public void run() {
            if (watcher!=null)
               watcher.call1("onAppLovin", message);
         } } );
   }


   static void preloadAsync()
   {
      Context ctx = sGameActivity.mContext;
      // Load an Interstitial Ad
      AppLovinSdk.getInstance( ctx ).getAdService().loadNextAd( AppLovinAdSize.INTERSTITIAL,
        new AppLovinAdLoadListener()
        {
            @Override
            public void adReceived(AppLovinAd ad)
            {
               loadedAd = ad;
               NmeAppLovin.send("onInterstitialPreloaded");
            }

            @Override
            public void failedToReceiveAd(int errorCode)
            {
               // Look at AppLovinErrorCodes.java for list of error codes.
               NmeAppLovin.send("onInterstitialPreloadFailed");
            }
        } );
   }

   static void preloadRewardAsync()
   {
      Context ctx = sGameActivity.mContext;
      if (myIncent==null)
         myIncent = AppLovinIncentivizedInterstitial.create(ctx);
      myIncent.preload(new AppLovinAdLoadListener() {
         @Override
         public void adReceived(AppLovinAd appLovinAd) {
             NmeAppLovin.send("onRewardPreloaded");
         }
         @Override
         public void failedToReceiveAd(int errorCode) {
             // A rewarded video failed to load.
             NmeAppLovin.send("onRewardPreloadFailed");
         }
     });
   }

   // Play a rewarded video in correspondence to a button click
    static void playRewardAsync()
    {
       // Check to see if a rewarded video is available.
       if (myIncent!=null && myIncent.isAdReadyToDisplay()){
           // A rewarded video is available.  Call the show method with the listeners you want to use.
           // We will use the display listener to preload the next rewarded video when this one finishes.
           Context ctx = sGameActivity.mContext;
           myIncent.show( ctx,
             new AppLovinAdRewardListener() {
                @Override
                public void userRewardVerified(final AppLovinAd ad, Map<String, String> response) {
                   NmeAppLovin.send("onRewardVerified");
                }
                @Override
                public void userOverQuota(final AppLovinAd ad, Map<String, String> response) {
                   NmeAppLovin.send("onRewardOverQuota");
                }
                @Override
                public void userRewardRejected(final AppLovinAd ad, final Map<String, String> response) {
                   NmeAppLovin.send("onRewardRejected");
                }
                @Override
                public void validationRequestFailed(final AppLovinAd ad, final int errorCode) {
                   NmeAppLovin.send("onRewardFailed");
                }
                @Override
                public void userDeclinedToViewAd(final AppLovinAd ad) {
                   NmeAppLovin.send("onRewardCaneled");
                }
             },
             new AppLovinAdVideoPlaybackListener() {
                @Override public void videoPlaybackBegan(AppLovinAd appLovinAd) {
                   NmeAppLovin.send("onVideoBegan");
                }
                @Override
                public void videoPlaybackEnded(AppLovinAd appLovinAd, double percentViewed, boolean wasFullyViewed) {
                   NmeAppLovin.send("onVideoEnded");
                }
             },
           new AppLovinAdDisplayListener() {
               @Override
               public void adDisplayed(AppLovinAd appLovinAd) {
                   // A rewarded video is being displayed.
                   NmeAppLovin.send("onRewardDisplayed");
               }
               @Override
               public void adHidden(AppLovinAd appLovinAd) {
                   // A rewarded video was closed.  Preload the next video now.  We won't use a load listener.
                   myIncent.preload(null);
                   NmeAppLovin.send("onRewardHidden");
               }
           });
       }
       else
       {
          // No ad is currently available.  Perform failover logic...
          NmeAppLovin.send("rewardNotAvailable");
       }
    }

    static void playInterstitialAsync( )
    {
       Log.e(TAG,"playInterstitialAsync");
       Context ctx = sGameActivity.mContext;
       if (adDialog==null)
           adDialog = AppLovinInterstitialAd.create( AppLovinSdk.getInstance( ctx ), ctx);
       adDialog.setAdDisplayListener(new AppLovinAdDisplayListener() {
          @Override
          public void adDisplayed(AppLovinAd appLovinAd) {
              // An interstitial ad was displayed.
              NmeAppLovin.send("onInterstitialDisplayed");
          }
          @Override
          public void adHidden(AppLovinAd appLovinAd) {
              // An interstitial ad was hidden.
              preloadAsync();
              NmeAppLovin.send("onInterstitialHidden");
          }
      } );
      adDialog.setAdVideoPlaybackListener( new AppLovinAdVideoPlaybackListener() {
         @Override public void videoPlaybackBegan(AppLovinAd appLovinAd) {
            NmeAppLovin.send("onVideoBegan");
         }
         @Override
         public void videoPlaybackEnded(AppLovinAd appLovinAd, double percentViewed, boolean wasFullyViewed) {
            NmeAppLovin.send("onVideoEnded");
         }
      });
      if (loadedAd!=null)
         adDialog.showAndRender(loadedAd);
      else
         adDialog.show();
    }
}

