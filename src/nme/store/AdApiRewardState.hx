package nme.store;

enum AdApiRewardState {
   ApiUndefined;       /** No ad network configured in this build — ads will never appear **/
   ApiNotReady;         /** Ad network present but unreachable — suggest checking connection **/
   ApiNoConsent;       /** Consent required but not granted — offer privacy/consent settings **/
   ApiRewardNotLoaded; /** SDK ready, reward ad not yet loaded **/
   ApiRewardReady;     /** Reward ad ready to play **/
}
