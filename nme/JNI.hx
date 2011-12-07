package nme;
#if (android)


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
	 * @param	useArray		Whether the method should accept multiple parameters, or a single array with the parameters to pass to Java
	 * @return		A method that calls Java. The first parameter is a handle for the Java object instance, the rest are passed into the method as arguments
	 */
	public static function createMemberMethod(className:String, memberName:String, signature:String, useArray:Bool = false):Dynamic
	{
		var method = new JNIMethod (nme_jni_create_method(className, memberName, signature, false));
		return method.getMemberMethod(useArray);
	}
	
	
	/**
	 * Create bindings to a static class method in Java
	 * @param	className		The name of the target class in Java
	 * @param	memberName		The name of the target method
	 * @param	signature		The JNI string-based type signature for the method
	 * @param	useArray		Whether the method should accept multiple parameters, or a single array with the parameters to pass to Java
	 * @return		A method that calls Java. Each argument is passed into the Java method as arguments
	 */
	public static function createStaticMethod(className:String, memberName:String, signature:String, useArray:Bool = false):Dynamic
	{
		var method = new JNIMethod (nme_jni_create_method(className, memberName, signature, true));
		return method.getStaticMethod(useArray);
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_jni_create_method = Loader.load("nme_jni_create_method", 4);
	private static var nme_jni_create_interface = Loader.load("nme_jni_create_interface", 3);
	
}


class JNIMethod
{
	public var callMemberArgs:Dynamic;
	public var callStaticArgs:Dynamic;
	
	private var method:Dynamic;
	
	
	public function new(method:Dynamic)
	{
		this.method = method;
	}
	
	
	public function callMember(args:Array<Dynamic>):Dynamic
	{
		var jobject = args.shift ();
		return nme_jni_call_member(method, jobject, args);
	}
	
	
	public function callStatic(args:Array<Dynamic>):Dynamic
	{
		return nme_jni_call_static(method, args);
	}
	
	
	public function getMemberMethod(useArray:Bool):Dynamic
	{
		if (useArray)
			{
				return callMember;
			}
			else
			{
				callMemberArgs = Reflect.makeVarArgs (callMember);
				return callMemberArgs;
			}
	}
	
	
	public function getStaticMethod(useArray:Bool):Dynamic
	{
		if (useArray)
		{
			return callStatic;
		}
		else
		{
			callStaticArgs = Reflect.makeVarArgs (callStatic);
			return callStaticArgs;
		}
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_jni_call_member = Loader.load("nme_jni_call_member", 3);
	private static var nme_jni_call_static = Loader.load("nme_jni_call_static", 2);
	
}


#end