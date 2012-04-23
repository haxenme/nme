package nme.errors;
#if code_completion


@:native("ArgumentError") extern class ArgumentError extends Error {
}


#elseif (cpp || neko)
typedef ArgumentError = neash.errors.ArgumentError;
#elseif js
typedef ArgumentError = jeash.errors.ArgumentError;
#else
typedef ArgumentError = flash.errors.ArgumentError;
#end