package nme.errors;
#if display


@:native("RangeError") extern class RangeError extends nme.errors.Error {
}


#elseif (cpp || neko)
typedef RangeError = neash.errors.RangeError;
#elseif js
typedef RangeError = jeash.errors.RangeError;
#else
typedef RangeError = flash.errors.RangeError;
#end
