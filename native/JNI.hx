package native;
#if (android)


import cpp.zip.Uncompress;
import haxe.io.Bytes;
import haxe.BaseCode;
import native.Loader;


class JNI {
	
	
	static var isInit = false;
	
   
	static function init () {
		
		if (!isInit) {
			
			isInit = true;
			var func = Loader.load ("nme_jni_init_callback", 1);
			func (onCallback);
			
		}
		
	}
	
	
	static function onCallback (inObj:Dynamic, inFunc:Dynamic, inArgs:Dynamic):Dynamic {
		
		//trace("onCallback " + inObj + "," + inFunc + "," + inArgs );
		var field = Reflect.field (inObj, inFunc);
		
		if (field != null)
			return Reflect.callMethod (inObj, field, inArgs);
		
		trace("onCallback - unknown field " + inFunc);
		
		return null;
		
	}
	
	
	/**
	 * Create bindings to an class instance method in Java
	 * @param	className		The name of the target class in Java
	 * @param	memberName		The name of the target method
	 * @param	signature		The JNI string-based type signature for the method
	 * @param	useArray		Whether the method should accept multiple parameters, or a single array with the parameters to pass to Java
	 * @return		A method that calls Java. The first parameter is a handle for the Java object instance, the rest are passed into the method as arguments
	 */
	public static function createMemberMethod (className:String, memberName:String, signature:String, useArray:Bool = false):Dynamic {
		
		init ();
		
		var method = new JNIMethod (nme_jni_create_method (className, memberName, signature, false));
		return method.getMemberMethod (useArray);
		
	}
	
	
	/**
	 * Create bindings to a static class method in Java
	 * @param	className		The name of the target class in Java
	 * @param	memberName		The name of the target method
	 * @param	signature		The JNI string-based type signature for the method
	 * @param	useArray		Whether the method should accept multiple parameters, or a single array with the parameters to pass to Java
	 * @return		A method that calls Java. Each argument is passed into the Java method as arguments
	 */
	public static function createStaticMethod (className:String, memberName:String, signature:String, useArray:Bool = false):Dynamic {
		
		init ();
		
		var method = new JNIMethod (nme_jni_create_method (className, memberName, signature, true));
		return method.getStaticMethod (useArray);
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_jni_create_method = Loader.load ("nme_jni_create_method", 4);
	
	
}


class JNIMethod {
	
	
	private var method:Dynamic;
	
	
	public function new (method:Dynamic) {
		
		this.method = method;
		
	}
	
	
	public function callMember (args:Array<Dynamic>):Dynamic {
		
		var jobject = args.shift ();
		return nme_jni_call_member (method, jobject, args);
		
	}
	
	
	public function callStatic (args:Array<Dynamic>):Dynamic {
		
		return nme_jni_call_static (method, args);
		
	}
	
	
	public function getMemberMethod (useArray:Bool):Dynamic {
		
		if (useArray) {
			
			return callMember;
			
		} else {
			
			return Reflect.makeVarArgs (callMember);
			
		}
		
	}
	
	
	public function getStaticMethod (useArray:Bool):Dynamic {
		
		if (useArray) {
			
			return callStatic;
			
		} else {
			
			return  Reflect.makeVarArgs (callStatic);
			
		}
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_jni_call_member = Loader.load ("nme_jni_call_member", 3);
	private static var nme_jni_call_static = Loader.load ("nme_jni_call_static", 2);
	
	
}


#end