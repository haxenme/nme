package nme.display;
#if code_completion


@:fakeEnum(String) extern enum TriangleCulling {
	NEGATIVE;
	NONE;
	POSITIVE;
}


#elseif (cpp || neko)
typedef TriangleCulling = neash.display.TriangleCulling;
#elseif js
typedef TriangleCulling = jeash.display.TriangleCulling;
#else
typedef TriangleCulling = flash.display.TriangleCulling;
#end