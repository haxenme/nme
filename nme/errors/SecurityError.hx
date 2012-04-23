package nme.errors;
#if code_completion


@:native("SecurityError") extern class SecurityError extends Error {
}


#elseif (cpp || neko)
typedef SecurityError = neash.errors.SecurityError;
#elseif js
typedef SecurityError = jeash.errors.SecurityError;
#else
typedef SecurityError = flash.errors.SecurityError;
#end