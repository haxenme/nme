#if flash


package nme.display;


@:native ("flash.display.SpreadMethod")
@:fakeEnum(String) extern enum SpreadMethod {
	PAD;
	REFLECT;
	REPEAT;
}



#else


package nme.display;

enum SpreadMethod { PAD; REPEAT; REFLECT; }


#end