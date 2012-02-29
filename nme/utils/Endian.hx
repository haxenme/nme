package nme.utils;

#if (cpp || neko)

typedef Endian = neash.utils.Endian;

#elseif js

typedef Endian = jeash.utils.Endian;

#else

typedef Endian = flash.utils.Endian;

#end