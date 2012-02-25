package nme.utils;
#if (cpp || neko)


class Endian
{

	public static inline var BIG_ENDIAN : String = "bigEndian";
	public static inline var LITTLE_ENDIAN : String = "littleEndian";

}


#elseif js

enum Endian {
		BIG_ENDIAN;
		LITTLE_ENDIAN;
}

#else
typedef Endian = flash.utils.Endian;
#end