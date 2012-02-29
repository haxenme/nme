package nme.net;

#if (cpp || neko)

typedef URLVariables = neash.net.URLVariables;

#elseif js

typedef URLVariables = jeash.net.URLVariables;

#else

typedef URLVariables = flash.net.URLVariables;

#end