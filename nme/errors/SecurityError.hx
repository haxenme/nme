package nme.errors;

#if (cpp || neko)

typedef SecurityError = neash.errors.SecurityError;

#elseif js

typedef SecurityError = jeash.errors.SecurityError;

#else

typedef SecurityError = flash.errors.SecurityError;

#end