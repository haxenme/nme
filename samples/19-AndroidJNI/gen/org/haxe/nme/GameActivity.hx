package org.haxe.nme;
class GameActivity extends android.app.Activity
{

   static var __create_func:Dynamic;
   public static function _create() : org.haxe.nme.GameActivity
   {
      if (__create_func==null)
         __create_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","<init>","()V");
      return new org.haxe.nme.GameActivity(nme.JNI.callStatic(__create_func,[]));
   }

   public function new(handle:Dynamic) { super(handle); }
   static var _showKeyboard_func:Dynamic;
   public static function showKeyboard(arg0:Bool) : Dynamic
   {
      if (_showKeyboard_func==null)
         _showKeyboard_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","showKeyboard","(Z)V");
      nme.JNI.callStatic(_showKeyboard_func,[arg0]);
   }

   static var _getResource_func:Dynamic;
   public static function getResource(arg0:String) : Dynamic
   {
      if (_getResource_func==null)
         _getResource_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","getResource","(Ljava/lang/String;)[B");
      return nme.JNI.callStatic(_getResource_func,[arg0]);
   }

   static var _getSoundHandle_func:Dynamic;
   public static function getSoundHandle(arg0:String) : Dynamic
   {
      if (_getSoundHandle_func==null)
         _getSoundHandle_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","getSoundHandle","(Ljava/lang/String;)I");
      return nme.JNI.callStatic(_getSoundHandle_func,[arg0]);
   }

   static var _getMusicHandle_func:Dynamic;
   public static function getMusicHandle(arg0:String) : Dynamic
   {
      if (_getMusicHandle_func==null)
         _getMusicHandle_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","getMusicHandle","(Ljava/lang/String;)I");
      return nme.JNI.callStatic(_getMusicHandle_func,[arg0]);
   }

   static var _getContext_func:Dynamic;
   public static function getContext() : Dynamic
   {
      if (_getContext_func==null)
         _getContext_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","getContext","()Landroid/content/Context;");
      return nme.JNI.callStatic(_getContext_func,[]);
   }

   static var _playSound_func:Dynamic;
   public static function playSound(arg0:Int,arg1:Float,arg2:Float,arg3:Int) : Dynamic
   {
      if (_playSound_func==null)
         _playSound_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","playSound","(IDDI)I");
      return nme.JNI.callStatic(_playSound_func,[arg0,arg1,arg2,arg3]);
   }

   static var _playMusic_func:Dynamic;
   public static function playMusic(arg0:Int,arg1:Float,arg2:Float,arg3:Int) : Dynamic
   {
      if (_playMusic_func==null)
         _playMusic_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","playMusic","(IDDI)I");
      return nme.JNI.callStatic(_playMusic_func,[arg0,arg1,arg2,arg3]);
   }

   static var _postUICallback_func:Dynamic;
   public static function postUICallback(arg0:Float) : Dynamic
   {
      if (_postUICallback_func==null)
         _postUICallback_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","postUICallback","(J)V");
      nme.JNI.callStatic(_postUICallback_func,[arg0]);
   }

   static var _launchBrowser_func:Dynamic;
   public static function launchBrowser(arg0:String) : Dynamic
   {
      if (_launchBrowser_func==null)
         _launchBrowser_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","launchBrowser","(Ljava/lang/String;)V");
      nme.JNI.callStatic(_launchBrowser_func,[arg0]);
   }

   static var _getUserPreference_func:Dynamic;
   public static function getUserPreference(arg0:String) : Dynamic
   {
      if (_getUserPreference_func==null)
         _getUserPreference_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","getUserPreference","(Ljava/lang/String;)Ljava/lang/String;");
      return nme.JNI.callStatic(_getUserPreference_func,[arg0]);
   }

   static var _setUserPreference_func:Dynamic;
   public static function setUserPreference(arg0:String,arg1:String) : Dynamic
   {
      if (_setUserPreference_func==null)
         _setUserPreference_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","setUserPreference","(Ljava/lang/String;Ljava/lang/String;)V");
      nme.JNI.callStatic(_setUserPreference_func,[arg0,arg1]);
   }

   static var _clearUserPreference_func:Dynamic;
   public static function clearUserPreference(arg0:String) : Dynamic
   {
      if (_clearUserPreference_func==null)
         _clearUserPreference_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","clearUserPreference","(Ljava/lang/String;)V");
      nme.JNI.callStatic(_clearUserPreference_func,[arg0]);
   }

   static var _playMusic1_func:Dynamic;
   public static function playMusic1(arg0:String) : Dynamic
   {
      if (_playMusic1_func==null)
         _playMusic1_func=nme.JNI.createStaticMethod("org.haxe.nme.GameActivity","playMusic","(Ljava/lang/String;)V");
      nme.JNI.callStatic(_playMusic1_func,[arg0]);
   }

}
