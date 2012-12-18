package nme.errors;
#if display


@:native("RangeError") extern class RangeError extends nme.errors.Error {
}


#elseif (cpp || neko)
typedef RangeError = native.errors.RangeError;
#elseif js
typedef RangeError = browser.errors.RangeError;
#else
typedef RangeError = flash.errors.RangeError;
#end
