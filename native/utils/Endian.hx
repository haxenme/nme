package native.utils;
#if (cpp || neko)

class Endian 
{
   public static inline var BIG_ENDIAN : String = "bigEndian";
   public static inline var LITTLE_ENDIAN : String = "littleEndian";
}

#end