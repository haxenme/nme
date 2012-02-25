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


#elseif js

import haxe.Stack;

class Error
{
	public var errorID:Int;
	public var message:String;
	public var name:String;

	static inline var DEFAULT_TO_STRING = "Error";

	public function new (message:String = "", id:Int = 0) {
		this.message = message;
		this.errorID = id;
	}

	public function getStackTrace() {
		return Stack.toString(Stack.exceptionStack());
	}

	public function toString() {
		if (message != null)
			return message;
		else
			return DEFAULT_TO_STRING;
	}
}

#else
typedef Error = flash.errors.Error;
#end