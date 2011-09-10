package nme.display;


#if flash
@:native ("flash.display.SpreadMethod")
@:fakeEnum(String) extern enum SpreadMethod {
	PAD;
	REFLECT;
	REPEAT;
}
#else



enum SpreadMethod { PAD; REPEAT; REFLECT; }
#end