package nme.utils;


#if flash
@:native ("flash.utils.Endian")
@:fakeEnum(String) extern enum Endian {
	BIG_ENDIAN;
	LITTLE_ENDIAN;
}
#else



class Endian
{
	public static inline var BIG_ENDIAN : String = "bigEndian";
	public static inline var LITTLE_ENDIAN : String = "littleEndian";
}
#end