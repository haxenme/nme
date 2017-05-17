package ios.watchconnectivity;

@:enum
abstract WCSessionActivationState(Int) {
  var WCSessionActivationStateNotActivated = 0;
  var WCSessionActivationStateInactive = 1;
  var WCSessionActivationStateActivated = 2;
}


