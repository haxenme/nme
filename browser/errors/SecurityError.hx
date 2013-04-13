package browser.errors;
#if js


class SecurityError extends Error {
	
	
	public function new(inMessage:String = "") {
		
		super(inMessage, 0);
		
	}
	

}


#end