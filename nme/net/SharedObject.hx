package nme.net;

#if (cpp || neko)

typedef SharedObject = neash.net.SharedObject;

#elseif js

typedef SharedObject = jeash.net.SharedObject;

#else

typedef SharedObject = flash.net.SharedObject;

#end