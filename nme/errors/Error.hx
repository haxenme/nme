package nme.errors;
#if (cpp || neko)


class Error
{
	
	private var errorID:Int;
	private var message:Dynamic;
	private var name:Dynamic;

	public function new(?inMessage:Dynamic, id:Dynamic = 0)
	{
		message = inMessage;
		errorID = id;
	}
	
	
	private function getStackTrace():String
	{
		return "";
	}
	
	
	public function toString():String
	{
		return message;
	}
	
}


#else
typedef Error = flash.errors.Error;
#end