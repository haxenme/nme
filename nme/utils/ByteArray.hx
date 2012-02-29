package nme.utils;

#if (cpp || neko)

typedef ByteArray = neash.utils.ByteArray;

#elseif js

typedef ByteArray = jeash.utils.ByteArray;

#else

typedef ByteArray = flash.utils.ByteArray;

#end