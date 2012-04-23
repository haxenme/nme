package nme.errors;
#if code_completion


@:native("TypeError") extern class TypeError extends Error {
}


#elseif (cpp || neko)
typedef TypeError = neash.errors.TypeError;
#elseif js
typedef TypeError = jeash.errors.TypeError;
#else
typedef TypeError = flash.errors.TypeError;
#end