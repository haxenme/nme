package nme.external;

#if (cpp || neko)

typedef ExternalInterface = neash.external.ExternalInterface;

#elseif js

typedef ExternalInterface = jeash.external.ExternalInterface;

#else

typedef ExternalInterface = flash.external.ExternalInterface;

#end