package android.widget;
class Toast
{
   var __jobject:Dynamic;

   static inline public var LENGTH_SHORT:Int = 0;
   static inline public var LENGTH_LONG:Int = 1;

   static var __create_func:Dynamic;
   public static function _create(arg0:Dynamic /*android.content.Context*/) : android.widget.Toast
   {
      if (__create_func==null)
         __create_func=nme.JNI.createStaticMethod("android.widget.Toast","<init>","(Landroid/content/Context;)V");
      return new android.widget.Toast(nme.JNI.callStatic(__create_func,[arg0]));
   }

   public function new(handle:Dynamic) { __jobject = handle; }
   static var _show_func:Dynamic;
   public function show() : Dynamic
   {
      if (_show_func==null)
         _show_func=nme.JNI.createMemberMethod("android.widget.Toast","show","()V");
      nme.JNI.callMember(_show_func,__jobject,[]);
   }

   static var _cancel_func:Dynamic;
   public function cancel() : Dynamic
   {
      if (_cancel_func==null)
         _cancel_func=nme.JNI.createMemberMethod("android.widget.Toast","cancel","()V");
      nme.JNI.callMember(_cancel_func,__jobject,[]);
   }

   static var _setView_func:Dynamic;
   public function setView(arg0:Dynamic /*android.view.View*/) : Dynamic
   {
      if (_setView_func==null)
         _setView_func=nme.JNI.createMemberMethod("android.widget.Toast","setView","(Landroid/view/View;)V");
      nme.JNI.callMember(_setView_func,__jobject,[arg0]);
   }

   static var _getView_func:Dynamic;
   public function getView() : Dynamic
   {
      if (_getView_func==null)
         _getView_func=nme.JNI.createMemberMethod("android.widget.Toast","getView","()Landroid/view/View;");
      return nme.JNI.callMember(_getView_func,__jobject,[]);
   }

   static var _setDuration_func:Dynamic;
   public function setDuration(arg0:Int) : Dynamic
   {
      if (_setDuration_func==null)
         _setDuration_func=nme.JNI.createMemberMethod("android.widget.Toast","setDuration","(I)V");
      nme.JNI.callMember(_setDuration_func,__jobject,[arg0]);
   }

   static var _getDuration_func:Dynamic;
   public function getDuration() : Dynamic
   {
      if (_getDuration_func==null)
         _getDuration_func=nme.JNI.createMemberMethod("android.widget.Toast","getDuration","()I");
      return nme.JNI.callMember(_getDuration_func,__jobject,[]);
   }

   static var _setMargin_func:Dynamic;
   public function setMargin(arg0:Float,arg1:Float) : Dynamic
   {
      if (_setMargin_func==null)
         _setMargin_func=nme.JNI.createMemberMethod("android.widget.Toast","setMargin","(FF)V");
      nme.JNI.callMember(_setMargin_func,__jobject,[arg0,arg1]);
   }

   static var _getHorizontalMargin_func:Dynamic;
   public function getHorizontalMargin() : Dynamic
   {
      if (_getHorizontalMargin_func==null)
         _getHorizontalMargin_func=nme.JNI.createMemberMethod("android.widget.Toast","getHorizontalMargin","()F");
      return nme.JNI.callMember(_getHorizontalMargin_func,__jobject,[]);
   }

   static var _getVerticalMargin_func:Dynamic;
   public function getVerticalMargin() : Dynamic
   {
      if (_getVerticalMargin_func==null)
         _getVerticalMargin_func=nme.JNI.createMemberMethod("android.widget.Toast","getVerticalMargin","()F");
      return nme.JNI.callMember(_getVerticalMargin_func,__jobject,[]);
   }

   static var _setGravity_func:Dynamic;
   public function setGravity(arg0:Int,arg1:Int,arg2:Int) : Dynamic
   {
      if (_setGravity_func==null)
         _setGravity_func=nme.JNI.createMemberMethod("android.widget.Toast","setGravity","(III)V");
      nme.JNI.callMember(_setGravity_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _getGravity_func:Dynamic;
   public function getGravity() : Dynamic
   {
      if (_getGravity_func==null)
         _getGravity_func=nme.JNI.createMemberMethod("android.widget.Toast","getGravity","()I");
      return nme.JNI.callMember(_getGravity_func,__jobject,[]);
   }

   static var _getXOffset_func:Dynamic;
   public function getXOffset() : Dynamic
   {
      if (_getXOffset_func==null)
         _getXOffset_func=nme.JNI.createMemberMethod("android.widget.Toast","getXOffset","()I");
      return nme.JNI.callMember(_getXOffset_func,__jobject,[]);
   }

   static var _getYOffset_func:Dynamic;
   public function getYOffset() : Dynamic
   {
      if (_getYOffset_func==null)
         _getYOffset_func=nme.JNI.createMemberMethod("android.widget.Toast","getYOffset","()I");
      return nme.JNI.callMember(_getYOffset_func,__jobject,[]);
   }

   static var _makeText_func:Dynamic;
   public static function makeText(arg0:Dynamic /*android.content.Context*/,arg1:String,arg2:Int) : android.widget.Toast
   {
      if (_makeText_func==null)
         _makeText_func=nme.JNI.createStaticMethod("android.widget.Toast","makeText","(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;");
      return new android.widget.Toast(nme.JNI.callStatic(_makeText_func,[arg0,arg1,arg2]));
   }

   static var _makeText1_func:Dynamic;
   public static function makeText1(arg0:Dynamic /*android.content.Context*/,arg1:Int,arg2:Int) : android.widget.Toast
   {
      if (_makeText1_func==null)
         _makeText1_func=nme.JNI.createStaticMethod("android.widget.Toast","makeText","(Landroid/content/Context;II)Landroid/widget/Toast;");
      return new android.widget.Toast(nme.JNI.callStatic(_makeText1_func,[arg0,arg1,arg2]));
   }

   static var _setText_func:Dynamic;
   public function setText(arg0:Int) : Dynamic
   {
      if (_setText_func==null)
         _setText_func=nme.JNI.createMemberMethod("android.widget.Toast","setText","(I)V");
      nme.JNI.callMember(_setText_func,__jobject,[arg0]);
   }

   static var _setText1_func:Dynamic;
   public function setText1(arg0:String) : Dynamic
   {
      if (_setText1_func==null)
         _setText1_func=nme.JNI.createMemberMethod("android.widget.Toast","setText","(Ljava/lang/CharSequence;)V");
      nme.JNI.callMember(_setText1_func,__jobject,[arg0]);
   }

}
