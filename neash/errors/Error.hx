package neash.errors;


class Error
{
	
	/** @private */ public var errorID:Int;
	/** @private */ public var message:Dynamic;
	/** @private */ public var name:Dynamic;

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