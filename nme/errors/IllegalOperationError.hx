package nme.errors;
#if code_completion


extern class IllegalOperationError extends Error {
	function new(?message : String, id : Int = 0) : Void;
}


#elseif (cpp || neko)
typedef IllegalOperationError = neash.errors.IllegalOperationError;
#elseif js
typedef IllegalOperationError = jeash.errors.IllegalOperationError;
#else
typedef IllegalOperationError = flash.errors.IllegalOperationError;
#end