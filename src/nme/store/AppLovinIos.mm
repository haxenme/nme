#import <AppLovinSDK/AppLovinSDK.h>






@interface RewardController : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate, ALAdRewardDelegate>
//@property (nonatomic, strong) ALAd * _Nullable rewardedAd;
@end

@implementation RewardController


- (void)loadRewardedVideo
{
   [ALIncentivizedInterstitialAd shared].adDisplayDelegate = self;
   [ALIncentivizedInterstitialAd shared].adVideoPlaybackDelegate = self;
   [ALIncentivizedInterstitialAd preloadAndNotify: self];
}


-(void) videoPlaybackBeganInAd: (nonnull ALAd*) ad {
   nme::store::AppLovin_obj::onEvent("onVideoBegan");
   }

-(void) videoPlaybackEndedInAd: (nonnull ALAd*) ad atPlaybackPercent: (nonnull NSNumber*) percentPlayed fullyWatched: (BOOL) wasFullyWatched {
   }

-(void) ad: (nonnull ALAd *) ad wasDisplayedIn: (nonnull UIView *) view
{
}

-(void) ad: (nonnull ALAd *) ad wasHiddenIn: (nonnull UIView *) view
{
   nme::store::AppLovin_obj::onEvent("onRewardHidden");
   [ALIncentivizedInterstitialAd preloadAndNotify: self];
}

-(void) ad: (nonnull ALAd *) ad wasClickedIn: (nonnull UIView *) view { }

- (void)showRewardedVideo
{
    if ( [ALIncentivizedInterstitialAd isReadyForDisplay] )
    {
        // If you want to use a reward delegate, set it here. For this example, we will use nil.
        [ALIncentivizedInterstitialAd showAndNotify: self];
    }
    else
    {
        nme::store::AppLovin_obj::onEvent("rewardNotAvailable");
    }
}


 // ALAdRewardDelegate
 - (void)rewardValidationRequestForAd:(nonnull ALAd *)ad didSucceedWithResponse:(nonnull NSDictionary *)response
 {
   nme::store::AppLovin_obj::onEvent("onRewardVerified");
 }

 - (void)rewardValidationRequestForAd:(nonnull ALAd *)ad didExceedQuotaWithResponse:(nonnull NSDictionary *)response
 {
   nme::store::AppLovin_obj::onEvent("onRewardOverQuota");
 }

 - (void)rewardValidationRequestForAd:(nonnull ALAd *)ad wasRejectedWithResponse:(nonnull NSDictionary *)response
 {
   nme::store::AppLovin_obj::onEvent("onRewardRejected");
 }

 - (void)rewardValidationRequestForAd:(nonnull ALAd *)ad didFailWithError:(NSInteger)responseCode
 {
   nme::store::AppLovin_obj::onEvent("onRewardFailed");
 }

 - (void)userDeclinedToViewAd:(nonnull ALAd *)ad
 {
   nme::store::AppLovin_obj::onEvent("onRewardCaneled");
 }



#pragma mark - Ad Load Delegate

- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad
{
    // We now have an interstitial ad we can show!
    nme::store::AppLovin_obj::onEvent("onRewardPreloaded");
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    // Look at ALErrorCodes.h for the list of error codes.
    nme::store::AppLovin_obj::onEvent("onRewardPreloadFailed");
}


@end



@interface AdController : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate >
@end

@implementation AdController

- (void)loadInterstitialAd
{
    [ALInterstitialAd shared].adDisplayDelegate = self;
    [ALInterstitialAd shared].adVideoPlaybackDelegate = self;
    // Load an interstitial ad and be notified when the ad request is finished.
    [[ALSdk shared].adService loadNextAd: ALAdSize.interstitial andNotify: self];
}

- (void)showInterstitialAd
{
   [[ALInterstitialAd shared] show];
}

// ALAdVideoPlaybackDelegate

-(void) videoPlaybackBeganInAd: (nonnull ALAd*) ad
{
   nme::store::AppLovin_obj::onEvent("onVideoBegan");
}

/**
 * This method is invoked when a video stops playing in an ad.
 *
 * This method is invoked on the main UI thread.
 *
 * @param ad                Ad in which video playback ended.
 * @param percentPlayed     How much of the video was watched, as a percent.
 * @param wasFullyWatched   Whether or not the video was watched to, or very near to, completion.
 */
-(void) videoPlaybackEndedInAd: (nonnull ALAd*) ad atPlaybackPercent: (nonnull NSNumber*) percentPlayed fullyWatched: (BOOL) wasFullyWatched
{
   nme::store::AppLovin_obj::onEvent("onVideoEnded");
}


/**
 * This method is invoked when the ad is displayed in the view.
 *
 * This method is invoked on the main UI thread.
 * 
 * @param ad     Ad that was just displayed. Will not return nil.
 * @param view   Ad view in which the ad was displayed. Will not return nil. 
 */
-(void) ad: (nonnull ALAd *) ad wasDisplayedIn: (nonnull UIView *) view
{
}

/**
 * This method is invoked when the ad is hidden from in the view. This occurs
 * when the ad is rotated or when it is explicitly closed.
 * 
 * This method is invoked on the main UI thread.
 * 
 * @param ad     Ad that was just hidden. Will not return nil.
 * @param view   Ad view in which the ad was hidden. Will not return nil.
 */
-(void) ad: (nonnull ALAd *) ad wasHiddenIn: (nonnull UIView *) view
{
   nme::store::AppLovin_obj::onEvent("onInterstitialHidden");
   [self loadInterstitialAd];
}

/**
 * This method is invoked when the ad is clicked from in the view.
 * 
 * This method is invoked on the main UI thread.
 *
 * @param ad     Ad that was just clicked. Will not return nil.
 * @param view   Ad view in which the ad was hidden. Will not return nil.
 */
-(void) ad: (nonnull ALAd *) ad wasClickedIn: (nonnull UIView *) view
{
}



- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad
{
    // We now have an interstitial ad we can show!
    nme::store::AppLovin_obj::onEvent("onInterstitialPreloaded");
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code
{
    // Look at ALErrorCodes.h for the list of error codes.
    nme::store::AppLovin_obj::onEvent("onInterstitialPreloadFailed");
}

@end


static AdController *_Nonnull adController = [[AdController alloc] init];
static RewardController *_Nonnull rewardController = [[RewardController alloc] init];
static bool isInitPending = false;
static bool isInit = false;
static bool loadInterstitialAdPending = false;
static bool loadRewardedVideoPending = false;

void doInit()
{
  if (!isInit)
  {
     isInit = true;
     isInitPending = true;
     [[ALSdk shared] initializeSdkWithCompletionHandler:^(ALSdkConfiguration *configuration) {
        // SDK finished initialization
        isInitPending = false;
        if (loadInterstitialAdPending)
           [adController loadInterstitialAd];
        if (loadRewardedVideoPending)
           [rewardController loadRewardedVideo];
    }];
  }
}

void loadInterstitialAd()
{
   doInit();
   if (!isInitPending)
      [adController loadInterstitialAd];
   else
      loadInterstitialAdPending = true;
}

void showInterstitialAd()
{
   [adController showInterstitialAd];
}


void loadRewardedVideo()
{
   doInit();
   if (!isInitPending)
      [rewardController loadRewardedVideo];
   else
      loadRewardedVideoPending = true;
}


void showRewardedVideo()
{
   [rewardController showRewardedVideo];
}


