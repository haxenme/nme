package nme.net;

#if (cpp || neko)

typedef URLRequest = neash.net.URLRequest;

#elseif js

typedef URLRequest = jeash.net.URLRequest;

#else

typedef URLRequest = flash.net.URLRequest;

#end