// why is this here?


package nme;
#if js

class Error 
{
	public var errorID(default,null) : Int;
	public var message : Dynamic;
	public var name : Dynamic;
	public function new(?message : String, ?id : Int) 
	{
		this.message = message;
		this.errorID = id;
	}
	public function getStackTrace() : String
	{
		return haxe.Stack.toString( haxe.Stack.callStack() );
	}
	public function toString()
	{
		if ( this.message != null )
			return this.message;
		else
			return "Error";
	}
}

#end