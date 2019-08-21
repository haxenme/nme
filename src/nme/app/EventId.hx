package nme.app;

@:nativeProperty
class EventId
{
   public static inline var Unknown =  0;
   public static inline var KeyDown =  1;
   public static inline var Char =  2;
   public static inline var KeyUp =  3;
   public static inline var MouseMove =  4;
   public static inline var MouseDown =  5;
   public static inline var MouseClick =  6;
   public static inline var MouseUp =  7;
   public static inline var Resize =  8;
   public static inline var Poll =  9;
   public static inline var Quit =  10;
   public static inline var Focus =  11;
   public static inline var ShouldRotate =  12;

   // Internal for now...
   public static inline var DestroyHandler =  13;
   public static inline var Redraw =  14;

   public static inline var TouchBegin =  15;
   public static inline var TouchMove =  16;
   public static inline var TouchEnd =  17;
   public static inline var TouchTap =  18;

   public static inline var Change =  19;
   public static inline var Activate =  20;
   public static inline var Deactivate =  21;
   public static inline var GotInputFocus =  22;
   public static inline var LostInputFocus =  23;
   
   public static inline var JoyAxisMove =  24;
   public static inline var JoyBallMove =  25;
   public static inline var JoyHatMove =  26;
   public static inline var JoyButtonDown =  27;
   public static inline var JoyButtonUp =  28;
   public static inline var JoyDeviceAdded = 29;
   public static inline var JoyDeviceRemoved = 30;
   
   public static inline var SysWM =  31;
   
   public static inline var RenderContextLost =  32;
   public static inline var RenderContextRestored =  33;

   public static inline var Scroll = 34;
   public static inline var AppLink = 35;

   public static inline var DpiChanged = 36;
}
