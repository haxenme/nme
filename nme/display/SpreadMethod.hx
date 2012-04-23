package nme.display;
#if code_completion


@:fakeEnum(String) extern enum SpreadMethod {
	PAD;
	REFLECT;
	REPEAT;
}


#elseif (cpp || neko)
typedef SpreadMethod = neash.display.SpreadMethod;
#elseif js
typedef SpreadMethod = jeash.display.SpreadMethod;
#else
typedef SpreadMethod = flash.display.SpreadMethod;
#end