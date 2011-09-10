package nme.text;


#if flash
@:native ("flash.text.AntiAliasType")
@:fakeEnum(String) extern enum AntiAliasType {
	ADVANCED;
	NORMAL;
}
#end