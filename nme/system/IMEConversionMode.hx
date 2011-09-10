package nme.system;


#if flash
@:native ("flash.system.IMEConversionMode")
@:fakeEnum(String) extern enum IMEConversionMode {
	ALPHANUMERIC_FULL;
	ALPHANUMERIC_HALF;
	CHINESE;
	JAPANESE_HIRAGANA;
	JAPANESE_KATAKANA_FULL;
	JAPANESE_KATAKANA_HALF;
	KOREAN;
	UNKNOWN;
}
#end