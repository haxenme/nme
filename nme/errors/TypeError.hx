package nme.errors;
#if display


@:native("TypeError") extern class TypeError extends Error {
}


#elseif (cpp || neko)
typedef TypeError = native.errors.TypeError;
#elseif js
typedef TypeError = browser.errors.TypeError;
#else
typedef TypeError = flash.errors.TypeError;
#end
