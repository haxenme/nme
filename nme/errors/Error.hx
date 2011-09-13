package nme.errors;
#if (cpp || neko)


class Error
{
	var errorID : Int;
	var message : Dynamic;
	var name : Dynamic;

	function new(?inMessage : Dynamic, id : Dynamic = 0)
	{
	  message = inMessage;
	  errorID = id;
	}
	public function toString() : String { return message; }
	function getStackTrace() : String { return ""; }
}


#else
typedef Error = flash.errors.Error;
#end