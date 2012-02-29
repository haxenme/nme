package nme.net;

#if (cpp || neko)

typedef URLRequestMethod = neash.net.URLRequestMethod;

#elseif js

typedef URLRequestMethod = jeash.net.URLRequestMethod;

#else

typedef URLRequestMethod = flash.net.URLRequestMethod;

#end