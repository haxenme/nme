package nme.utils;
#if code_completion


@:fakeEnum(String) extern enum Endian {
	BIG_ENDIAN;
	LITTLE_ENDIAN;
}


#elseif (cpp || neko)
typedef Endian = neash.utils.Endian;
#elseif js
typedef Endian = jeash.utils.Endian;
#else
typedef Endian = flash.utils.Endian;
#end