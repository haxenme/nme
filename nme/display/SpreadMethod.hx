package nme.display;
#if (cpp || neko || js)


enum SpreadMethod
{
	PAD;
	REPEAT;
	REFLECT;
}


#else
typedef SpreadMethod = flash.display.SpreadMethod;
#end