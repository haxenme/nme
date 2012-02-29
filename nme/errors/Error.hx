package nme.errors;

#if (cpp || neko)

typedef Error = neash.errors.Error;

#elseif js

typedef Error = jeash.errors.Error;

#else

typedef Error = flash.errors.Error;

#end