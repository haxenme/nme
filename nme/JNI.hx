package nme;
#if display


extern class JNI
{
	/**
	 * Create bindings to an class instance method in Java
	 * @param	className		The name of the target class in Java
	 * @param	memberName		The name of the target method
	 * @param	signature		The JNI string-based type signature for the method
	 * @param	useArray		Whether the method should accept multiple parameters, or a single array with the parameters to pass to Java
	 * @return		A method that calls Java. The first parameter is a handle for the Java object instance, the rest are passed into the method as arguments
	 */
	public static function createMemberMethod(className:String, memberName:String, signature:String, useArray:Bool = false):Dynamic;
	
	/**
	 * Create bindings to a static class method in Java
	 * @param	className		The name of the target class in Java
	 * @param	memberName		The name of the target method
	 * @param	signature		The JNI string-based type signature for the method
	 * @param	useArray		Whether the method should accept multiple parameters, or a single array with the parameters to pass to Java
	 * @return		A method that calls Java. Each argument is passed into the Java method as arguments
	 */
	public static function createStaticMethod(className:String, memberName:String, signature:String, useArray:Bool = false):Dynamic;
}


#elseif android
typedef JNI = native.JNI;
#end
