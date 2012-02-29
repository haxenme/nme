package nme.system;

#if (cpp || neko)

typedef System = neash.system.System;

#elseif js

typedef System = jeash.system.System;

#else

typedef System = flash.system.System;

#end