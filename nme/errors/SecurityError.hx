package nme.errors;


#if flash
@:native("SecurityError") extern class SecurityError extends Error {
}
#else



class SecurityError extends Error
{
   public function new(inMessage:String = "")
   {
	   super(inMessage,0);
   }
}
#end