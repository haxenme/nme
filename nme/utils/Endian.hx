#if flash


package nme.utils;


@:native ("flash.utils.Endian")
@:fakeEnum(String) extern enum Endian {
	BIG_ENDIAN;
	LITTLE_ENDIAN;
}



#else


package nme.utils;

class Endian
{
	public static inline var BIG_ENDIAN : String = "bigEndian";
	public static inline var LITTLE_ENDIAN : String = "littleEndian";
}


#end