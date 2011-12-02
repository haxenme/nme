package nme;
#if (cpp)


import cpp.zip.Uncompress;
import haxe.io.Bytes;
import haxe.BaseCode;
import nme.Loader;


class JNI
{

	private static var alreadyCreated = new Hash<Bool>();
	private static var base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	
	
	public static function createInterface(haxeClass:Dynamic, className:String, classDef:String):Dynamic
	{
		var bytes:Bytes = null;
		if (!alreadyCreated.get(className))
		{
			bytes = Bytes.ofString(BaseCode.decode(classDef, base64));
			bytes = Uncompress.run(bytes, 9);
			alreadyCreated.set(className, true);
		}
		return nme_jni_create_interface(haxeClass, className, bytes == null ? null : bytes.getData());
	}
	
	
	/**
	 * Create bindings to an class instance method in Java
	 * @param	className		The name of the target class in Java
	 * @param	memberName		The name of the target method
	 * @param	signature		The JNI string-based type signature for the method
	 * @return		A method that calls Java. The first parameter is a handle for the Java object instance, the rest are passed into the method as arguments
	 */
	public static function createMemberMethod(className:String, memberName:String, signature:String):Dynamic
	{
		var method = new JNIMethod (nme_jni_create_method(className, memberName, signature, false));
		return method.callMember;
	}
	
	
	/**
	 * Create bindings to a static class method in Java
	 * @param	className		The name of the target class in Java
	 * @param	memberName		The name of the target method
	 * @param	signature		The JNI string-based type signature for the method
	 * @return		A method that calls Java. Each argument is passed into the Java method as arguments
	 */
	public static function createStaticMethod(className:String, memberName:String, signature:String):Dynamic
	{
		var method = new JNIMethod (nme_jni_create_method(className, memberName, signature, true));
		return method.callStatic;
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_jni_create_method = Loader.load("nme_jni_create_method", 4);
	private static var nme_jni_create_interface = Loader.load("nme_jni_create_interface", 3);
	
}


class JNIMethod
{
	public var callMember:Dynamic;
	public var callStatic:Dynamic;
	
	private var method:Dynamic;
	
	
	public function new(method:Dynamic)
	{
		this.method = method;
		callMember = Reflect.makeVarArgs (_callMember);
		callStatic = Reflect.makeVarArgs (_callStatic);
	}
	
	
	private function _callMember(args:Array<Dynamic>)
	{
		var jobject = args.shift ();
		return nme_jni_call_member(method, jobject, args);
	}
	
	
	private function _callStatic(args:Array<Dynamic>)
	{
		return nme_jni_call_static(method, args);
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_jni_call_member = Loader.load("nme_jni_call_member", 3);
	private static var nme_jni_call_static = Loader.load("nme_jni_call_static", 2);
	
}


#end