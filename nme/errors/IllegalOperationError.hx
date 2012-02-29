package nme.errors;

#if (cpp || neko)

typedef IllegalOperationError = neash.errors.IllegalOperationError;

#elseif js

typedef IllegalOperationError = jeash.errors.IllegalOperationError;

#else

typedef IllegalOperationError = flash.errors.IllegalOperationError;

#end