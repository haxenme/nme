package nme.net;

#if (cpp || neko)

typedef SharedObjectFlushStatus = neash.net.SharedObjectFlushStatus;

#elseif js

typedef SharedObjectFlushStatus = jeash.net.SharedObjectFlushStatus;

#else

typedef SharedObjectFlushStatus = flash.net.SharedObjectFlushStatus;

#end