package nme.watchos;

import cpp.Callable;

extern class HaxeLink
{
   public static inline var onAwake = 0;
   public static inline var willActivate = 1;
   public static inline var didActivate = 2;
   public static inline var applicationDidFinishLaunching = 3;
   public static inline var applicationDidBecomeActive = 4;
   public static inline var applicationWillResignActive = 5;
   public static inline var onButton = 6;

   public static inline var updateScene = 7;
   public static inline var didEvaluateActionsForScene = 8;
   public static inline var didSimulatePhysicsForScene = 9;
   public static inline var didApplyConstraintsForScene = 10;
   public static inline var didFinishUpdateForScene = 11;


   @:native("::HxSetHaxeCallback")
   public static function setCallback( func:Callable< Int->Int->Float->cpp.RawPointer<cpp.Void>->Int > ):Void;
}
