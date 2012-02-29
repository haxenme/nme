package nme.errors;

#if (cpp || neko)

typedef EOFError = neash.errors.EOFError;

#elseif js

typedef EOFError = jeash.errors.EOFError;

#else

typedef EOFError = flash.errors.EOFError;

#end