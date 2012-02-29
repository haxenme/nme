package nme.errors;

#if (cpp || neko)

typedef TypeError = neash.errors.TypeError;

#elseif js

typedef TypeError = jeash.errors.TypeError;

#else

typedef TypeError = flash.errors.TypeError;

#end