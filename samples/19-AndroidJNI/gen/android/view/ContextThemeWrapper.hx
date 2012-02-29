package android.view;
class ContextThemeWrapper extends android.content.ContextWrapper
{

   static var __create_func:Dynamic;
   public static function _create() : android.view.ContextThemeWrapper
   {
      if (__create_func==null)
         __create_func=nme.JNI.createStaticMethod("android.view.ContextThemeWrapper","<init>","()V");
      return new android.view.ContextThemeWrapper(nme.JNI.callStatic(__create_func,[]));
   }

   public function new(handle:Dynamic) { super(handle); }
   static var __create1_func:Dynamic;
   public static function _create1(arg0:Dynamic /*android.content.Context*/,arg1:Int) : android.view.ContextThemeWrapper
   {
      if (__create1_func==null)
         __create1_func=nme.JNI.createStaticMethod("android.view.ContextThemeWrapper","<init>","(Landroid/content/Context;I)V");
      return new android.view.ContextThemeWrapper(nme.JNI.callStatic(__create1_func,[arg0,arg1]));
   }

   static var _setTheme_func:Dynamic;
   public override function setTheme(arg0:Int) : Dynamic
   {
      if (_setTheme_func==null)
         _setTheme_func=nme.JNI.createMemberMethod("android.view.ContextThemeWrapper","setTheme","(I)V");
      nme.JNI.callMember(_setTheme_func,__jobject,[arg0]);
   }

   static var _getTheme_func:Dynamic;
   public override function getTheme() : Dynamic
   {
      if (_getTheme_func==null)
         _getTheme_func=nme.JNI.createMemberMethod("android.view.ContextThemeWrapper","getTheme","()Landroid/content/res/Resources$Theme;");
      return nme.JNI.callMember(_getTheme_func,__jobject,[]);
   }

   static var _getSystemService_func:Dynamic;
   public override function getSystemService(arg0:String) : Dynamic
   {
      if (_getSystemService_func==null)
         _getSystemService_func=nme.JNI.createMemberMethod("android.view.ContextThemeWrapper","getSystemService","(Ljava/lang/String;)Ljava/lang/Object;");
      return nme.JNI.callMember(_getSystemService_func,__jobject,[arg0]);
   }

}
