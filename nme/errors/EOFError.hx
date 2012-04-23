package nme.errors;
#if code_completion


extern class EOFError/* extends IOError*/ {
	function new(?message : String, id : Int = 0) : Void;
}


#elseif (cpp || neko)
typedef EOFError = neash.errors.EOFError;
#elseif js
typedef EOFError = jeash.errors.EOFError;
#else
typedef EOFError = flash.errors.EOFError;
#end