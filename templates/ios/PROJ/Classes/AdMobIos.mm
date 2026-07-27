// AdMobIos.mm - compiled by Xcode (not hxcpp).
// Has access to the Google Mobile Ads SPM framework headers.
// Calls back into the hxcpp runtime via the C bridge defined in
// src/nme/store/AdMobIos.mm (compiled by hxcpp).

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>

// ---------------------------------------------------------------------------
// C bridge back into hxcpp runtime (defined in src/nme/store/AdMobIos.mm)
// ---------------------------------------------------------------------------
#ifdef __cplusplus
extern "C" {
#endif
void c_nmeAdMobOnEvent(const char *event);
#ifdef __cplusplus
}
#endif

// ---------------------------------------------------------------------------
// Ad unit ID resolution.
// When NME_REAL_ADS is defined the hxcpp build passes the configured IDs as
// preprocessor defines; otherwise fall back to Google test IDs.
// ---------------------------------------------------------------------------
#define NME_ADMOB_XSTR(x) #x
#define NME_ADMOB_STR(x)  NME_ADMOB_XSTR(x)

#if defined(NME_REAL_ADS) && defined(NME_ADMOB_INTERSTITIAL_ID)
static NSString *const kNMEInterstitialAdUnitID = @NME_ADMOB_STR(NME_ADMOB_INTERSTITIAL_ID);
#else
static NSString *const kNMEInterstitialAdUnitID = @"ca-app-pub-3940256099942544/4411468910";
#endif

#if defined(NME_REAL_ADS) && defined(NME_ADMOB_REWARD_ID)
static NSString *const kNMERewardedAdUnitID = @NME_ADMOB_STR(NME_ADMOB_REWARD_ID);
#else
static NSString *const kNMERewardedAdUnitID = @"ca-app-pub-3940256099942544/1712485313";
#endif

// ---------------------------------------------------------------------------
// Forward declarations
// ---------------------------------------------------------------------------
static void nmeAdMobSendEvent(const char *event);
static UIViewController *nmeRootViewController(void);

// ---------------------------------------------------------------------------
// Interstitial controller
// ---------------------------------------------------------------------------

@interface NMEAdMobInterstitial : NSObject <GADFullScreenContentDelegate>
@property (nonatomic, strong) GADInterstitialAd *ad;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation NMEAdMobInterstitial

- (void)load
{
   if (self.isLoading || self.ad != nil) return;
   self.isLoading = YES;
   NSLog(@"NME AdMob loading interstitial %@", kNMEInterstitialAdUnitID);
   [GADInterstitialAd loadWithAdUnitID:kNMEInterstitialAdUnitID
                               request:[GADRequest request]
                     completionHandler:^(GADInterstitialAd *ad, NSError *error) {
      self.isLoading = NO;
      if (error) {
         NSLog(@"NME AdMob interstitial failed to load: %@", error.localizedDescription);
         nmeAdMobSendEvent("onInterstitialPreloadFailed");
         return;
      }
      self.ad = ad;
      self.ad.fullScreenContentDelegate = self;
      NSLog(@"NME AdMob interstitial loaded");
      nmeAdMobSendEvent("onInterstitialPreloaded");
   }];
}

- (void)show
{
   if (self.ad == nil) {
      NSLog(@"NME AdMob interstitial not ready, reloading");
      [self load];
      return;
   }
   [self.ad presentFromRootViewController:nmeRootViewController()];
}

- (void)retryIfNeeded
{
   if (!self.isLoading && self.ad == nil)
      [self load];
}

// GADFullScreenContentDelegate
- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
   NSLog(@"NME AdMob interstitial presented");
   nmeAdMobSendEvent("onInterstitialDisplayed");
}

- (void)adWillDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
   NSLog(@"NME AdMob interstitial dismissed");
   self.ad = nil;
   nmeAdMobSendEvent("onInterstitialHidden");
   [self load];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad
    didFailToPresentFullScreenContentWithError:(NSError *)error
{
   NSLog(@"NME AdMob interstitial failed to present: %@", error.localizedDescription);
   self.ad = nil;
   nmeAdMobSendEvent("onInterstitialFailedToShow");
   [self load];
}

@end

// ---------------------------------------------------------------------------
// Rewarded ad controller
// ---------------------------------------------------------------------------

@interface NMEAdMobRewarded : NSObject <GADFullScreenContentDelegate>
@property (nonatomic, strong) GADRewardedAd *ad;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation NMEAdMobRewarded

- (void)load
{
   if (self.isLoading || self.ad != nil) return;
   self.isLoading = YES;
   NSLog(@"NME AdMob loading rewarded %@", kNMERewardedAdUnitID);
   [GADRewardedAd loadWithAdUnitID:kNMERewardedAdUnitID
                           request:[GADRequest request]
                 completionHandler:^(GADRewardedAd *ad, NSError *error) {
      self.isLoading = NO;
      if (error) {
         NSLog(@"NME AdMob rewarded failed to load: %@", error.localizedDescription);
         nmeAdMobSendEvent("onRewardPreloadFailed");
         return;
      }
      self.ad = ad;
      self.ad.fullScreenContentDelegate = self;
      NSLog(@"NME AdMob rewarded loaded");
      nmeAdMobSendEvent("onRewardPreloaded");
   }];
}

- (void)show
{
   if (self.ad == nil) {
      NSLog(@"NME AdMob rewarded not ready");
      nmeAdMobSendEvent("onRewardFailed");
      return;
   }
   [self.ad presentFromRootViewController:nmeRootViewController()
                  userDidEarnRewardHandler:^{
      NSLog(@"NME AdMob reward earned");
      nmeAdMobSendEvent("onRewardVerified");
   }];
}

- (void)retryIfNeeded
{
   if (!self.isLoading && self.ad == nil)
      [self load];
}

// GADFullScreenContentDelegate
- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
   NSLog(@"NME AdMob rewarded presented");
   nmeAdMobSendEvent("onRewardDisplayed");
}

- (void)adWillDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad
{
   NSLog(@"NME AdMob rewarded dismissed");
   self.ad = nil;
   nmeAdMobSendEvent("onRewardHidden");
   [self load];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad
    didFailToPresentFullScreenContentWithError:(NSError *)error
{
   NSLog(@"NME AdMob rewarded failed to present: %@", error.localizedDescription);
   self.ad = nil;
   nmeAdMobSendEvent("onRewardFailed");
   [self load];
}

@end

// ---------------------------------------------------------------------------
// Module-level state
// ---------------------------------------------------------------------------

static NMEAdMobInterstitial *sInterstitial  = nil;
static NMEAdMobRewarded     *sRewarded      = nil;
static BOOL sAdMobInitialized               = NO;
static BOOL sAdMobInitPending               = NO;
static BOOL sPendingInterstitial            = NO;
static BOOL sPendingRewarded                = NO;

// ---------------------------------------------------------------------------
// Helpers (defined after ObjC classes are complete)
// ---------------------------------------------------------------------------

static UIViewController *nmeRootViewController(void)
{
   for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
      UIWindowScene *ws = (UIWindowScene *)scene;
      if ([ws isKindOfClass:[UIWindowScene class]] && ws.windows.count > 0)
         return ws.windows.firstObject.rootViewController;
   }
   return nil;
}

static void nmeAdMobSendEvent(const char *event)
{
   c_nmeAdMobOnEvent(event);
}

static void nmeAdMobOnSdkReady(void)
{
   sAdMobInitPending = NO;
   NSLog(@"NME AdMob SDK initialized");
   nmeAdMobSendEvent("onSdkInitialized");
   if (sPendingInterstitial) { sPendingInterstitial = NO; [sInterstitial load]; }
   if (sPendingRewarded)     { sPendingRewarded     = NO; [sRewarded     load]; }
}

static void nmeAdMobStartSDK(void)
{
   sAdMobInitPending = YES;
   [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *status) {
      nmeAdMobOnSdkReady();
   }];
}

static void nmeAdMobEnsureInit(void)
{
   if (sAdMobInitialized) return;
   sAdMobInitialized = YES;
   sInterstitial = [[NMEAdMobInterstitial alloc] init];
   sRewarded     = [[NMEAdMobRewarded     alloc] init];

   if (@available(iOS 14, *)) {
      [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:
         ^(ATTrackingManagerAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
               NSLog(@"NME AdMob ATT status: %lu", (unsigned long)status);
               nmeAdMobStartSDK();
            });
         }];
   } else {
      nmeAdMobStartSDK();
   }
}

// ---------------------------------------------------------------------------
// C entry points called from Haxe via @:native
// ---------------------------------------------------------------------------

extern "C" void loadInterstitialAd(void)
{
   nmeAdMobEnsureInit();
   if (sAdMobInitPending)
      sPendingInterstitial = YES;
   else
      [sInterstitial load];
}

extern "C" void showInterstitialAd(void)
{
   if (sInterstitial) [sInterstitial show];
}

extern "C" void loadRewardedVideo(void)
{
   nmeAdMobEnsureInit();
   if (sAdMobInitPending)
      sPendingRewarded = YES;
   else
      [sRewarded load];
}

extern "C" void showRewardedVideo(void)
{
   if (sRewarded) [sRewarded show];
}

extern "C" void nmeAdMobRetryInterstitial(void)
{
   nmeAdMobEnsureInit();
   if (!sAdMobInitPending)
      [sInterstitial retryIfNeeded];
   else
      sPendingInterstitial = YES;
}

extern "C" void nmeAdMobRetryReward(void)
{
   nmeAdMobEnsureInit();
   if (!sAdMobInitPending)
      [sRewarded retryIfNeeded];
   else
      sPendingRewarded = YES;
}
