package nme;

import cpp.zip.Uncompress;
import haxe.io.Bytes;
#if (haxe_211 || haxe3)
import haxe.crypto.BaseCode;
#else
import haxe.BaseCode;
#end
import nme.Loader;

@:nativeProperty
class JNI 
{
   static var isInit = false;

   public static function init() 
   {
      if (!isInit) 
      {
         isInit = true;
         var func = Loader.load("nme_jni_init_callback", 1);
         func(onCallback);
      }
   }

   static function onCallback(inObj:Dynamic, inFunc:Dynamic, inArgs:Dynamic):Dynamic 
   {
      //trace("onCallback " + inObj + "," + inFunc + "," + inArgs );
      var field = Reflect.field(inObj, inFunc);

      if (field != null)
         return Reflect.callMethod(inObj, field, inArgs);

      trace("onCallback - unknown field " + inFunc + " in " + inObj);
      trace("Make sure to use '@:keep' if enabling DLC");

      return null;
   }

   /**
    * Create bindings to an class instance method in Java
    * @param   className      The name of the target class in Java
    * @param   memberName      The name of the target method
    * @param   signature      The JNI string-based type signature for the method
    * @param   useArray      Whether the method should accept multiple parameters, or a single array with the parameters to pass to Java
    * @return      A method that calls Java. The first parameter is a handle for the Java object instance, the rest are passed into the method as arguments
    */
   public static function createMemberMethod(className:String, memberName:String, signature:String, useArray:Bool = false, quietFail:Bool = false):Dynamic 
   {
      #if android
      init();
      className = className.split(".").join("/");

      var handle = nme_jni_create_method(className, memberName, signature, false, quietFail);
      if (handle==null)
      {
         if (quietFail)
            return null;
         throw "Could not find member function " + memberName;
      }
      var method = new JNIMethod(handle);
      return method.getMemberMethod(useArray);
      #else
      return null;
      #end
   }

   /**
    * Create bindings to a static class method in Java
    * @param   className      The name of the target class in Java
    * @param   memberName      The name of the target method
    * @param   signature      The JNI string-based type signature for the method
    * @param   useArray      Whether the method should accept multiple parameters, or a single array with the parameters to pass to Java
    * @return      A method that calls Java. Each argument is passed into the Java method as arguments
    */
   public static function createStaticMethod(className:String, memberName:String, signature:String, useArray:Bool = false, quietFail:Bool=false):Dynamic 
   {
      #if android
      init();
      className = className.split(".").join("/");

      var handle = nme_jni_create_method(className, memberName, signature, true, quietFail);
      if (handle==null)
      {
         if (quietFail)
            return null;
         throw "Could not find static function " + memberName;
      }
      var method = new JNIMethod(handle);
      return method.getStaticMethod(useArray);
      #else
      return null;
      #end
   }


   public static function callMember(method:Dynamic, jobject:Dynamic, a:Array<Dynamic>):Dynamic 
   {
      switch(a.length)
      {
         case 0: return method(jobject);
         case 1: return method(jobject,a[0]);
         case 2: return method(jobject,a[0],a[1]);
         case 3: return method(jobject,a[0],a[1],a[2]);
         case 4: return method(jobject,a[0],a[1],a[2],a[3]);
         case 5: return method(jobject,a[0],a[1],a[2],a[3],a[4]);
         case 6: return method(jobject,a[0],a[1],a[2],a[3],a[4],a[5]);
         case 7: return method(jobject,a[0],a[1],a[2],a[3],a[4],a[5],a[6]);
         default : return null;
      }
   }

   public static function callStatic(method:Dynamic, a:Array<Dynamic>):Dynamic 
   {
      switch(a.length)
      {
         case 0: return method();
         case 1: return method(a[0]);
         case 2: return method(a[0],a[1]);
         case 3: return method(a[0],a[1],a[2]);
         case 4: return method(a[0],a[1],a[2],a[3]);
         case 5: return method(a[0],a[1],a[2],a[3],a[4]);
         case 6: return method(a[0],a[1],a[2],a[3],a[4],a[5]);
         case 7: return method(a[0],a[1],a[2],a[3],a[4],a[5],a[6]);
         default : return null;
      }
   }


   // Native Methods
   #if android
   private static var nme_jni_create_method = Loader.load("nme_jni_create_method", 5);
   private static var nme_jni_call_member = Loader.load("nme_jni_call_member", 3);
   private static var nme_jni_call_static = Loader.load("nme_jni_call_static", 2);
   #else
   private static var nme_jni_create_method:Dynamic;
   private static var nme_jni_call_member:Dynamic;
   private static var nme_jni_call_static:Dynamic;
   #end
}

class JNIMethod 
{
   private var method:Dynamic;

   public function new(method:Dynamic) 
   {
      this.method = method;
   }

   public function callMember(args:Array<Dynamic>):Dynamic 
   {
      var jobject = args.shift();
      return nme_jni_call_member(method, jobject, args);
   }

   public function callStatic(args:Array<Dynamic>):Dynamic 
   {
      return nme_jni_call_static(method, args);
   }

   public function getMemberMethod(useArray:Bool):Dynamic 
   {
      if (useArray) 
         return callMember;
      else 
         return Reflect.makeVarArgs(callMember);
   }

   public function getStaticMethod(useArray:Bool):Dynamic 
   {
      if (useArray) 
         return callStatic;
      else 
         return  Reflect.makeVarArgs(callStatic);
   }

   // Native Methods
   #if android
   private static var nme_jni_call_member = Loader.load("nme_jni_call_member", 3);
   private static var nme_jni_call_static = Loader.load("nme_jni_call_static", 2);
   #else
   private static var nme_jni_call_member:Dynamic;
   private static var nme_jni_call_static:Dynamic;
   #end
}

