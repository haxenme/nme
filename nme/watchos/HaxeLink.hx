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


   @:native("::HxSetHaxeCallback")
   public static function setCallback( func:Callable< Int->Int->Int > ):Void;
}
