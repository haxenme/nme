package nme.display;


#if flash
@:native ("flash.display.ShaderPrecision")
@:fakeEnum(String) extern enum ShaderPrecision {
	FAST;
	FULL;
}
#end