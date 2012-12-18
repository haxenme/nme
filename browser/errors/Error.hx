package browser.errors;


#if haxe_211
import haxe.CallStack;
#else
import haxe.Stack;
#end


class Error {
	
	
	private static inline var DEFAULT_TO_STRING = "Error";
	
	public var errorID:Int;
	public var message:String;
	public var name:String;
	
	
	public function new (message:String = "", id:Int = 0) {
		
		this.message = message;
		this.errorID = id;
		
	}
	
	
	public function getStackTrace ():String {
		
		#if haxe_211
		return CallStack.toString (CallStack.exceptionStack ());
		#else
		return Stack.toString (Stack.exceptionStack ());
		#end
		
	}
	
	
	public function toString ():String {
		
		if (message != null) {
			
			return message;
			
		} else {
			
			return DEFAULT_TO_STRING;
			
		}
		
	}
	
	
}