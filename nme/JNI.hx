package nme;

class JNI
{
   static var base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
   static var alreadyCreated = new Hash<Bool>();


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

   public static function createInterface(haxeClass:Dynamic, className:String, classDef:String):Dynamic
   {
      var bytes:haxe.io.Bytes = null;
      if (!alreadyCreated.get(className))
      {
         bytes = haxe.io.Bytes.ofString(haxe.BaseCode.decode(classDef,base64));

         bytes = cpp.zip.Uncompress.run(bytes,9);

         alreadyCreated.set(className,true);
      }

      return nme_jni_create_interface(haxeClass, className, bytes==null?null:bytes.getData());
   }



   static var nme_jni_create_method = nme.Loader.load("nme_jni_create_method",4);
   static var nme_jni_call_member = nme.Loader.load("nme_jni_call_member",3);
   static var nme_jni_call_static = nme.Loader.load("nme_jni_call_static",2);
   static var nme_jni_create_interface = nme.Loader.load("nme_jni_create_interface",3);
}


