package nme;

class JNI
{
   public static function createStaticMethod( className:String, memberName:String, signature:String )
        : Dynamic
   {
      return nme_jni_create_method(className,memberName,signature,true);
   }
   public static function createMemberMethod( className:String, memberName:String, signature:String )
        : Dynamic
   {
      return nme_jni_create_method(className,memberName,signature,false);
   }


   public static function callMember( method:Dynamic, jobject:Dynamic, args:Array<Dynamic>) : Dynamic
   {
      return nme_jni_call_member(method, jobject, args);
   }

   public static function callStatic( method:Dynamic, args:Array<Dynamic>) : Dynamic
   {
      return nme_jni_call_static(method, args);
   }

   static var nme_jni_create_method = nme.Loader.load("nme_jni_create_method",4);
   static var nme_jni_call_member = nme.Loader.load("nme_jni_call_member",3);
   static var nme_jni_call_static = nme.Loader.load("nme_jni_call_static",2);
}
