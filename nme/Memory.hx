package nme;

#if (cpp || neko)

typedef Memory = neash.Memory;

#elseif js

//typedef Memory = jeash.Memory;

#else

typedef Memory = flash.Memory;

#end