package nme.errors;

#if (cpp || neko)

typedef ArgumentError = neash.errors.ArgumentError;

#elseif js

typedef ArgumentError = jeash.errors.ArgumentError;

#else

typedef ArgumentError = flash.errors.ArgumentError;

#end