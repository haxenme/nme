package nme;
#if (cpp)


import cpp.zip.Uncompress;
import haxe.io.Bytes;
import haxe.BaseCode;
import nme.Loader;


class JNI
{

	static var alreadyCreated = new Hash<Bool>();
	static var base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	
	
	public static function callMember(method:Dynamic, jobject:Dynamic, args:Array<Dynamic>):Dynamic
	{
		return nme_jni_call_member(method, jobject, args);
	}
	
	
	public static function callStatic(method:Dynamic, args:Array<Dynamic>):Dynamic
	{
		return nme_jni_call_static(method, args);
	}
	
	
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
	
	
	public static function createMemberMethod(className:String, memberName:String, signature:String):Dynamic
	{
		return nme_jni_create_method(className, memberName, signature, false);
	}
	
	
	public static function createStaticMethod(className:String, memberName:String, signature:String):Dynamic
	{
		return nme_jni_create_method(className, memberName, signature, true);
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_jni_create_method = Loader.load("nme_jni_create_method", 4);
	private static var nme_jni_call_member = Loader.load("nme_jni_call_member", 3);
	private static var nme_jni_call_static = Loader.load("nme_jni_call_static", 2);
	private static var nme_jni_create_interface = Loader.load("nme_jni_create_interface", 3);
	
}


#end