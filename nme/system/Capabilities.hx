package nme.system;

#if (cpp || neko)

typedef Capabilities = neash.system.Capabilities;

#elseif js

typedef Capabilities = jeash.system.Capabilities;

#else

typedef Capabilities = flash.system.Capabilities;

#end