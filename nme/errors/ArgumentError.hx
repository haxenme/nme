package nme.errors;
#if display


@:native("ArgumentError") extern class ArgumentError extends Error {
}


#elseif (cpp || neko)
typedef ArgumentError = native.errors.ArgumentError;
#elseif js
typedef ArgumentError = browser.errors.ArgumentError;
#else
typedef ArgumentError = flash.errors.ArgumentError;
#end
